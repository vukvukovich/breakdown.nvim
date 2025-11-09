# breakdown.nvim

Turn debugging into a spectator sport. One command and your code yeets itself across Neovim like it rage-quit before you could. This plugin doesn't fix your stress... it commits to the bit and falls apart with you... in buttery-smooth 60 FPS.

## Features

- **Realistic physics simulation** - Characters fall with gravity, mass variation, and collision detection
- **Syntax highlighting preservation** - Colors stay intact during the breakdown
- **Restore on keypress** - Press any key to restore your buffer
- **Desk slam detection** - Triggers on table impact via accelerometer (Intel Macs only)
- **Highly configurable** - Customize gravity, speed, and physics parameters
- **Performance optimized** - Smooth 60 FPS animation

## Demo

[Add GIF/video here]

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/breakdown.nvim",
  config = function()
    require("breakdown").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/breakdown.nvim",
  config = function()
    require("breakdown").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'yourusername/breakdown.nvim'
```

Then in your `init.lua`:
```lua
require("breakdown").setup()
```

## Usage

Trigger the breakdown animation with:

```vim
:Breakdown
```

Or call it from Lua:

```lua
require("breakdown").breakdown()
```

After the animation completes, **press any key** to restore your buffer.

### Keyboard Mapping (Recommended)

Map to your favorite rage-quit key:

```lua
vim.keymap.set("n", "<leader>br", "<cmd>Breakdown<cr>", { desc = "Breakdown animation" })
```

### Accelerometer Mode (Not Yet Working)

**Research Status:** We discovered that Apple Silicon Macs (M1/M2/M3) DO have accelerometer hardware accessible via IOKit:
- Device: "Apple Internal Keyboard / Trackpad"
- HID UsagePage: 0xFF00 (vendor-defined)
- HID Usage: 0x03
- Can be opened with IOHIDDeviceOpen

**Current Limitation:** While the device can be found and opened, it doesn't send data without special entitlements that command-line tools can't obtain. Possible solutions for future:
- Signed app bundle with proper entitlements
- Private framework access (non-portable)
- Different sensor access method

**For Now:** Use keyboard mapping instead:

```lua
vim.keymap.set("n", "<leader>br", "<cmd>Breakdown<cr>", { desc = "Breakdown" })
```

The Swift accelerometer reader code is in `bin/accel_reader.swift` for reference. Contributions welcome if you find a way to get data from the sensor!

## Configuration

### Default Configuration

```lua
require("breakdown").setup({
  fps = 60,
  gravity = 50.0,
  mass_min = 0.7,
  mass_max = 1.7,
  drift_max = 1.5,
  initial_velocity_max = 2.0,
  air_resistance = 0.98,
  collision_padding = 0.3,
  collision_distance = 1.5,

  -- Accelerometer (macOS only)
  enable_accelerometer = false,
  impact_threshold = 100,
  poll_interval = 50,
})
```

### Example Configurations

**Slower, more dramatic breakdown:**
```lua
require("breakdown").setup({
  gravity = 20.0,
  mass_min = 0.5,
  mass_max = 1.0,
  drift_max = 3.0,
})
```

**Fast rage quit:**
```lua
require("breakdown").setup({
  gravity = 100.0,
  mass_min = 1.5,
  mass_max = 2.5,
  drift_max = 0.5,
})
```

**Keyboard trigger (Recommended):**
```lua
-- Map to your preferred key
vim.keymap.set("n", "<C-q>", "<cmd>Breakdown<cr>")
```

## How It Works

1. **Capture** - Grabs all visible characters with their syntax highlighting
2. **Simulate** - Applies realistic physics (gravity, mass, collision, air resistance)
3. **Render** - Displays particles as virtual text overlays at 60 FPS
4. **Restore** - Waits for keypress, then restores original buffer

The plugin uses Neovim's extmark system for rendering and `vim.inspect_pos()` for accurate syntax highlighting capture, ensuring compatibility with all colorschemes and syntax systems (treesitter, LSP semantic tokens, traditional syntax).

## Requirements

- Neovim >= 0.9.0

## Credits

Inspired by frustration and the universal developer experience of wanting to flip a table.

## License

MIT License - see LICENSE file for details
