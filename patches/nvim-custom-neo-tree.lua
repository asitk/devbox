return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Enables real-time updates from terminal actions
      use_libuv_file_watcher = true,
      -- Turning this to false allows Neo-tree to shift its root focus
      -- to track your cross-directory tabs seamlessly across the drive
      bind_to_cwd = true,
      filtered_items = {
        visible = true, -- Show hidden files but dimmed
        hide_dotfiles = false, -- Don't hide files starting with '.'
        hide_gitignored = false, -- Show files in .gitignore
      },
      follow_current_file = {
        enabled = true,
        -- Force-reveals external files cleanly in the explorer sidebar
        leave_dirs_open = false, -- Closes old directory branches behind you to keep the sidebar clean
      },
    },
  },
}
