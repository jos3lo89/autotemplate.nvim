# ✨ autotemplate.nvim

<p align="center">
  <strong>Interpolación automática de Strings para Neovim usando Treesitter.</strong>
</p>

Convierta automáticamente comillas simples (`'`) o dobles (`"`) en backticks (`` ` ``) cuando escribe `${` dentro de un string. Inspirado en extensiones de VS Code, pero hecho a la manera de Neovim: **Rápido, nativo y usando Treesitter.**

## ⚡ Demo

> Imagina escribir `console.log("Hola ${name}")`. Al escribir el `${`, las comillas cambian automáticamente a backticks y el cursor se coloca dentro de las llaves.

## 📦 Instalación

Requiere **Neovim 0.9+** y tener instalado **Treesitter** para los lenguajes que uses.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "jos3lo89/autotemplate.nvim",
  config = function()
    require("autotemplate").setup({
      -- Opcional: Tu configuración aquí
    })
  end,
}
```
