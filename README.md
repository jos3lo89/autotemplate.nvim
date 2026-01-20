# ✨ autotemplate.nvim

<p align="center">
  <strong>Automatic String Interpolation for Neovim using Treesitter.</strong>
</p>

Automatically converts single (`'`) or double (`"`) quotes into backticks (`` ` ``) when you type `${` inside a string.

## ⚡ Demo

> Imagine typing `console.log("Hello ${name}")`. When you type `${`, the quotes are automatically converted to backticks and the cursor is placed inside the braces.

## 📦 Installation and Configuration

The plugin is designed to be flexible and give you full control.

Below is the recommended configuration for **[lazy.nvim](https://github.com/folke/lazy.nvim)**. Copy and paste this block into your plugins file:

```lua
return {
  "jos3lo89/autotemplate.nvim",
  -- Default configuration
  opts = {
    filetypes = {
      "javascript",
      "typescript",
      "javascriptreact",
      "typescriptreact",
      "vue",
      "svelte",
    },
    ignored_filetypes = {
      "text",
      "markdown",
    },
  },
}


```

### Requirements

- **Neovim 0.9+**
- **Nvim-Treesitter** installed with the parsers for your languages (`:TSInstall javascript`, etc.)

## 🚀 Commands

- `:AutoTemplateToggle` - Enables or disables the plugin globally.
