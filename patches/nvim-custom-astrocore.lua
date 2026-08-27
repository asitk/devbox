-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },          -- set global limits for large files for disabling features like treesitter
      autopairs = true,                                          -- enable autopairs at start
      cmp = true,                                                -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true,                                       -- highlight URLs at start
      notifications = true,                                      -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        -- relativenumber = true,         -- sets vim.opt.relativenumber
        -- number = true,                 -- sets vim.opt.number
        -- spell = false,                 -- sets vim.opt.spell
        -- signcolumn = "yes",            -- sets vim.opt.signcolumn to yes
        -- wrap = false,                  -- sets vim.opt.wrap
        backup = true,                                         -- Enable backup
        writebackup = true,                                    -- Enable writebackup
        backupdir = vim.fn.expand("~/.local/state/nvim/backup//"), -- Specify backup directory
        backupext = ".bak",                                    -- Set custom extension

        -- Basic settings
        number = true,
        relativenumber = true,
        cursorline = true,
        wrap = false,
        scrolloff = 10,
        sidescrolloff = 8,

        -- Indentation
        tabstop = 2,
        shiftwidth = 2,
        softtabstop = 2,
        expandtab = true,
        smartindent = true,
        autoindent = true,

        -- Search settings
        ignorecase = true,
        smartcase = true,
        hlsearch = false,
        incsearch = true,

        -- Visual settings
        termguicolors = true,
        signcolumn = "yes",
        colorcolumn = "80",
        showmatch = true,
        matchtime = 2,
        cmdheight = 1,
        completeopt = "menuone,noinsert,noselect",
        showmode = false,
        pumheight = 10,
        pumblend = 10,
        winblend = 0,
        conceallevel = 0,
        concealcursor = "",
        lazyredraw = true,
        synmaxcol = 300,

        -- File handling
        swapfile = false,
        undofile = true,
        undodir = vim.fn.expand("~/.vim/undodir"),
        updatetime = 300,
        timeoutlen = 500,
        ttimeoutlen = 0,
        autoread = true,
        autowrite = false,

        -- Behavior settings
        hidden = true,
        errorbells = false,
        backspace = "indent,eol,start",
        autochdir = false,
        iskeyword = vim.opt.iskeyword + "-", -- Appends "-"
        path = vim.opt.path + "**",      -- Appends subdirectories
        selection = "exclusive",
        mouse = "a",
        clipboard = "unnamedplus", -- AstroNvim handles append logic
        modifiable = true,
        encoding = "UTF-8",

        -- Cursor settings
        guicursor =
        "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175",

        -- Folding settings
        foldmethod = "expr",
        foldexpr = "nvim_treesitter#foldexpr()",
        foldlevel = 99,

        -- Split behavior
        splitbelow = true,
        splitright = true,
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    -- Useful routines
    autocmds = {
      -- Highlight yanked text
      highlight_yank = {
        {
          event = "TextYankPost",
          desc = "Highlight yanked text",
          callback = function()
            vim.highlight.on_yank()
          end,
        },
      },

      -- Return to last edit position
      last_loc = {
        {
          event = "BufReadPost",
          desc = "Return to last edit position when opening files",
          callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if
                mark[1] > 0
                and mark[1] <= lcount
                and vim.fn.index({ "commit", "gitrebase", "xxd" }, vim.bo.filetype) == -1
                and not vim.o.diff
            then
              pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
          end,
        },
      },

      -- Filetype-specific indentation
      ft_indentation = {
        {
          event = "FileType",
          pattern = { "lua", "python" },
          callback = function()
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
          end,
        },
        {
          event = "FileType",
          pattern = { "javascript", "typescript", "json", "html", "css" },
          callback = function()
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
          end,
        },
      },

      auto_open_neotree = {
        {
          event = "VimEnter",
          desc = "Open Neo-tree on startup",
          callback = function()
            -- Only open if Neovim was launched without specific files
            if vim.fn.argc() == 0 then
              vim.cmd("Neotree show")
            end
          end,
        },
      },

      backup_rotation = {
        {
          event = "BufWritePre",
          desc = "Add timestamp to backup and prune old copies",
          callback = function()
            -- 1. Set the new timestamped extension
            vim.opt.backupext = "." .. os.date("%Y%m%d_%H%M%S")

            -- 2. Cleanup Logic
            local max_backups = 2

            -- Use vim.o instead of vim.opt to get a clean string
            local raw_dir = vim.o.backupdir
            if not raw_dir or raw_dir == "" then
              return
            end

            -- Strip the trailing // if it exists for the glob search
            local bdir = vim.fn.expand(raw_dir:gsub("//$", ""))

            -- Encode current file path as Neovim does (slash -> %)
            local full_path = vim.fn.expand("%:p")
            local encoded_name = full_path:gsub("/", "%%")

            -- Find all existing backups for this specific encoded path
            local pattern = bdir .. "/" .. encoded_name .. "*"
            local backups = vim.fn.glob(pattern, false, true)

            table.sort(backups)

            -- Delete if we exceed the limit
            if #backups > max_backups then
              local num_to_delete = #backups - max_backups
              for i = 1, num_to_delete do
                vim.fn.delete(backups[i])
              end
            end
          end,
        },
      },
    },

    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- Normal mode mappings
      n = {
        -- Tab Management
        ["<leader>v"] = { name = "Tabs/Views" },

        -- Core Navigation
        ["<leader>vn"] = { ":tabnew<CR>", desc = "New tab" },
        ["<leader>vc"] = { ":tabclose<CR>", desc = "Close tab" },

        -- Tab moving
        ["<leader>vm"] = { ":tabmove<CR>", desc = "Move tab" },
        ["<leader>v>"] = { ":tabmove +1<CR>", desc = "Move tab right" },
        ["<leader>v<"] = { ":tabmove -1<CR>", desc = "Move tab left" },

        -- Direct Number Jump (1-5)
        ["<leader>v1"] = { "1gt", desc = "View Tab 1" },
        ["<leader>v2"] = { "2gt", desc = "View Tab 2" },
        ["<leader>v3"] = { "3gt", desc = "View Tab 3" },
        ["<leader>v4"] = { "4gt", desc = "View Tab 4" },
        ["<leader>v5"] = { "5gt", desc = "View Tab 5" },

        -- Enhanced Functions with your specific indentation
        ["<leader>vd"] = {
          function()
            local current_file = vim.fn.expand("%:p")
            if current_file ~= "" then
              vim.cmd("tabnew " .. current_file)
            else
              vim.cmd("tabnew")
            end
          end,
          desc = "Duplicate current tab",
        },

        ["<leader>vr"] = {
          function()
            local current_tab = vim.fn.tabpagenr()
            local last_tab = vim.fn.tabpagenr("$")

            for i = last_tab, current_tab + 1, -1 do
              vim.cmd(i .. "tabclose")
            end
          end,
          desc = "Close tabs to the right",
        },

        ["<leader>vl"] = {
          function()
            local current_tab = vim.fn.tabpagenr()

            for i = current_tab - 1, 1, -1 do
              vim.cmd("1tabclose")
            end
          end,
          desc = "Close tabs to the left",
        },

        ["<leader>vo"] = {
          function()
            vim.ui.input({ prompt = "File to open in new tab: ", completion = "file" }, function(input)
              if input and input ~= "" then
                vim.cmd("tabnew " .. input)
              end
            end)
          end,
          desc = "Open file in new tab",
        },

        -- Yank to EOL (consistent with D and C behavior)
        ["Y"] = { "y$", desc = "Yank to end of line" },
        -- Center screen when jumping through search results
        ["n"] = { "nzzzv", desc = "Next search result (centered)" },
        ["N"] = { "Nzzzv", desc = "Previous search result (centered)" },
        -- Center screen when scrolling half-pages
        ["<C-d>"] = { "<C-d>zz", desc = "Half page down (centered)" },
        ["<C-u>"] = { "<C-u>zz", desc = "Half page up (centered)" },
        -- Delete without yanking
        ["<Leader>d"] = { '"_d', desc = "Delete without yanking" },
        -- Buffer navigation
        ["<Leader>bn"] = { ":bnext<CR>", desc = "Next buffer" },
        ["<Leader>bp"] = { ":bprevious<CR>", desc = "Previous buffer" },
        -- Window navigation
        ["<C-h>"] = { "<C-w>h", desc = "Move to left window" },
        ["<C-j>"] = { "<C-w>j", desc = "Move to bottom window" },
        ["<C-k>"] = { "<C-w>k", desc = "Move to top window" },
        ["<C-l>"] = { "<C-w>l", desc = "Move to right window" },
        -- Splitting & Resizing
        ["<Leader>sv"] = { ":vsplit<CR>", desc = "Split window vertically" },
        ["<Leader>sh"] = { ":split<CR>", desc = "Split window horizontally" },
        ["<C-Up>"] = { ":resize +2<CR>", desc = "Increase window height" },
        ["<C-Down>"] = { ":resize -2<CR>", desc = "Decrease window height" },
        ["<C-Left>"] = { ":vertical resize -2<CR>", desc = "Decrease window width" },
        ["<C-Right>"] = { ":vertical resize +2<CR>", desc = "Increase window width" },
        -- Quick config editing: Point directly to astrocore.lua
        ["<Leader>rc"] = {
          function()
            vim.cmd("e " .. vim.fn.stdpath("config") .. "/lua/plugins/astrocore.lua")
          end,
          desc = "Edit AstroCore config",
        },
        -- Reloading (Note: AstroNvim handles most reloads automatically on save)
        ["<Leader>rl"] = { ":so $MYVIMRC<CR>", desc = "Reload init.lua" },
        -- Better J behavior
        ["J"] = { "mzJ`z", desc = "Join lines and keep cursor position" },
        -- Move current line up/down
        ["<A-j>"] = { ":m .+1<CR>==", desc = "Move line down" },
        ["<A-k>"] = { ":m .-2<CR>==", desc = "Move line up" },
        -- navigate buffer tabs
        ["]b"] = {
          function()
            require("astrocore.buffer").nav(vim.v.count1)
          end,
          desc = "Next buffer",
        },
        ["[b"] = {
          function()
            require("astrocore.buffer").nav(-vim.v.count1)
          end,
          desc = "Previous buffer",
        },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(function(bufnr)
              require("astrocore.buffer").close(bufnr)
            end)
          end,
          desc = "Close buffer from tabline",
        },

        -- Copy Full File-Path
        ["<Leader>P"] = {
          function()
            local path = vim.fn.expand("%:p")
            vim.fn.setreg("+", path)
            -- Using AstroNvim's notify system for a cleaner look
            if package.loaded["notify"] then
              require("notify")("Copied path: " .. path, "info", { title = "Clipboard" })
            else
              print("Copied path: " .. path)
            end
          end,
          desc = "Copy full file path",
        },
      },

      -- Visual mode mappings
      v = {
        -- Delete without yanking
        ["<Leader>d"] = { '"_d', desc = "Delete without yanking" },

        -- Move selection up/down
        ["<A-j>"] = { ":m '>+1<CR>gv=gv", desc = "Move selection down" },
        ["<A-k>"] = { ":m '<-2<CR>gv=gv", desc = "Move selection up" },

        -- Better indenting in visual mode
        ["<"] = { "<gv", desc = "Indent left and reselect" },
        [">"] = { ">gv", desc = "Indent right and reselect" },
      },
    },
  },
}
