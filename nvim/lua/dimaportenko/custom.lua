-- Shorten function name
local keymap = vim.api.nvim_set_keymap
local cmd = vim.api.nvim_create_user_command
local api = vim.api

local opts = { noremap = true, silent = true }

function _CUSTOM_SETUP()
  cmd("RnStart", "terminal yarn start", {})
end

function _COPY_TO_CLIPBOARD(value)
  vim.fn.setreg("+", value)
end

-- copy current buffer filepath
function _COPY_BUFFER_FILEPATH()
  -- get file path of current buffer
  local path = vim.api.nvim_buf_get_name(0)
  -- copy to clipboard
  _COPY_TO_CLIPBOARD(path)

  print(path)
end

-- copy current buffer filepath
function _OPEN_BUFFER_IN_FINDER()
  -- get directory path of current buffer
  local path = vim.fn.expand("%:p:h")
  -- run command 'open path'
  vim.fn.system("open " .. path)
end

function _COPY_CWD()
  local path = vim.fn.getcwd()
  _COPY_TO_CLIPBOARD(path)
end

function _XCODE_BUILD_CLEAN()
  local xcodeproj = vim.fn.glob("ios/*.xcodeproj")
  -- local xcworkspace = vim.fn.glob("ios/*.xcworkspace")

  -- print(vim.inspect(xcodeproj))
  -- print(vim.inspect(xcworkspace))

  -- if #xcworkspace > 0 then
  --   vim.api.nvim_command("!xcodebuild clean -workspace " .. xcworkspace)
  -- else
  if #xcodeproj > 0 then
    vim.api.nvim_command("!xcodebuild clean -project " .. xcodeproj)
  else
    vim.api.nvim_err_write("No Xcode project or workspace found in the `ios` directory.")
  end
end

cmd("CopyBufferFilepath", "lua _COPY_BUFFER_FILEPATH()", {})
cmd("CopyCurrentWorkingDir", "lua _COPY_CWD()", {})

cmd("OpenBufferInFinder", "lua _OPEN_BUFFER_IN_FINDER()", {})

cmd("XcodeOpenRN", "!xed ios", {})
cmd("XcodeCleanIOSBuildRN", "lua _XCODE_BUILD_CLEAN()", {})

cmd("AndroidStudioRN", "!open android/ -a Android\\ Studio", {})
-- for Android metro bundler connect
-- adb reverse tcp: 8081 tcp:8081
cmd("AdbReverseTcp", "!adb reverse tcp:8081 tcp:8081", {})

-- bash command to find and kill process on port 8081
-- lsof -i:8081 -t | xargs kill -9
cmd("KillReactNativeBundler", "!lsof -i:8081 -t | xargs kill -9", {})

-- Telescope simulators run
cmd("SimulatorsRun", "Telescope simulators run", {})

-- live_grep for selected node in nvim-tree
-- https://github.com/alexander-born/.cfg/blob/aa6475fd2b696ea07209e68a6db068cacff8e205/nvim/.config/nvim/lua/config/nvimtree.lua#L23
function _LIVE_GREP_AT_NVIM_TREE_NODE()
  -- node pcall
  local ok, node = pcall(require('nvim-tree.lib').get_node_at_cursor)
  -- local node = require('nvim-tree.lib').get_node_at_cursor()
  if not ok then return end

  if not node then return end
  require('telescope.builtin').live_grep({ search_dirs = { node.absolute_path } })
end

keymap("n", "<S-t>", "<cmd>lua _LIVE_GREP_AT_NVIM_TREE_NODE()<cr>", opts)

-- open nvim tree node in finder
function _OPEN_NVIM_TREE_NODE_IN_FINDER()
  local node = require('nvim-tree.lib').get_node_at_cursor()
  if not node then return end

  local path = vim.fn.fnamemodify(node.absolute_path, ":p:h")
  print(path)

  vim.fn.system("open " .. path)
end

cmd("OpenNvimTreeNodeInFinder", "lua _OPEN_NVIM_TREE_NODE_IN_FINDER()", {})

-- ios simulator list
-- xcrun simctl list

-- close all buffers
cmd("CloseAllBuffers", "bufdo bwipeout", {})


-- close current focused term
function _TOGGLE_FOCUSED_TERM()
  local toggleterm = require('toggleterm')
  local name = api.nvim_buf_get_name(api.nvim_get_current_buf())
  local parts = vim.split(name, "#", {})
  local id = tonumber(parts[#parts])
  toggleterm.toggle(id)
end

cmd("ToggleFocusedTerm", "lua _TOGGLE_FOCUSED_TERM()", {})
keymap("n", "<leader>ct", "<cmd>lua _TOGGLE_FOCUSED_TERM()<cr>", opts)
