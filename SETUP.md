# Setup & dependencies

This config is based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). For layout and plugin philosophy, see [README.md](README.md). This document lists **external tools** you need on the machine and **OS-specific install** steps.

**Target Neovim:** 0.11 or newer (`:checkhealth kickstart` will complain if older).

---

## Required

| Tool | Why |
| :--- | :--- |
| **Neovim** 0.11+ | Editor |
| **git** | Bootstraps `lazy.nvim`; `gitsigns.nvim`; `lua/custom/smart_cd.lua` uses `git rev-parse` |
| **make** | Builds `telescope-fzf-native`; optional LuaSnip `jsregexp` step |
| **C compiler** (`gcc` or `clang`) | Native extension build for Telescope fzf; Treesitter parser compiles |
| **unzip** | Used by some plugin/tool installs |
| **ripgrep** (`rg`) | Telescope grep pickers (`<leader>sg`, etc.) |
| **fd** | `<leader>bc`, `<leader>br`, `<leader>bt` use `fd` to find `.csproj` / `.sln` (see [lua/custom/keymaps.lua](lua/custom/keymaps.lua)) |

## Strongly recommended

| Tool | Why |
| :--- | :--- |
| **Nerd Font** | `vim.g.have_nerd_font = true` — icons in Telescope, Neo-tree, statusline. Config references *JetBrains Mono Nerd Font Mono* in `init.lua`; set the same font in your terminal (or set `have_nerd_font` to `false`). |
| **.NET SDK** (`dotnet`) | Build/run/test keymaps and C# workflow |
| **jq** | `<leader>fj` formats JSON with `:%!jq .` |

## Clipboard (Linux only)

`init.lua` sets `clipboard = unnamedplus`. Install a provider so Neovim can talk to the system clipboard:

- **X11:** `xclip` or `xsel` (e.g. Debian/Ubuntu: `sudo apt install xclip`)
- **Wayland:** `wl-clipboard` (e.g. `sudo apt install wl-clipboard`)

macOS uses the built-in clipboard; no extra package.

## Managed inside Neovim

After first start, **Lazy** installs plugins; **Mason** (`:Mason`) can install LSP/formatters/DAP (e.g. `lua_ls`, `stylua`, **OmniSharp**, **netcoredbg** for C# debugging per [lua/kickstart/plugins/debug.lua](lua/kickstart/plugins/debug.lua)).

---

## macOS

1. Install [Homebrew](https://brew.sh) if needed.
2. Install dependencies (adjust if you use another Neovim install method):

   ```bash
   brew install neovim git make ripgrep fd unzip
   xcode-select --install   # Command Line Tools → provides clang/make if missing
   ```

3. Optional: `brew install dotnet-sdk jq`
4. Optional (C# debug): install **netcoredbg** via `:Mason` in Neovim, or `brew install netcoredbg`
5. Install a [Nerd Font](https://www.nerdfonts.com/font-downloads) and select it in your terminal (e.g. Kitty, WezTerm, Ghostty, iTerm2).
6. Clone or copy this config to `~/.config/nvim`, then run `nvim` and wait for `:Lazy` to finish syncing.

---

## Linux

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y git make gcc ripgrep unzip curl \
  xclip neovim
```

**fd:** the distro package is often **`fd-find`**, and the binary is **`fdfind`**. This config calls **`fd`**, so either:

```bash
sudo apt install -y fd-find
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
```

…or install a `fd` package that provides the `fd` name (e.g. from [sharkdp/fd releases](https://github.com/sharkdp/fd/releases)).

Optional:

```bash
sudo apt install -y jq wl-clipboard   # or xclip for X11
```

Install the **.NET SDK** via [Microsoft’s Linux instructions](https://learn.microsoft.com/dotnet/core/install/linux) (distro packages vary by release).

### Fedora

```bash
sudo dnf install -y git make gcc ripgrep fd-find unzip neovim wl-clipboard
# If the binary is fdfind, symlink fd as above, or install fd from COPR / GitHub if you prefer.
```

### Arch Linux

```bash
sudo pacman -S --needed git make gcc ripgrep fd unzip neovim wl-clipboard
```

(`fd` on Arch provides the `fd` command directly.)

---

## First launch & checks

1. Run `nvim`.
2. Wait for **lazy.nvim** to install plugins (or run `:Lazy`).
3. Run `:checkhealth` and fix any **ERROR** rows you care about.
4. Run `:Mason` and ensure tools you use (e.g. **omnisharp**, **stylua**, **netcoredbg**) are installed.

---

## Troubleshooting

| Issue | What to check |
| :--- | :--- |
| Telescope fzf errors | `make` + compiler installed; rebuild with `:Lazy build` |
| `<leader>bc` / `br` / `bt` errors | `fd` on `PATH` (on Ubuntu, `fdfind` → `fd` symlink) |
| No clipboard on Linux | `xclip`, `xsel`, or `wl-clipboard` |
| C# LSP missing | `:Mason` → install **omnisharp**; .NET SDK on `PATH` for project loading |

For upstream install variants (AppImage, nightly, etc.), see the **Installation** section in [README.md](README.md).
