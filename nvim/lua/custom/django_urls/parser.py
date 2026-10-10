"""Static Django URL parser for `custom.django_urls`.

Reads a repo's urls.py files with `ast` (standard library only, no Django, no
venv) and prints every URL pattern as JSON:

    python3 -I parser.py --root <repo> [--service <dir> ...]

Without --service every directory holding a manage.py is parsed. For each
service the URLconf named by ROOT_URLCONF is walked: `path()`/`re_path()` are
joined through `include()` (string modules, lists, tuples, router.urls),
`router.register()` is expanded into the list/detail routes its ViewSet
supports plus one route per `@action`, and each view is traced through the
imports to the class or function that defines it. Patterns under an `if`
(usually `settings.DEBUG`) are tagged. Includes that leave the repo (Django
admin, third-party apps) become a single stub row.

Module lookups search the service first, then every other Python project in
the repo (a directory with pyproject.toml or setup.py, and its src/), so
shared libraries resolve too.
"""

from __future__ import annotations

import argparse
import ast
import json
import os
import re
import shutil
import subprocess
import sys

SKIP_DIRS = {
    ".git",
    ".hg",
    ".venv",
    "venv",
    "env",
    "node_modules",
    "__pycache__",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
    ".tox",
    "site-packages",
    "dist",
    "build",
}
MAX_WALK_DEPTH = 6
MAX_DEPTH = 40

LIST_METHODS = {"list", "create"}
DETAIL_METHODS = {"retrieve", "update", "partial_update", "destroy"}
ALL_METHODS = LIST_METHODS | DETAIL_METHODS

# DRF classes, used when a base class does not resolve to code in the repo.
KNOWN_BASES = {
    "ModelViewSet": ALL_METHODS,
    "ReadOnlyModelViewSet": {"list", "retrieve"},
    "GenericViewSet": set(),
    "ViewSet": set(),
    "ViewSetMixin": set(),
    "ListModelMixin": {"list"},
    "CreateModelMixin": {"create"},
    "RetrieveModelMixin": {"retrieve"},
    "UpdateModelMixin": {"update", "partial_update"},
    "DestroyModelMixin": {"destroy"},
}

PATH_FUNCS = {"path", "re_path", "url"}
ROUTER_CLASSES = {"DefaultRouter", "SimpleRouter"}


# --------------------------------------------------------------------------- #
# Repo layout
# --------------------------------------------------------------------------- #


def walk_repo(root):
    """Return (service dirs, library roots) found under `root`."""
    services, projects = [], []
    root = os.path.abspath(root)
    base_depth = root.rstrip(os.sep).count(os.sep)
    for dirpath, dirnames, filenames in os.walk(root):
        depth = dirpath.count(os.sep) - base_depth
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS and not d.startswith("."))
        if depth >= MAX_WALK_DEPTH:
            dirnames[:] = []
        if "manage.py" in filenames:
            services.append(dirpath)
            dirnames[:] = []
        elif "pyproject.toml" in filenames or "setup.py" in filenames:
            projects.append(dirpath)
    lib_roots = []
    for project in projects:
        src = os.path.join(project, "src")
        lib_roots.append(src if os.path.isdir(src) else project)
    return services, lib_roots


def find_root_urlconf(service_dir):
    """ROOT_URLCONF from the service's settings, else the first `*.urls` that exists."""
    pattern = re.compile(r"""^ROOT_URLCONF\s*=\s*["']([\w.]+)["']""", re.M)
    found = []
    for dirpath, dirnames, filenames in os.walk(service_dir):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".") and d != "tests"]
        for filename in filenames:
            if not filename.endswith(".py"):
                continue
            path = os.path.join(dirpath, filename)
            try:
                with open(path, encoding="utf-8") as fh:
                    text = fh.read()
            except (OSError, UnicodeDecodeError):
                continue
            if "ROOT_URLCONF" not in text:
                continue
            match = pattern.search(text)
            if match:
                found.append(match.group(1))
    if found:
        # Settings split into base/local/production usually agree; take the most common.
        return max(set(found), key=found.count)
    for candidate in ("core.urls", "config.urls", "urls"):
        if module_file([service_dir], candidate):
            return candidate
    return "core.urls"


def module_file(roots, modname):
    parts = modname.split(".")
    for root in roots:
        base = os.path.join(root, *parts)
        for path in (base + ".py", os.path.join(base, "__init__.py")):
            if os.path.isfile(path):
                return path
    return None


# --------------------------------------------------------------------------- #
# Modules
# --------------------------------------------------------------------------- #


class Module:
    def __init__(self, path, modname, tree):
        self.path = path
        self.modname = modname
        self.tree = tree
        self.is_package = os.path.basename(path) == "__init__.py"
        self.imports = {}  # local name -> dotted target
        self.defs = {}  # name -> ClassDef / FunctionDef
        self.assigns = {}  # name -> last value node at module level
        for stmt in iter_module_stmts(tree.body):
            if isinstance(stmt, ast.Import):
                for alias in stmt.names:
                    if alias.asname:
                        self.imports[alias.asname] = alias.name
                    else:
                        head = alias.name.split(".")[0]
                        self.imports[head] = head
            elif isinstance(stmt, ast.ImportFrom):
                base = self.absolute(stmt.module, stmt.level)
                for alias in stmt.names:
                    if alias.name == "*":
                        continue
                    target = f"{base}.{alias.name}" if base else alias.name
                    self.imports[alias.asname or alias.name] = target
            elif isinstance(stmt, (ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
                self.defs[stmt.name] = stmt
            elif isinstance(stmt, ast.Assign):
                for target in stmt.targets:
                    if isinstance(target, ast.Name):
                        self.assigns[target.id] = stmt.value
            elif isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name) and stmt.value:
                self.assigns[stmt.target.id] = stmt.value

    def absolute(self, module, level):
        if not level:
            return module or ""
        package = self.modname.split(".")
        if not self.is_package:
            package = package[:-1]
        if level > 1:
            package = package[: len(package) - (level - 1)]
        base = ".".join(package)
        if module:
            return f"{base}.{module}" if base else module
        return base

    def const(self, name):
        node = self.assigns.get(name)
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            return node.value
        return None


def iter_module_stmts(body):
    """Module-level statements, descending into if/try/with blocks."""
    for stmt in body:
        yield stmt
        if isinstance(stmt, ast.If):
            yield from iter_module_stmts(stmt.body)
            yield from iter_module_stmts(stmt.orelse)
        elif isinstance(stmt, ast.Try):
            yield from iter_module_stmts(stmt.body)
            yield from iter_module_stmts(stmt.orelse)
            yield from iter_module_stmts(stmt.finalbody)
            for handler in stmt.handlers:
                yield from iter_module_stmts(handler.body)
        elif isinstance(stmt, ast.With):
            yield from iter_module_stmts(stmt.body)


def dotted(node):
    parts = []
    while isinstance(node, ast.Attribute):
        parts.append(node.attr)
        node = node.value
    if isinstance(node, ast.Name):
        parts.append(node.id)
        return ".".join(reversed(parts))
    return None


def call_name(node):
    if isinstance(node, ast.Call):
        name = dotted(node.func)
        if name:
            return name.split(".")[-1]
    return None


def kwarg(call, name):
    for keyword in call.keywords:
        if keyword.arg == name:
            return keyword.value
    return None


def const_str(node):
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    if isinstance(node, ast.JoinedStr):
        return "".join(
            v.value if isinstance(v, ast.Constant) else "{" + ast.unparse(v.value) + "}" for v in node.values
        )
    return None


def if_tag(test):
    return "debug" if "DEBUG" in ast.unparse(test) else "cond"


# --------------------------------------------------------------------------- #
# Service parser
# --------------------------------------------------------------------------- #


class ServiceParser:
    def __init__(self, repo_root, service_dir, lib_roots):
        self.repo_root = repo_root
        self.service_dir = service_dir
        self.roots = [service_dir] + [r for r in lib_roots if not r.startswith(service_dir + os.sep)]
        self.modules = {}  # path -> Module | None
        self.by_name = {}  # modname -> Module | None
        self.var_cache = {}
        self.rg_cache = {}
        self.errors = []
        self.entries = []

    # ----- module loading ------------------------------------------------- #

    def load(self, modname):
        if modname in self.by_name:
            return self.by_name[modname]
        path = module_file(self.roots, modname)
        module = self.load_path(path, modname) if path else None
        self.by_name[modname] = module
        return module

    def load_path(self, path, modname=None):
        if path in self.modules:
            return self.modules[path]
        if modname is None:
            modname = self.modname_for(path)
        try:
            with open(path, encoding="utf-8") as fh:
                tree = ast.parse(fh.read(), filename=path)
        except (OSError, SyntaxError, UnicodeDecodeError, ValueError) as err:
            self.errors.append(f"{self.rel(path)}: {err}")
            self.modules[path] = None
            return None
        module = Module(path, modname, tree)
        self.modules[path] = module
        return module

    def modname_for(self, path):
        for root in self.roots:
            if path.startswith(root + os.sep):
                rel = os.path.relpath(path, root)[: -len(".py")]
                parts = rel.split(os.sep)
                if parts[-1] == "__init__":
                    parts = parts[:-1]
                return ".".join(parts)
        return os.path.splitext(os.path.basename(path))[0]

    def rel(self, path):
        return os.path.relpath(path, self.repo_root)

    # ----- symbol resolution --------------------------------------------- #

    def resolve_dotted(self, name, depth=0):
        """('module', Module) | ('def', Module, node) | ('var', Module, name) | ('missing', Module, attr) | ('external', name)."""
        if depth > MAX_DEPTH:
            return ("external", name)
        parts = name.split(".")
        for i in range(len(parts), 0, -1):
            module = self.load(".".join(parts[:i]))
            if module is None:
                continue
            rest = parts[i:]
            if not rest:
                return ("module", module)
            return self.resolve_in(module, rest, depth + 1)
        return ("external", name)

    def resolve_in(self, module, attrs, depth=0):
        head, rest = attrs[0], attrs[1:]
        if head in module.defs:
            node = module.defs[head]
            if rest and isinstance(node, ast.ClassDef):
                for stmt in node.body:
                    if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)) and stmt.name == rest[0]:
                        return ("def", module, stmt)
            return ("def", module, node)
        if head in module.assigns:
            return ("var", module, head)
        if head in module.imports:
            return self.resolve_dotted(".".join([module.imports[head], *rest]), depth + 1)
        # A submodule that is not imported explicitly (package attribute access).
        if module.is_package:
            sub = self.load(f"{module.modname}.{head}")
            if sub is not None:
                return ("module", sub) if not rest else self.resolve_in(sub, rest, depth + 1)
        return ("missing", module, head)

    def resolve_ref(self, module, node):
        name = dotted(node)
        if not name:
            return None
        parts = name.split(".")
        head = parts[0]
        if head in module.defs or head in module.assigns:
            return self.resolve_in(module, parts)
        if head in module.imports:
            return self.resolve_dotted(".".join([module.imports[head], *parts[1:]]))
        return ("missing", module, parts[-1])

    def rg_find(self, name):
        """Fallback lookup of `class name` / `def name` in the service and libraries."""
        if name in self.rg_cache:
            return self.rg_cache[name]
        result = None
        rg = shutil.which("rg")
        if rg and re.fullmatch(r"\w+", name):
            cmd = [rg, "-n", "--no-heading", "-t", "py", "-e", rf"^\s*(class|def|async def)\s+{name}\b", *self.roots]
            try:
                out = subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout
            except (OSError, subprocess.SubprocessError):
                out = ""
            hits = []
            for line in out.splitlines():
                path, lineno, _ = line.split(":", 2)
                hits.append((os.sep + "tests" + os.sep in path or "/test_" in path, path, int(lineno)))
            if hits:
                _, path, lineno = sorted(hits)[0]
                module = self.load_path(os.path.abspath(path))
                node = None
                if module is not None:
                    node = next(
                        (n for n in ast.walk(module.tree) if getattr(n, "name", None) == name and n.lineno == lineno),
                        None,
                    )
                result = (module, node, os.path.abspath(path), lineno)
        self.rg_cache[name] = result
        return result

    def find_class(self, module, node):
        """Resolve a class reference to (Module, ClassDef), or None."""
        ref = self.resolve_ref(module, node)
        if ref and ref[0] == "def" and isinstance(ref[2], ast.ClassDef):
            return ref[1], ref[2]
        if ref and ref[0] == "missing":
            hit = self.rg_find(ref[2])
            if hit and isinstance(hit[1], ast.ClassDef):
                return hit[0], hit[1]
        return None

    def find_method(self, module, cls, name, depth=0):
        """(Module, FunctionDef) of `name` on `cls` or the first base that defines it."""
        for stmt in cls.body:
            if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)) and stmt.name == name:
                return module, stmt
        if depth > MAX_DEPTH:
            return None
        for base in cls.bases:
            found = self.find_class(module, base)
            target = found and self.find_method(found[0], found[1], name, depth + 1)
            if target:
                return target
        return None

    # ----- view targets --------------------------------------------------- #

    def view_target(self, module, node):
        """(label, file, line) for the view a pattern points at."""
        if isinstance(node, ast.Call):
            func = node.func
            if isinstance(func, ast.Attribute) and func.attr == "as_view":
                method = viewset_method(node)
                if method:
                    found = self.find_class(module, func.value)
                    target = found and self.find_method(found[0], found[1], method)
                    if target:
                        return (f"{dotted(func.value)}.{method}", target[0].path, target[1].lineno)
                return self.view_target(module, func.value)
            # Wrapped view, e.g. csrf_exempt(View.as_view()) or throttle("x")(view).
            for arg in node.args:
                if isinstance(arg, (ast.Call, ast.Name, ast.Attribute)):
                    target = self.view_target(module, arg)
                    if target[1]:
                        return target
            return self.view_target(module, func)
        label = dotted(node) or ast.unparse(node)
        ref = self.resolve_ref(module, node)
        if ref is None:
            return (label, None, None)
        if ref[0] == "def":
            return (label, ref[1].path, ref[2].lineno)
        if ref[0] == "var":
            var_module, var_name = ref[1], ref[2]
            value = var_module.assigns.get(var_name)
            if value is not None and value is not node and isinstance(value, (ast.Call, ast.Name, ast.Attribute)):
                target = self.view_target(var_module, value)
                return (label, target[1], target[2])
            return (label, var_module.path, assign_line(var_module, var_name))
        if ref[0] == "missing":
            hit = self.rg_find(ref[2])
            if hit:
                return (label, hit[2], hit[3])
        return (label, None, None)

    # ----- pattern lists ---------------------------------------------------- #

    def var_items(self, module, name, depth=0):
        """Items of a module-level list variable, replaying its assignments in order."""
        key = (module.path, name)
        if key in self.var_cache:
            return self.var_cache[key]
        self.var_cache[key] = []  # cycle guard
        items = self.replay(module, module.tree.body, name, [], depth)
        self.var_cache[key] = items
        return items

    def replay(self, module, body, name, tags, depth):
        items = []
        for stmt in body:
            if isinstance(stmt, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in stmt.targets):
                items = self.list_items(module, stmt.value, tags, depth)
            elif isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name) and stmt.target.id == name:
                if stmt.value is not None:
                    items = self.list_items(module, stmt.value, tags, depth)
            elif isinstance(stmt, ast.AugAssign) and isinstance(stmt.target, ast.Name) and stmt.target.id == name:
                items = items + self.list_items(module, stmt.value, tags, depth)
            elif isinstance(stmt, ast.Expr) and isinstance(stmt.value, ast.Call):
                func = stmt.value.func
                if isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name) and func.value.id == name:
                    args = stmt.value.args
                    if func.attr == "append" and args:
                        items = items + self.list_items(module, ast.List(elts=[args[0]]), tags, depth)
                    elif func.attr == "extend" and args:
                        items = items + self.list_items(module, args[0], tags, depth)
                    elif func.attr == "insert" and len(args) > 1:
                        items = self.list_items(module, ast.List(elts=[args[1]]), tags, depth) + items
            elif isinstance(stmt, ast.If):
                tag = [*tags, if_tag(stmt.test)]
                items = items + self.replay(module, stmt.body, name, tag, depth)
                items = items + self.replay(module, stmt.orelse, name, [*tags, "cond"], depth)
            elif isinstance(stmt, (ast.Try, ast.With)):
                items = items + self.replay(module, stmt.body, name, tags, depth)
        return items

    def list_items(self, module, node, tags, depth):
        """Flatten an expression that evaluates to a list of URL patterns."""
        if depth > MAX_DEPTH:
            return []
        if isinstance(node, (ast.List, ast.Tuple)):
            items = []
            for elt in node.elts:
                if isinstance(elt, ast.Starred):
                    items += self.list_items(module, elt.value, tags, depth + 1)
                elif call_name(elt) in PATH_FUNCS:
                    items.append(("path", module, elt, tags))
                elif isinstance(elt, (ast.Name, ast.Attribute)):
                    items += self.list_items(module, elt, tags, depth + 1)
            return items
        if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add):
            return self.list_items(module, node.left, tags, depth + 1) + self.list_items(
                module, node.right, tags, depth + 1
            )
        if isinstance(node, ast.IfExp):
            return self.list_items(module, node.body, tags, depth + 1)
        if isinstance(node, ast.Call) and call_name(node) == "list" and node.args:
            return self.list_items(module, node.args[0], tags, depth + 1)
        if isinstance(node, ast.Attribute) and node.attr == "urls":
            router = self.router_ref(module, node.value)
            if router:
                return [("router", router[0], router[1], tags)]
        if isinstance(node, (ast.Name, ast.Attribute)):
            ref = self.resolve_ref(module, node)
            if ref and ref[0] == "var":
                return self.var_items(ref[1], ref[2], depth + 1)
            if ref and ref[0] == "module":
                return self.var_items(ref[1], "urlpatterns", depth + 1)
        return []

    def router_ref(self, module, node):
        """(Module, var name) of a router instance referenced by `node`."""
        ref = self.resolve_ref(module, node)
        if ref and ref[0] == "var":
            value = ref[1].assigns.get(ref[2])
            if isinstance(value, ast.IfExp):
                value = value.body
            if isinstance(value, ast.Call) and (
                call_name(value) in ROUTER_CLASSES or "Router" in (call_name(value) or "")
            ):
                return ref[1], ref[2]
        return None

    # ----- expansion -------------------------------------------------------- #

    def expand(self, items, prefix, namespaces, depth=0):
        if depth > MAX_DEPTH:
            return
        for item in items:
            kind = item[0]
            if kind == "path":
                self.expand_path(item[1], item[2], item[3], prefix, namespaces, depth)
            elif kind == "router":
                self.expand_router(item[1], item[2], item[3], prefix, namespaces)

    def expand_path(self, module, call, tags, prefix, namespaces, depth):
        args = call.args
        route_node = args[0] if args else kwarg(call, "route")
        view = args[1] if len(args) > 1 else kwarg(call, "view")
        route = clean_route(const_str(route_node) if route_node is not None else "")
        if route is None:
            route = "{" + ast.unparse(route_node) + "}"
        name_node = kwarg(call, "name") or (args[3] if len(args) > 3 else None)
        name = const_str(name_node) if name_node is not None else None
        url = prefix + route
        if view is None:
            return
        if call_name(view) == "include":
            self.expand_include(module, call, view, tags, url, namespaces, depth)
            return
        label, file, line = self.view_target(module, view)
        if file is None:
            tags = [*tags, "external"]
        self.add(url, name, namespaces, label, file, line, module.path, call.lineno, tags)

    def expand_include(self, module, path_call, include_call, tags, url, namespaces, depth):
        arg = include_call.args[0] if include_call.args else kwarg(include_call, "arg")
        namespace_node = kwarg(include_call, "namespace") or (
            include_call.args[1] if len(include_call.args) > 1 else None
        )
        namespace = const_str(namespace_node) if namespace_node is not None else None
        items, app_name = None, None
        if isinstance(arg, ast.Tuple) and len(arg.elts) >= 2 and const_str(arg.elts[1]) is not None:
            app_name = const_str(arg.elts[1])
            if len(arg.elts) > 2 and const_str(arg.elts[2]) is not None:
                namespace = namespace or const_str(arg.elts[2])
            items = self.include_target(module, arg.elts[0], tags, depth)
        elif arg is not None:
            target = self.include_target(module, arg, tags, depth)
            if isinstance(target, tuple):
                items, app_name = target
            else:
                items = target
        if items is None:
            label = "include(" + (ast.unparse(arg) if arg is not None else "") + ")"
            self.add(url, None, namespaces, label, None, None, module.path, path_call.lineno, [*tags, "external"])
            return
        ns = namespace or app_name
        self.expand(
            [(k, m, n, [*tags, *[t for t in t2 if t not in tags]]) for k, m, n, t2 in items],
            url,
            [*namespaces, ns] if ns else namespaces,
            depth + 1,
        )

    def include_target(self, module, node, tags, depth):
        """Items for an include() argument, or (items, app_name) for a module, or None when unresolvable."""
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            target = self.load(node.value)
            if target is None:
                return None
            return (self.var_items(target, "urlpatterns", depth + 1), target.const("app_name"))
        if isinstance(node, (ast.Name, ast.Attribute)):
            ref = self.resolve_ref(module, node)
            if ref and ref[0] == "module":
                return (self.var_items(ref[1], "urlpatterns", depth + 1), ref[1].const("app_name"))
            if ref and ref[0] == "external":
                return None
            if isinstance(node, ast.Attribute) and node.attr == "urls" and not self.router_ref(module, node.value):
                if not ref or ref[0] != "var":
                    return None
        items = self.list_items(module, node, tags, depth + 1)
        if not items and not isinstance(node, (ast.List, ast.Tuple)):
            return None
        return items

    def expand_router(self, module, var, tags, prefix, namespaces):
        ctor = module.assigns.get(var)
        if isinstance(ctor, ast.IfExp):
            ctor = ctor.body
        trailing = "/"
        slash_node = kwarg(ctor, "trailing_slash") if isinstance(ctor, ast.Call) else None
        if isinstance(slash_node, ast.Constant):
            if slash_node.value is False:
                trailing = ""
            elif isinstance(slash_node.value, str):
                trailing = slash_node.value
        for call, reg_tags in router_registrations(module, var):
            self.expand_register(module, call, [*tags, *reg_tags], prefix, namespaces, trailing)

    def expand_register(self, module, call, tags, prefix, namespaces, trailing):
        args = call.args
        prefix_node = args[0] if args else kwarg(call, "prefix")
        viewset = args[1] if len(args) > 1 else kwarg(call, "viewset")
        basename_node = kwarg(call, "basename") or (args[2] if len(args) > 2 else None)
        reg_prefix = clean_route(const_str(prefix_node) if prefix_node is not None else "") or ""
        reg_prefix = reg_prefix.strip("/")
        if viewset is None:
            return
        label, file, line = self.view_target(module, viewset)
        found = self.find_class(module, viewset)
        info = self.class_info(*found) if found else None
        basename = const_str(basename_node) if basename_node is not None else None
        if basename is None:
            basename = (info and info["model"]) or reg_prefix.replace("/", "-") or label.split(".")[-1].lower()
        lookup = "<" + ((info and info["lookup"]) or "pk") + ">"

        def route(*parts):
            return prefix + "/".join(p for p in parts if p) + trailing

        if info is None or info["unknown"]:
            has_list = has_detail = True
        else:
            has_list = bool(info["methods"] & LIST_METHODS)
            has_detail = bool(info["methods"] & DETAIL_METHODS)
            if not has_list and not has_detail and not info["actions"]:
                has_list = has_detail = True
        url_line = call.lineno
        if has_list:
            self.add(route(reg_prefix), f"{basename}-list", namespaces, label, file, line, module.path, url_line, tags)
        if has_detail:
            self.add(
                route(reg_prefix, lookup),
                f"{basename}-detail",
                namespaces,
                label,
                file,
                line,
                module.path,
                url_line,
                tags,
            )
        for action in (info and info["actions"]) or []:
            parts = [reg_prefix, lookup, action["url_path"]] if action["detail"] else [reg_prefix, action["url_path"]]
            self.add(
                route(*parts),
                f"{basename}-{action['url_name']}",
                namespaces,
                f"{label}.{action['name']}",
                action["file"],
                action["line"],
                module.path,
                url_line,
                tags,
            )

    def class_info(self, module, cls, depth=0, seen=None):
        """Handler methods, @actions, lookup and model of a ViewSet, following its bases."""
        seen = seen or set()
        info = {"methods": set(), "actions": [], "lookup": None, "model": None, "unknown": False}
        key = (module.path, cls.name, cls.lineno)
        if key in seen or depth > MAX_DEPTH:
            return info
        seen.add(key)
        action_names = set()
        for stmt in cls.body:
            if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)):
                info["methods"].add(stmt.name)
                action = action_decorator(stmt)
                if action is not None:
                    action.update(name=stmt.name, file=module.path, line=stmt.lineno)
                    info["actions"].append(action)
                    action_names.add(stmt.name)
            elif isinstance(stmt, ast.Assign):
                for target in stmt.targets:
                    if not isinstance(target, ast.Name):
                        continue
                    if target.id in ("lookup_url_kwarg", "lookup_field") and const_str(stmt.value):
                        if target.id == "lookup_url_kwarg" or info["lookup"] is None:
                            info["lookup"] = const_str(stmt.value)
                    elif target.id == "queryset" and info["model"] is None:
                        info["model"] = queryset_model(stmt.value)
        for base in cls.bases:
            name = (dotted(base) or "").split(".")[-1]
            found = self.find_class(module, base)
            if found:
                parent = self.class_info(found[0], found[1], depth + 1, seen)
            elif name in KNOWN_BASES:
                parent = {
                    "methods": set(KNOWN_BASES[name]),
                    "actions": [],
                    "lookup": None,
                    "model": None,
                    "unknown": False,
                }
            else:
                parent = {
                    "methods": set(),
                    "actions": [],
                    "lookup": None,
                    "model": None,
                    "unknown": name.endswith("ViewSet"),
                }
            info["methods"] |= parent["methods"]
            info["unknown"] = info["unknown"] or parent["unknown"]
            info["lookup"] = info["lookup"] or parent["lookup"]
            info["model"] = info["model"] or parent["model"]
            for action in parent["actions"]:
                if action["name"] not in action_names:
                    info["actions"].append(action)
                    action_names.add(action["name"])
        return info

    # ----- output ----------------------------------------------------------- #

    def add(self, url, name, namespaces, label, file, line, url_file, url_line, tags):
        full_name = ":".join([*namespaces, name]) if name else None
        self.entries.append(
            {
                "url": "/" + url.lstrip("/"),
                "name": full_name,
                "view": label,
                "file": file,
                "line": line,
                "url_file": url_file,
                "url_line": url_line,
                "tags": sorted(set(tags)),
            }
        )

    def run(self):
        urlconf = find_root_urlconf(self.service_dir)
        module = self.load(urlconf)
        if module is None:
            self.errors.append(f"{self.rel(self.service_dir)}: ROOT_URLCONF {urlconf} not found")
        else:
            self.expand(self.var_items(module, "urlpatterns"), "", [])
        return {
            "name": service_name(self.repo_root, self.service_dir),
            "dir": self.service_dir,
            "urlconf": urlconf,
            "entries": self.entries,
            "files": sorted(p for p, m in self.modules.items() if m is not None),
            "errors": self.errors,
        }


def router_registrations(module, var):
    """(register call, tags) for every `<var>.register(...)` at module level."""

    def walk(body, tags):
        for stmt in body:
            if isinstance(stmt, ast.Expr) and isinstance(stmt.value, ast.Call):
                func = stmt.value.func
                if (
                    isinstance(func, ast.Attribute)
                    and func.attr == "register"
                    and isinstance(func.value, ast.Name)
                    and func.value.id == var
                ):
                    yield stmt.value, tags
            elif isinstance(stmt, ast.If):
                yield from walk(stmt.body, [*tags, if_tag(stmt.test)])
                yield from walk(stmt.orelse, [*tags, "cond"])
            elif isinstance(stmt, (ast.Try, ast.With)):
                yield from walk(stmt.body, tags)

    return list(walk(module.tree.body, []))


def viewset_method(as_view_call):
    """Handler named by `ViewSet.as_view({"get": "list"})`, preferring GET."""
    actions = as_view_call.args[0] if as_view_call.args else kwarg(as_view_call, "actions")
    if not isinstance(actions, ast.Dict):
        return None
    methods = {const_str(k): const_str(v) for k, v in zip(actions.keys, actions.values) if k is not None}
    return methods.get("get") or next((v for v in methods.values() if v), None)


def action_decorator(func):
    for decorator in func.decorator_list:
        node = decorator.func if isinstance(decorator, ast.Call) else decorator
        if (dotted(node) or "").split(".")[-1] != "action":
            continue
        detail = False
        url_path = func.name
        url_name = func.name.replace("_", "-")
        if isinstance(decorator, ast.Call):
            detail_node = kwarg(decorator, "detail")
            if isinstance(detail_node, ast.Constant):
                detail = bool(detail_node.value)
            url_path = const_str(kwarg(decorator, "url_path")) or url_path
            url_name = const_str(kwarg(decorator, "url_name")) or url_name
        return {"detail": detail, "url_path": clean_route(url_path).strip("/"), "url_name": url_name}
    return None


def queryset_model(node):
    """`Model` of `queryset = Model.objects...`, lowercased like DRF's default basename."""
    while isinstance(node, (ast.Call, ast.Attribute)):
        if isinstance(node, ast.Attribute) and node.attr == "objects" and isinstance(node.value, ast.Name):
            return node.value.id.lower()
        node = node.func if isinstance(node, ast.Call) else node.value
    return None


def assign_line(module, name):
    for stmt in iter_module_stmts(module.tree.body):
        if isinstance(stmt, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in stmt.targets):
            return stmt.lineno
    return 1


def clean_route(route):
    """Strip the ^ and $ anchors of a regex route; path() routes pass through unchanged."""
    if route is None:
        return None
    if route.startswith("^"):
        route = route[1:]
    if route.endswith("$") and not route.endswith("\\$"):
        route = route[:-1]
    # Regex named groups read like path() converters: (?P<pk>[^/.]+) -> <pk>.
    return re.sub(r"\(\?P<(\w+)>(?:[^()]|\([^()]*\))*\)", r"<\1>", route)


def service_name(repo_root, service_dir):
    if os.path.abspath(service_dir) == os.path.abspath(repo_root):
        return os.path.basename(os.path.abspath(repo_root))
    return os.path.basename(service_dir.rstrip(os.sep))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", required=True, help="repository root")
    parser.add_argument("--service", action="append", default=[], help="service dir (repeatable); default: all")
    args = parser.parse_args(argv)
    root = os.path.abspath(args.root)
    services, lib_roots = walk_repo(root)
    if args.service:
        services = [os.path.abspath(s) for s in args.service]
    result = []
    for service in services:
        try:
            result.append(ServiceParser(root, service, lib_roots).run())
        except Exception as err:  # keep the other services when one breaks the parser
            result.append(
                {
                    "name": service_name(root, service),
                    "dir": service,
                    "urlconf": None,
                    "entries": [],
                    "files": [],
                    "errors": [f"{type(err).__name__}: {err}"],
                }
            )
    json.dump({"root": root, "services": result}, sys.stdout)


if __name__ == "__main__":
    main()
