"""Tests for parser.py. Run: python3 -m unittest discover -s lua/custom/django_urls/tests"""

import os
import sys
import tempfile
import textwrap
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import parser as django_parser  # noqa: E402

FILES = {
    "svc/manage.py": "",
    "svc/core/__init__.py": "",
    "svc/core/config/base.py": 'ROOT_URLCONF = "core.urls"\n',
    "svc/core/views.py": """
        from django.views import View

        class HealthView(View):
            pass

        def home(request):
            pass
    """,
    "svc/core/urls.py": """
        from django.conf import settings
        from django.contrib import admin
        from django.urls import include, path, re_path
        from django.views.decorators.csrf import csrf_exempt

        from core import views
        from core.views import HealthView

        urlpatterns = [
            path("health/", HealthView.as_view(), name="health"),
            path("", csrf_exempt(views.home), name="home"),
            path("admin/", admin.site.urls),
            path("api/<version>/", include("shop.urls")),
            path("auth/", include("gs_lib.urls")),
            path("o/", include("oauth2_provider.urls", namespace="oauth2")),
            path("nested/", include([path("ping/", views.home, name="ping")])),
            re_path(r"^files/(?P<path>.*)$", views.home, name="files"),
        ]

        if settings.DEBUG:
            urlpatterns += [path("__debug__/", include("debug_toolbar.urls"))]
    """,
    "svc/shop/__init__.py": "",
    "svc/shop/views.py": """
        from rest_framework import mixins, viewsets
        from rest_framework.decorators import action

        class BaseViewSet(viewsets.GenericViewSet):
            @action(detail=False, url_path="export-all")
            def export(self, request):
                pass

        class OrderViewSet(viewsets.ModelViewSet):
            queryset = Order.objects.all()
            lookup_field = "uid"

            @action(detail=True, methods=["post"])
            def cancel_order(self, request, uid=None):
                pass

        class ReportViewSet(mixins.ListModelMixin, BaseViewSet):
            pass

        class PlainViewSet(viewsets.ViewSet):
            def retrieve(self, request, pk=None):
                pass
    """,
    "svc/shop/urls.py": """
        from django.urls import include, path
        from rest_framework.routers import DefaultRouter

        from shop.views import OrderViewSet, PlainViewSet, ReportViewSet

        app_name = "shop"

        router = DefaultRouter()
        router.register(r"orders", OrderViewSet)
        router.register("reports", ReportViewSet, basename="report")
        router.register("plain", PlainViewSet, basename="plain")

        urlpatterns = [
            path("", include(router.urls)),
            path("orders/<int:pk>/print/", OrderViewSet.as_view({"get": "cancel_order"}), name="order-print"),
        ]
    """,
    "libs/gs-lib/pyproject.toml": "",
    "libs/gs-lib/gs_lib/__init__.py": "",
    "libs/gs-lib/gs_lib/views.py": "def login(request):\n    pass\n",
    "libs/gs-lib/gs_lib/urls.py": """
        from django.urls import path
        from gs_lib import views

        urlpatterns = [path("login/", views.login, name="login")]
    """,
    "svc/.venv/lib/site/manage.py": "",
    "svc/node_modules/x/urls.py": "",
}


class ParserTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = os.path.realpath(cls.tmp.name)
        for rel, body in FILES.items():
            path = os.path.join(cls.root, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as fh:
                fh.write(textwrap.dedent(body).lstrip())
        services, lib_roots = django_parser.walk_repo(cls.root)
        cls.services = services
        cls.result = django_parser.ServiceParser(cls.root, services[0], lib_roots).run()
        cls.by_name = {e["name"]: e for e in cls.result["entries"] if e["name"]}
        cls.by_url = {e["url"]: e for e in cls.result["entries"]}

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def where(self, entry):
        return (os.path.relpath(entry["file"], self.root), entry["line"])

    def test_discovers_service_and_skips_venv_and_node_modules(self):
        self.assertEqual(self.services, [os.path.join(self.root, "svc")])
        self.assertEqual(self.result["urlconf"], "core.urls")
        self.assertEqual(self.result["errors"], [])

    def test_class_view_and_wrapped_function_view(self):
        self.assertEqual(self.by_name["health"]["url"], "/health/")
        self.assertEqual(self.where(self.by_name["health"]), ("svc/core/views.py", 3))
        self.assertEqual(self.where(self.by_name["home"]), ("svc/core/views.py", 6))

    def test_include_string_module_with_app_name_and_prefix(self):
        entry = self.by_name["shop:order-list"]
        self.assertEqual(entry["url"], "/api/<version>/orders/")
        self.assertEqual(os.path.relpath(entry["url_file"], self.root), "svc/shop/urls.py")

    def test_router_lookup_field_model_basename_and_detail_action(self):
        self.assertEqual(self.by_name["shop:order-detail"]["url"], "/api/<version>/orders/<uid>/")
        action = self.by_name["shop:order-cancel-order"]
        self.assertEqual(action["url"], "/api/<version>/orders/<uid>/cancel_order/")
        self.assertEqual(action["view"], "OrderViewSet.cancel_order")
        self.assertEqual(self.where(action), ("svc/shop/views.py", 14))

    def test_viewset_routes_inferred_from_mixins_and_inherited_actions(self):
        self.assertIn("shop:report-list", self.by_name)
        self.assertNotIn("shop:report-detail", self.by_name)
        self.assertEqual(self.by_name["shop:report-export"]["url"], "/api/<version>/reports/export-all/")
        self.assertIn("shop:plain-detail", self.by_name)
        self.assertNotIn("shop:plain-list", self.by_name)

    def test_as_view_action_mapping_jumps_to_method(self):
        entry = self.by_name["shop:order-print"]
        self.assertEqual(entry["view"], "OrderViewSet.cancel_order")
        self.assertEqual(self.where(entry), ("svc/shop/views.py", 14))

    def test_library_include_resolves_into_libs(self):
        entry = self.by_name["login"]
        self.assertEqual(entry["url"], "/auth/login/")
        self.assertEqual(self.where(entry), ("libs/gs-lib/gs_lib/views.py", 1))

    def test_third_party_include_and_admin_are_external_stubs(self):
        self.assertIn("external", self.by_url["/o/"]["tags"])
        self.assertIsNone(self.by_url["/o/"]["file"])
        self.assertIn("external", self.by_url["/admin/"]["tags"])

    def test_debug_block_is_tagged(self):
        self.assertEqual(self.by_url["/__debug__/"]["tags"], ["debug", "external"])
        self.assertEqual(self.by_name["health"]["tags"], [])

    def test_inline_include_list_and_regex_groups(self):
        self.assertEqual(self.by_name["ping"]["url"], "/nested/ping/")
        self.assertEqual(self.by_name["files"]["url"], "/files/<path>")


if __name__ == "__main__":
    unittest.main()
