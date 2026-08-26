return {
  -- Use the rust-analyzer that ships with the active rustup toolchain instead of
  -- the Mason-managed copy. The rustup binary is always version-locked to `rustc`,
  -- so the proc-macro server ABI can never drift out of sync after a `rustup update`.
  -- (Fixes: "proc-macro server's api version (N) is newer than rust-analyzer's (M)".)
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        cmd = { "rustup", "run", "stable", "rust-analyzer" },
        -- Stamps the target picked with `:RustTarget` into every client that
        -- starts, wrapping rustaceanvim's own settings loader. See
        -- `custom/rust_target.lua` for why the built-in
        -- `:RustAnalyzer target` cannot be used here.
        settings = function(project_root, default_settings)
          return require("custom.rust_target").settings(project_root, default_settings)
        end,
      },
    },
    -- rust-analyzer analyses one target at a time, so switching between macOS
    -- and iOS decides which `#[cfg(...)]` branches are live. `:RustTarget`
    -- completes over the installed targets, and opens a picker with no
    -- argument.
    init = function()
      require("custom.rust_target").setup()
    end,
    keys = {
      { "<leader>rt", "<cmd>RustTarget<cr>", desc = "Rust: switch rust-analyzer target" },
    },
  },

  -- Format Rust as a three-step chain: `rustfmt`, then `dx fmt`, then an awk
  -- cleanup pass. conform runs them left-to-right, piping each one's stdout
  -- into the next.
  --
  -- 1. rustfmt never descends into proc-macro bodies, so it formats the
  --    surrounding Rust (and preserves blank lines between items) while leaving
  --    everything inside Dioxus `rsx! { ... }` blocks untouched.
  --    We deliberately do NOT use `dx fmt --all-code`: its all-code path
  --    re-serializes the whole file and strips blank lines between top-level
  --    functions (dx 0.7.9). Running rustfmt separately avoids that bug, since
  --    dx without --all-code never rewrites the non-rsx code.
  -- 2. dx_rsx formats only the rsx and passes the rest of the file through
  --    verbatim. `--split-line-attributes` puts each rsx attribute/child on its
  --    own line. Downside in dx 0.7.9: it also injects a blank line right after
  --    every element's opening `{` (the empty attribute slot), even for
  --    elements with no attributes. That blank reappears on every save.
  -- 3. rsx_cleanup undoes two cosmetic quirks of dx's split-line output, using
  --    one line of look-back (the `buf` previous line). When `buf` ends in `{`:
  --      * a following blank line is dropped (the injected attribute-slot blank);
  --      * a following `}`-only line is joined back, so `Counter {\n}` collapses
  --        to `Counter {}`.
  --    rustfmt already strips leading-block blank lines and collapses empty Rust
  --    blocks before dx runs, so the only lines this rule touches are the rsx
  --    ones dx just produced. Blank lines between functions (preceded by `}`)
  --    and between statements (not preceded by `{`) are left untouched.
  --
  -- `--file -` makes dx read the buffer from stdin and write to stdout.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        dx_rsx = {
          command = "dx",
          args = { "fmt", "--split-line-attributes", "--file", "-" },
          stdin = true,
        },
        rsx_cleanup = {
          command = "awk",
          -- [==[ ... ]==] is a raw Lua string so the awk regex backslashes and
          -- the `]]` inside [[:space:]] pass through untouched.
          args = { [==[{ line=$0; if (havebuf && buf ~ /\{[[:space:]]*$/) { if (line ~ /^[[:space:]]*$/) next; if (line ~ /^[[:space:]]*\}[[:space:]]*$/) { sub(/[[:space:]]*$/,"",buf); print buf "}"; havebuf=0; next } } if (havebuf) print buf; buf=line; havebuf=1 } END { if (havebuf) print buf }]==] },
          stdin = true,
        },
      },
      formatters_by_ft = {
        rust = { "rustfmt", "dx_rsx", "rsx_cleanup" },
      },
    },
  },
}
