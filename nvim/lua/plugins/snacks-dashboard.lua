return {
  "snacks.nvim",
  init = function()
    local function set_dashboard_hl()
      vim.api.nvim_set_hl(0, "SnacksDashboardHeader", {
        fg = "#89B4FA",
        bold = true,
      })
    end

    set_dashboard_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = set_dashboard_hl,
    })
  end,
  opts = {
    dashboard = {
      width = 70,
      preset = {
        header = table.concat({
          "   ██████╗  ██████╗ ███████╗ ██████╗ ██╗   ██╗██████╗  ██████╗███████╗",
          "  ██╔════╝ ██╔═══██╗██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔════╝██╔════╝",
          "  ██║  ███╗██║   ██║███████╗██║   ██║██║   ██║██████╔╝██║     █████╗  ",
          "  ██║   ██║██║   ██║╚════██║██║   ██║██║   ██║██╔══██╗██║     ██╔══╝  ",
          "  ╚██████╔╝╚██████╔╝███████║╚██████╔╝╚██████╔╝██║  ██║╚██████╗███████╗",
          "   ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝",
        }, "\n"),
      },
    },
  },
}
