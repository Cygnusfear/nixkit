# nixkit

Minimal CLI toolkit for a humane shell experience. Import into any Nix project to get better defaults for common CLI tools.

## What's Included

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

## Shell Setup

When you enter the shell, nixkit automatically:
- Initializes starship prompt
- Sets up zoxide for smart `cd`
- Configures fzf keybindings (Ctrl+R for history, Ctrl+T for files)
- Sets bat as your pager (including man pages)
- Aliases: `ls`→eza, `ll`→eza -la, `tree`→eza --tree, `cat`→bat

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
  # Use your own shellHook, or:
  shellHook = nixkit.lib.shellHook;
};
```

## Exports

| Output | Description |
|--------|-------------|
| `devShells.${system}.default` | Full shell with tools + initialization |
| `packages.${system}.default` | Just the CLI tools bundled together |
| `lib.shellHook` | Just the shell initialization script |

## License

MIT
