Aquí tienes el archivo `README.md` completo y listo para copiar.

Incluye la sección de **Instalación y Configuración** con el bloque de código exacto que pediste (con listas blanca/negra explícitas) para que cualquier usuario solo tenga que copiar, pegar y tener el control total.

````markdown
# ✨ autotemplate.nvim

<p align="center">
  <strong>Interpolación automática de Strings para Neovim usando Treesitter.</strong>
</p>

Convierte automáticamente comillas simples (`'`) o dobles (`"`) en backticks (`` ` ``) cuando escribes `${` dentro de un string.

Inspirado en extensiones de VS Code, pero hecho a la manera de Neovim: **Rápido, nativo y usando Treesitter.**

## ⚡ Demo

> Imagina escribir `console.log("Hola ${name}")`. Al escribir el `${`, las comillas cambian automáticamente a backticks y el cursor se coloca dentro de las llaves.

## 📦 Instalación y Configuración

El plugin está diseñado para ser flexible y darte el control total.

A continuación, la configuración recomendada para **[lazy.nvim](https://github.com/folke/lazy.nvim)**. Copia y pega este bloque en tu archivo de plugins:

```lua
{
  "jos3lo89/autotemplate.nvim",
  opts = {
    -- 1. LISTA BLANCA (Whitelist)
    -- Define exactamente en qué lenguajes quieres que funcione.
    -- Al definir esta tabla, tienes el control total y sobrescribes los valores por defecto.
    filetypes = {
      "javascript",
      "typescript",
      "javascriptreact", -- Para .jsx
      "typescriptreact", -- Para .tsx
      "vue",
      "svelte",
      "python",          -- Opcional: Para f-strings
    },

    -- 2. LISTA NEGRA (Blacklist)
    -- Archivos donde NUNCA se activará, aunque estén en la lista blanca.
    -- Útil si algún tipo de archivo específico te da problemas.
    ignored_filetypes = {
      "text",
      "markdown",
    },

    -- 3. OTRAS OPCIONES
    disable_in_macro = true, -- Desactiva el plugin mientras grabas macros (q) para evitar errores
    debug = false,           -- Actívalo solo si necesitas depurar (muestra notificaciones)
  },
}
```
````

### Requisitos

- **Neovim 0.9+**
- **Nvim-Treesitter** instalado y con los parsers de tus lenguajes (`:TSInstall javascript`, `:TSInstall python`, etc.)

## 🚀 Comandos

- `:AutoTemplateToggle` - Activa o desactiva el plugin globalmente en tiempo real.

## 🧠 ¿Cómo funciona?

1. **El "Portero" (Init):** Verifica si tu archivo está en la lista blanca y **no** en la negra. Si pasa, activa el atajo de teclado `{`.
2. **El "Motor" (Core):** Cuando presionas `{` después de un `$`, usa Treesitter para detectar si estás _realmente_ dentro de un string (ignorando comentarios, etc.). Si es así, cambia las comillas por ti.

## 📄 Licencia

[MIT](https://www.google.com/search?q=./LICENSE)

```

```
