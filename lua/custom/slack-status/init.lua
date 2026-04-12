-- ~/.config/nvim/lua/slack_status.lua
local M = {}

local uv = vim.loop

local config = {
  enabled = true, -- Set to false to disable slack-status plugin
  binary_path = "slack-status", -- Go binary in PATH
  default_status = "Working in Neovim",
  idle_status = "Idle",
  idle_emoji = ":coffee:",
  default_emoji = ":computer:",
  mappings = {
    gitcommit = ":memo:",
    toggleterm = ":shell:",
    help = ":book:",
    man = ":books:",
    TelescopePrompt = ":mag:",
    lazy = ":gear:",
    mason = ":toolbox:",
    packer = ":package:",
  },
  fallbacks = {
    prompt = ":speech_balloon:",
    explorer = ":file_folder:",
    editing = ":keyboard:",
    plugins = ":hammer_and_wrench:",
    terminal = ":computer:",
    docs = ":notebook:",
  },
  debounce_ms = 3000, -- minimum time between same status updates
  idle_ms = 300000, -- 5 minutes idle
}

-- State tracking for debounce
local last_status_text = nil
local last_emoji = nil
local last_update_time = 0
local idle_timer = nil

-- Load .env file for TOKEN/COOKIES
local function load_env_file(path)
  local f = io.open(path, "r")
  if not f then return end
  for line in f:lines() do
    local key, val = line:match "^([%w_]+)=(.+)$"
    if key and val then
      val = val:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
      vim.fn.setenv(key, val)
    end
  end
  f:close()
end

load_env_file(vim.fn.fnamemodify("~/.config/slack-status/slack-status.env", ":p"))

-- Run Go binary asynchronously
local function set_slack_status(text, emoji)
  if vim.fn.executable(config.binary_path) == 0 then
    vim.notify("Slack status binary not found: " .. config.binary_path, vim.log.levels.ERROR)
    return
  end

  local env_file = vim.fn.fnamemodify("~/.config/slack-status/slack-status.env", ":p")
  local env_dir = vim.fn.fnamemodify(env_file, ":h")
  local err_log_file = env_dir .. "/slack-status-error.log"

  local cmd = { config.binary_path, "-s", text, "-e", emoji }
  vim.fn.jobstart(cmd, {
    detach = true,
    stderr_buffered = true,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local msg = vim.trim(table.concat(data, "\n"))
        if msg ~= "" then
          local f = io.open(err_log_file, "a")
          if f then
            f:write(
              os.date "[%Y-%m-%d %H:%M:%S] "
                .. string.format("Setting status to %s %s failed due to ", text, emoji)
                .. msg
                .. "\n"
            )
            f:close()
          end
        end
      end
    end,
  })
end

-- Get the top-most git repo name
local function get_git_repo_name()
  -- Find the git root directory
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if not git_root or git_root == "" then return nil end
  -- Return just the folder name (repo name)
  return vim.fn.fnamemodify(git_root, ":t")
end

-- Cord-style activity detection
local function detect_activity()
  local ft = vim.bo.filetype
  local bt = vim.bo.buftype
  local bufname = vim.api.nvim_buf_get_name(0)

  -- Committing
  if ft == "gitcommit" then
    local repo = get_git_repo_name()
    if repo then
      return string.format("Committing changes in %s...", repo)
    else
      return "Committing changes..."
    end
  end

  -- ToggleTerm
  if ft == "toggleterm" or bt == "terminal" then return "Hacking away in the terminal" end

  -- Help or man pages
  if ft == "help" or ft == "man" then return "Reading documentation" end

  -- Editing
  if bt == "" and ft ~= "" and bufname ~= "" then
    local topdir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    return string.format("Editing %s (%s) in %s", vim.fn.expand "%:t", ft, topdir)
  end

  -- File browsing
  if ft == "netrw" or ft == "neo-tree" or ft == "oil" or bt == "directory" then return "Browsing files" end

  -- Searching
  if ft == "TelescopePrompt" or bt == "prompt" then return "Searching..." end

  -- Plugin managers
  if ft == "lazy" or ft == "mason" or ft == "packer" then return "Managing plugins" end

  return config.default_status
end

-- Decide emoji based on filetype/context
local function get_emoji()
  local ft = vim.bo.filetype
  local bt = vim.bo.buftype

  -- Direct mapping from config
  if ft and config.mappings[ft] then return config.mappings[ft] end

  -- Prompts (Telescope, etc.)
  if bt == "prompt" or ft == "TelescopePrompt" then return config.fallbacks.prompt or ":speech_balloon:" end

  -- File explorers (neo-tree, netrw, oil)
  if ft == "neo-tree" or ft == "netrw" or ft == "oil" or bt == "directory" then
    return config.fallbacks.explorer or ":file_folder:"
  end

  -- Terminal
  if ft == "toggleterm" or bt == "terminal" then return config.fallbacks.terminal or ":computer:" end

  -- Documentation / Help
  if ft == "help" or ft == "man" then return config.fallbacks.docs or ":notebook:" end

  -- Plugin managers
  if ft == "lazy" or ft == "mason" or ft == "packer" then return config.fallbacks.plugins or ":hammer_and_wrench:" end

  -- Editing anything else
  return config.fallbacks.editing or ":keyboard:"
end

-- Update Slack status with debounce
function M.update_status(force)
  if not config.enabled then return end
  
  local env_file = vim.fn.fnamemodify("~/.config/slack-status/slack-status.env", ":p")
  local env_dir = vim.fn.fnamemodify(env_file, ":h")
  local log_file = env_dir .. "/slack-status.log"
  local emoji = ""
  local status_text = detect_activity()
  if status_text == config.default_status then
    emoji = config.default_emoji or ":rocket:"
  else
    emoji = get_emoji()
  end
  local now = uv.now()

  -- Debounce
  if
    not force
    and status_text == last_status_text
    and emoji == last_emoji
    and (now - last_update_time < config.debounce_ms)
  then
    local f = io.open(log_file, "a")
    if f then
      f:write(os.date "[%Y-%m-%d %H:%M:%S] Debouncing " .. status_text .. " " .. emoji .. "\n")
      f:close()
    end
    return
  else
    local f = io.open(log_file, "a")
    if f then
      f:write(os.date "[%Y-%m-%d %H:%M:%S] Sending " .. status_text .. " " .. emoji .. "\n")
      f:close()
    end
  end

  last_status_text = status_text
  last_emoji = emoji
  last_update_time = now
  set_slack_status(status_text, emoji)

  -- Reset idle timer
  if idle_timer then
    idle_timer:stop()
    idle_timer:close()
  end
  idle_timer = uv.new_timer()
  idle_timer:start(
    config.idle_ms,
    0,
    vim.schedule_wrap(function() set_slack_status(config.idle_status, config.idle_emoji) end)
  )
end

-- Setup autocmds
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if not config.enabled then return end

  -- Update on relevant events
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWritePost", "TextChanged", "CursorMoved", "InsertLeave" },
    { callback = function() M.update_status() end }
  )

  -- Force update in command-line modes
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    callback = function() M.update_status(true) end,
  })

  -- On exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      set_slack_status("Hopped off Neovim — now tinkering on Arch", config.fallbacks.offline or ":coffee:")
    end,
  })
end

return M
