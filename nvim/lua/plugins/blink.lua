return {
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      sources = {
        per_filetype = {
          markdown = { inherit_defaults = true, "project_paths" },
          mdx = { inherit_defaults = true, "project_paths" },
          ["markdown.mdx"] = { inherit_defaults = true, "project_paths" },
        },
        providers = {
          project_paths = {
            name = "Project paths",
            module = "custom.blink_project_paths",
            min_keyword_length = 0,
            score_offset = 100,
          },
        },
      },
      keymap = {
        preset = "super-tab",
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = {
          require("blink.cmp.keymap.presets").get("super-tab")["<Tab>"][1],
          require("lazyvim.util.cmp").map({ "snippet_forward", "ai_accept" }),
          "fallback",
        },
      },
    },
  },
}
