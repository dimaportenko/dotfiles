-- vim.cmd "colorscheme default"

-- vim.g.tokyonight_style = "night"

-- local colorscheme = "tokyonight"
local colorscheme = "catppuccin"

---
-- Catppuccin configuration START -- 
---
local status, catppuccin = pcall(require, "catppuccin")


if (not status) then
  -- print error message
  error("Catppuccin colorscheme is not installed")
  return
end

catppuccin.setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
  transparent_background = true,
})

---
-- Catppuccin configuration END -- 
---

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)

if not status_ok then 
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end
