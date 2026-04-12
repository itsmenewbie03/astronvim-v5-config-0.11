-- Slack Status Integration for AstroNvim
-- Requires: slack-status CLI built from your Go script
-- Place in lua/plugins/ for lazy.nvim to detect

return {
  dir = vim.fn.stdpath "config" .. "/lua/custom/slack-status/",
  event = "VeryLazy",
  config = function()
    require("custom.slack-status").setup {
      enabled = false,
      binary_path = "slack-status", -- must be in $PATH
      default_status = "Working in Neovim",
      default_emoji = ":neovim:",
      idle_status = "Reading docs or off on a side quest",
      idle_emoji = ":compass:", -- exploration feel
      debounce_ms = 5000,
      idle_ms = 3 * 60000,
      mappings = {
        -- Filetype-specific emoji mapping
        lua = ":lua_lang:",
        helm = ":helm:",
        go = ":golang:",
        c = ":c:",
        rust = ":rust:",
        javascript = ":javascript:",
        typescript = ":blue_heart:",
        svelte = ":svelte:",
        markdown = ":memo:",
        python = ":snake:",
        sh = ":shell:",
        json = ":page_facing_up:",
        gitignore = ":git:",
        gitcommit = ":git:",
        dockerfile = ":docker:",
        html = ":globe_with_meridians:",
        zig = ":zig:",
        css = ":art:",
        toggleterm = ":terminal:",
        terraform = ":terraform:",
        -- Add more filetypes as you wish
      },
      fallbacks = {
        editing = ":writing_hand:",
        prompt = ":mag:", -- Telescope, cmdline, etc.
        explorer = ":file_folder:", -- neo-tree, netrw
        offline = ":arch_linux:",
        terminal = ":terminal:",
      },
    }
  end,
}
