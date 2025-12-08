# diagram.nvim

A Neovim plugin for rendering diagrams, powered by [image.nvim](https://github.com/3rd/image.nvim).
\
You'll **need to set up [image.nvim](https://github.com/3rd/image.nvim)** to use this plugin, and either [Kitty](https://github.com/kovidgoyal/kitty) or [Überzug++](https://github.com/jstkdng/ueberzugpp).

<https://github.com/user-attachments/assets/67545056-e95d-4cbe-a077-d6707349946d>

### Integrations & renderers

The plugin has a generic design with pluggable **renderers** and **integrations**.
\
Renderers take source code as input and render it to an image, often by calling an external process.
\
Integrations read buffers, extract diagram code, and dispatch work to the renderers.

| Integration | Supported renderers                          |
| ----------- | ------------------------------------------- |
| `markdown`  | `mermaid`, `plantuml`, `d2`, `gnuplot`      |
| `neorg`     | `mermaid`, `plantuml`, `d2`, `gnuplot`      |

| Renderer   | Requirements                                      |
| ---------- | ------------------------------------------------- |
| `mermaid`  | [mmdc](https://github.com/mermaid-js/mermaid-cli) |
| `plantuml` | [plantuml](https://plantuml.com/download)         |
| `d2`       | [d2](https://d2lang.com/)                         |
| `gnuplot`  | [gnuplot](http://gnuplot.info/)                   |

### Installation

With **lazy.nvim**:

```lua
{
  "3rd/diagram.nvim",
  dependencies = {
    { "3rd/image.nvim", opts = {} }, -- you'd probably want to configure image.nvim manually instead of doing this
  },
  opts = { -- you can just pass {}, defaults below
    events = {
      render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
      clear_buffer = {"BufLeave"},
    },
    renderer_options = {
      mermaid = {
        background = nil, -- nil | "transparent" | "white" | "#hex"
        theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
        scale = 1, -- nil | 1 (default) | 2  | 3 | ...
        width = nil, -- nil | 800 | 400 | ...
        height = nil, -- nil | 600 | 300 | ...
        cli_args = nil, -- nil | { "--no-sandbox" } | { "-p", "/path/to/puppeteer" } | ...
      },
      plantuml = {
        charset = nil,
        cli_args = nil, -- nil | { "-Djava.awt.headless=true" } | ...
      },
      d2 = {
        theme_id = nil,
        dark_theme_id = nil,
        scale = nil,
        layout = nil,
        sketch = nil,
        cli_args = nil, -- nil | { "--pad", "0" } | ...
      },
      gnuplot = {
        size = nil, -- nil | "800,600" | ...
        font = nil, -- nil | "Arial,12" | ...
        theme = nil, -- nil | "light" | "dark" | custom theme string
        cli_args = nil, -- nil | { "-p" } | { "-c", "config.plt" } | ...
      },
    },
    popup_options = {
      enabled = false,        -- Enable popup preview (default: false)
      auto_close = true,      -- Auto-close on cursor move (default: true)
      auto_show = false,      -- Auto-show popup when cursor moves over diagram (default: false)
      delay = 300,            -- Delay in ms before showing popup (default: 300)
      width = nil,            -- Custom width (nil = auto)
      height = nil,           -- Custom height (nil = auto)
      border = "rounded",     -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    },
  },
},
```

### Custom CLI Arguments

You can pass custom command-line arguments to any renderer using the `cli_args` option.

**Common Use Cases:**

1. **Fixing mmdc sandboxing issues (Nix/AppImage):**
   ```lua
   renderer_options = {
     mermaid = {
       cli_args = { "--no-sandbox" },
     },
   }
   ```

2. **Custom d2 padding:**
   ```lua
   renderer_options = {
     d2 = {
       cli_args = { "--pad", "0" },
     },
   }
   ```

The `cli_args` are inserted immediately after the executable name and before any standard arguments.

### Usage

To use the plugin, you need to set up the integrations and renderers in your Neovim configuration. Here's an example:

```lua
require("diagram").setup({
  integrations = {
    require("diagram.integrations.markdown"),
    require("diagram.integrations.neorg"),
  },
  renderer_options = {
    mermaid = {
      theme = "forest",
    },
    plantuml = {
      charset = "utf-8",
    },
    d2 = {
      theme_id = 1,
    },
    gnuplot = {
      theme = "dark",
      size = "800,600",
    },
  },
})
```

### API

The plugin exposes the following API functions:

- `setup(opts)`: Sets up the plugin with the given options.
- `get_cache_dir()`: Returns the root cache directory.
- `show_diagram_hover()`: Shows the diagram at cursor (popup or new tab based on configuration).
- `close_popup()`: Manually closes any open popup window.

### Diagram Hover Feature

You can add a keymap to view diagrams in a dedicated tab. Place your cursor inside any diagram code block and press the mapped key to open the rendered diagram in a new tab.

**Important**: This keymap configuration is essential for manual diagram viewing, especially when you have automatic rendering disabled.

```lua
{
  "3rd/diagram.nvim",
  dependencies = {
    "3rd/image.nvim",
  },
  opts = {
    -- Disable automatic rendering for manual-only workflow
    events = {
      render_buffer = {}, -- Empty = no automatic rendering
      clear_buffer = { "BufLeave" },
    },
    renderer_options = {
      mermaid = {
        theme = "dark",
        scale = 2,
      },
    },
  },
  keys = {
    {
      "K", -- or any key you prefer
      function()
        require("diagram").show_diagram_hover()
      end,
      mode = "n",
      ft = { "markdown", "norg" }, -- Only in these filetypes
      desc = "Show diagram in new tab",
    },
  },
},
```

**Key Configuration Details:**
- `"K"` - The key to press (can be changed to any key like `"<leader>d"`, `"gd"`, etc.)
- `ft = { "markdown", "norg" }` - Only activates in markdown and neorg files
- The function calls `require("diagram").show_diagram_hover()` to display the diagram

**Features:**
- **Cursor detection**: Works when cursor is anywhere inside diagram code blocks
- **Multiple display modes**: Supports both popup windows and new tabs
- **Multiple diagram types**: Supports mermaid, plantuml, d2, and gnuplot
- **Easy navigation**:
  - `q` or `Esc` to close the diagram
  - `o` to open the image with system viewer (Preview, etc.)
- **Async rendering**: Handles both cached and newly-rendered diagrams

### Popup Preview Feature

The plugin now supports popup window previews for diagrams, similar to image.nvim's popup feature for images. When enabled, diagrams will be displayed in a floating window at the cursor position.

#### Basic Setup

```lua
require("diagram").setup({
  popup_options = {
    enabled = true,      -- Enable popup preview
    auto_close = true,   -- Auto-close on cursor move
    auto_show = false,   -- Manual trigger with keybinding (default)
    border = "rounded",  -- Window border style
  },
})
```

#### Advanced Configuration

```lua
require("diagram").setup({
  popup_options = {
    enabled = true,        -- Enable popup preview
    auto_close = true,     -- Auto-close on cursor move
    auto_show = true,      -- Auto-show popup when cursor moves over diagram
    delay = 300,           -- Delay in ms before showing popup (prevents flickering)
    width = 60,            -- Custom width (columns)
    height = 20,           -- Custom height (lines)
    border = "rounded",    -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
  },
})
```

#### Display Mode Comparison

**Popup Mode** (recommended for quick previews):
- Shows diagram in a floating window at cursor position
- Two trigger modes:
  - **Auto-show** (recommended): Popup appears automatically when cursor moves over diagram
  - **Manual trigger**: Press `K` to trigger popup display
- Auto-closes when cursor moves away (configurable)
- Perfect for quick diagram verification

**Tab Mode** (default, for detailed viewing):
- Opens diagram in a dedicated tab
- Better for complex diagrams or长时间 viewing
- Can be used alongside popup mode

#### Key Features

- **Smart positioning**: Popup appears at cursor position with proper offset
- **Auto-sizing**: Automatically adjusts size based on actual image dimensions and terminal size
  - **Smart scaling**: Converts image pixels to terminal cells for perfect fit
  - **Aspect ratio preservation**: Maintains original diagram proportions
  - **Size limits**: Prevents popup from exceeding 80% of terminal size
- **Auto-cleanup**: Properly cleans up resources when closed
- **Multiple trigger modes**:
  - **Auto-show**: Popup appears automatically when cursor moves over diagram (with delay to prevent flickering)
  - **Manual trigger**: Press `K` to show popup on demand
- **Intelligent detection**: Only shows popup when cursor is inside diagram code blocks
- **Multiple diagrams**: Supports all diagram types (mermaid, plantuml, d2, gnuplot)
- **Flexible closing**:
  - Auto-close on cursor move (default)
  - Manual close with `q` or `Esc`
  - Programmatic close with `require("diagram").close_popup()`
