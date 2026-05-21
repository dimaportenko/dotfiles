return {
  {
    "iamcco/markdown-preview.nvim",
    init = function()
      vim.g.mkdp_preview_options = {
        mkit = { breaks = true, linkify = true },
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {},
      }
    end,
  },
}
