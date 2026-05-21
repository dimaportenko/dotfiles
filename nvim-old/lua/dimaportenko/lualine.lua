local status, lualine = pcall(require, 'lualine')
if not status then
  return
end

lualine.setup {
  options = {
    icons_enabled = true,
    -- theme = 'tokyonight',
    theme = 'catppuccin',
    component_separators = { '', '' },
    section_separators = { '', '' },
    disabled_filetypes = {}
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = {
      'diagnostics',
      'diff',
      'fileformat',
      'filetype'
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  },
}
