{
  description = "Minimal CLI toolkit for a humane shell experience";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Minimal CLI tools for a humane shell experience
        cliTools = with pkgs; [
          ripgrep   # better grep
          fd        # better find
          fzf       # fuzzy finder
          bat       # better cat
          eza       # better ls
          zoxide    # better cd
          starship  # prompt
          jq        # JSON processing
        ];

        # Shell initialization for CLI tools
        cliShellHook = ''
          # Initialize starship prompt
          eval "$(starship init bash 2>/dev/null || starship init zsh 2>/dev/null || true)"

          # Initialize zoxide
          eval "$(zoxide init bash 2>/dev/null || zoxide init zsh 2>/dev/null || true)"

          # fzf keybindings (if in interactive shell)
          if [[ $- == *i* ]]; then
            eval "$(fzf --bash 2>/dev/null || fzf --zsh 2>/dev/null || true)"
          fi

          # Use bat as pager
          export PAGER="bat --plain"
          export MANPAGER="sh -c 'col -bx | bat -l man -p'"

          # Aliases
          alias ls="eza"
          alias ll="eza -la"
          alias tree="eza --tree"
          alias cat="bat --plain"
        '';
      in
      {
        # Ready-to-use dev shell
        devShells.default = pkgs.mkShell {
          buildInputs = cliTools;
          shellHook = cliShellHook;
        };

        # Just the packages (for cherry-picking)
        packages.default = pkgs.symlinkJoin {
          name = "nixkit";
          paths = cliTools;
        };
      }
    ) // {
      # Export shellHook for custom use
      lib.shellHook = ''
        # Initialize starship prompt
        eval "$(starship init bash 2>/dev/null || starship init zsh 2>/dev/null || true)"

        # Initialize zoxide
        eval "$(zoxide init bash 2>/dev/null || zoxide init zsh 2>/dev/null || true)"

        # fzf keybindings (if in interactive shell)
        if [[ $- == *i* ]]; then
          eval "$(fzf --bash 2>/dev/null || fzf --zsh 2>/dev/null || true)"
        fi

        # Use bat as pager
        export PAGER="bat --plain"
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"

        # Aliases
        alias ls="eza"
        alias ll="eza -la"
        alias tree="eza --tree"
        alias cat="bat --plain"
      '';
    };
}
