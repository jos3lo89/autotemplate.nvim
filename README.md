# 🚀 autotemplate.nvim

<div align="center">

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)

**Automatic template string conversion for Neovim using Treesitter**

[Features](#-features) • [Installation](#-installation) • [Configuration](#%EF%B8%8F-configuration) • [Commands](#-commands)

</div>

---

## ✨ Features

- 🎯 **Automatic Conversion**: Type `${` inside a string and watch quotes convert to backticks
- ⚡ **Lightning Fast**: Powered by Treesitter for accurate parsing
- 🎨 **Multi-Language**: Supports JavaScript, TypeScript, React, Vue, Svelte
- 🔧 **Highly Configurable**: Customize filetypes, behavior, and more
- 📦 **Zero Dependencies**: Only requires nvim-treesitter

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "jos3lo89/autotemplate.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = "InsertEnter",
  opts = {
    -- Your config here
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "jos3lo89/autotemplate.nvim",
  requires = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("autotemplate").setup()
  end
}
```

## ⚙️ Configuration

Default configuration:

```lua
require("autotemplate").setup({
  -- Languages to enable
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "svelte",
  },

  -- Languages to explicitly ignore
  ignored_filetypes = {
    "markdown",
    "text",
  },

  -- Disable during macro recording
  disable_in_macro = true,

  -- Enable debug messages
  debug = false,
})
```

## 🎮 Commands

| Command                     | Description          |
| --------------------------- | -------------------- |
| `:AutoTemplateToggle`       | Toggle plugin on/off |
| `:AutoTemplateEnable`       | Enable plugin        |
| `:AutoTemplateDisable`      | Disable plugin       |
| `:checkhealth autotemplate` | Check plugin health  |

<!-- ## 🎬 Demo

https://github.com/yourusername/autotemplate.nvim/assets/demo.gif -->

## 🔍 How It Works

1. You type `console.log("Hello ${name}")`
2. When you
3. type the `{` after `$`, the plugin:

- Detects you're inside a string
- Converts `"` to `` ` ``
- Places cursor inside `{}`

3.  Result: ``console.log(`Hello ${name}`)``

---

<div align="center">
Made with ❤️ for the Neovim community
</div>
