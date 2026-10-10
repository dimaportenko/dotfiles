-- Search every Django URL pattern in the repo and jump to its view. The code
-- lives in `lua/custom/django_urls/`; this spec only lazy-loads it, so nothing
-- runs until a keymap or `:DjangoUrls` is used.
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/custom/django_urls",
    name = "django-urls",
    dependencies = { "nvim-telescope/telescope.nvim" },
    cmd = "DjangoUrls",
    keys = {
      {
        "<leader>su",
        function()
          require("custom.django_urls").pick({ scope = "all" })
        end,
        desc = "Django URLs (all services)",
      },
      {
        "<leader>sU",
        function()
          require("custom.django_urls").pick({ scope = "current" })
        end,
        desc = "Django URLs (current service)",
      },
    },
    config = function()
      require("custom.django_urls").setup()
    end,
  },
}
