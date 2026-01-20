# autotemplate.nvim

<p align="center">
<strong>Automatic String Interpolation for Neovim using Treesitter.</strong>
</p>

Automatically converts single (') or double (") quotes into backticks (`) when you type ${ inside a string.

## Demo

Imagine typing console.log("Hello ${name}"). When you type ${, the quotes are automatically converted to backticks and the cursor is placed inside the braces.

# autotemplate.nvim

<p align="center">
<strong>Automatic String Interpolation for Neovim using Treesitter.</strong>
</p>

## Description

`autotemplate.nvim` automatically converts single (`'`) or double (`"`) quotes into backticks (`` ` ``) when you type `${` inside a string. Inspired by VS Code extensions, but built the Neovim way: Fast, native, and powered by Treesitter.

## Demo

Imagine typing `console.log("Hello ${name}")`. When you type `${`, the quotes are automatically converted to backticks and the cursor is placed inside the braces.

## Installation and Configuration

The plugin is designed to be flexible and give you full control.

### Installation with lazy.nvim

Copy and paste this block into your plugins file:

```lua
return {
  "jos3lo89/autotemplate.nvim",
  branch = "dev", -- Or "main" if you are on the stable branch
  opts = {
    -- Define exactly which languages you want to enable.
    -- Defining this table overrides the defaults completely.
    filetypes = {
      "javascript",
      "typescript",
      "javascriptreact", -- for .jsx
      "typescriptreact", -- for .tsx
      "vue",
      "svelte",
    },

    -- Filetypes to explicitly ignore, even if they are in the whitelist.
    ignored_filetypes = {
      "text",
      "markdown",
    },

    auto_close_brackets = true, -- Automatically inserts "}" and moves cursor left
    trigger_key = "{",          -- Key that triggers the check (Default: "{")
    disable_in_macro = true,    -- Disable plugin while recording macros
    debug = false,              -- Enable debug notifications
  },
}
```

### Requirements

- **Neovim 0.9+**
- **Nvim-Treesitter** installed with parsers for your target languages (e.g., `:TSInstall javascript`,, etc.)

## Commands

| Command               | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `:AutoTemplateToggle` | Enables or disables the plugin globally in real-time |
