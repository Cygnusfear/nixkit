# nixkit

Minimal CLI toolkit for a humane shell experience. Import into any Nix project to get better defaults for common CLI tools.

## What's Included

### Tools

| Tool | Replaces | Description |
|------|----------|-------------|
| [ripgrep](https://github.com/BurntSushi/ripgrep) | grep | Fast regex search |
| [fd](https://github.com/sharkdp/fd) | find | Fast file finder |
| [fzf](https://github.com/junegunn/fzf) | - | Fuzzy finder |
| [bat](https://github.com/sharkdp/bat) | cat | Syntax highlighting |
| [eza](https://github.com/eza-community/eza) | ls | Modern ls |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | cd | Smart directory jumping |
| [starship](https://starship.rs) | PS1 | Cross-shell prompt |
| [jq](https://jqlang.github.io/jq/) | - | JSON processor |

### Shell Setup

When you enter the shell, nixkit automatically configures:

**Environment:**
- Starship prompt with clean config (noisy cloud modules disabled)
- bat as pager (including for man pages)
- fzf with fd for file finding
- UTF-8 locale

**Zsh options:**
- Smart history (dedup, shared, verify before execute)
- Auto-cd and directory stack
- Case-insensitive completion
- ALT+arrow word navigation

**Aliases:**
- `ls`, `ll`, `la`, `tree` → eza
- `cat` → bat
- `preview` → fzf with bat preview
- `add`, `push`, `pull`, `fetch` → git shortcuts

**Functions:**
- `man` → Enhanced man pages with bat
- `run` → Smart package runner (detects yarn/npm/pnpm/bun)
- `cleandev` → Kill dev servers on common ports
- `commit` → Git commit with type prefix (`commit fix "message"`)
- `gits` → Interactive git status with fzf

## Usage

### Use Directly

```bash
nix develop github:Cygnusfear/nixkit
```

### Import in Your Project

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixkit.url = "github:Cygnusfear/nixkit";
  };

  outputs = { self, nixpkgs, nixkit, ... }:
    let
      system = "aarch64-darwin"; # or x86_64-linux, etc.
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        # Inherit all CLI tools and shell setup
        inputsFrom = [ nixkit.devShells.${system}.default ];

        # Add your project-specific tools
        buildInputs = [ pkgs.nodejs_22 pkgs.pnpm ];
      };
    };
}
```

### Cherry-Pick Packages Only

```nix
devShells.default = pkgs.mkShell {
  buildInputs = [
    nixkit.packages.${system}.default  # just the CLI tools
    pkgs.nodejs_22
  ];
  # Optionally add the shell setup:
  shellHook = nixkit.lib.shellHook;
};
```

## Exports

| Output | Description |
|--------|-------------|
| `devShells.${system}.default` | Full shell with tools + config |
| `packages.${system}.default` | Just the CLI tools bundled |
| `packages.${system}.starshipConfig` | Path to starship.toml in nix store |
| `lib.shellHook` | Shell initialization script |

## License

MIT
