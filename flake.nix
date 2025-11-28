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

        # Starship config
        starshipConfig = pkgs.writeText "starship.toml" ''
          "$schema" = 'https://starship.rs/config-schema.json'
          add_newline = true

          [aws]
          disabled = true

          [gcloud]
          disabled = true

          [azure]
          disabled = true
        '';

        # Shell initialization for CLI tools
        cliShellHook = ''
          # ============================================
          # Environment
          # ============================================
          export STARSHIP_CONFIG="${starshipConfig}"
          export PAGER="bat --plain"
          export MANPAGER="sh -c 'col -bx | bat -l man -p'"
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
          export LANG=en_US.UTF-8
          export LC_ALL=en_US.UTF-8

          # ============================================
          # Shell options (zsh)
          # ============================================
          if [[ -n "$ZSH_VERSION" ]]; then
            # History
            setopt HIST_IGNORE_ALL_DUPS
            setopt SHARE_HISTORY
            setopt HIST_REDUCE_BLANKS
            setopt HIST_VERIFY

            # Directory navigation
            setopt AUTO_CD
            setopt AUTO_PUSHD
            setopt PUSHD_IGNORE_DUPS

            # Completion
            setopt COMPLETE_IN_WORD
            setopt MENU_COMPLETE
            setopt NO_CASE_GLOB

            # Misc
            setopt NO_BEEP
            setopt INTERACTIVE_COMMENTS

            # Case insensitive completion
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

            # Keybindings - word navigation with ALT-arrow
            bindkey "^[[1;3D" backward-word  # ALT-left
            bindkey "^[[1;3C" forward-word   # ALT-right
          fi

          # ============================================
          # Tool initialization
          # ============================================
          # Initialize starship prompt
          if [[ -n "$ZSH_VERSION" ]]; then
            eval "$(starship init zsh)"
          elif [[ -n "$BASH_VERSION" ]]; then
            eval "$(starship init bash)"
          fi

          # Initialize zoxide
          if [[ -n "$ZSH_VERSION" ]]; then
            eval "$(zoxide init zsh)"
          elif [[ -n "$BASH_VERSION" ]]; then
            eval "$(zoxide init bash)"
          fi

          # fzf keybindings (--zsh/--bash requires fzf 0.48+)
          if [[ -n "$ZSH_VERSION" ]]; then
            if fzf --zsh &>/dev/null; then
              eval "$(fzf --zsh)"
            elif [[ -f "''${FZF_BASE:-/usr/share/fzf}/key-bindings.zsh" ]]; then
              source "''${FZF_BASE:-/usr/share/fzf}/key-bindings.zsh"
            fi
          elif [[ -n "$BASH_VERSION" ]]; then
            if fzf --bash &>/dev/null; then
              eval "$(fzf --bash)"
            elif [[ -f "''${FZF_BASE:-/usr/share/fzf}/key-bindings.bash" ]]; then
              source "''${FZF_BASE:-/usr/share/fzf}/key-bindings.bash"
            fi
          fi

          # ============================================
          # Aliases
          # ============================================
          alias ls="eza"
          alias ll="eza -la"
          alias la="eza -lah --git"
          alias tree="eza --tree"
          alias cat="bat --plain"

          # fzf preview
          alias preview='fzf --preview="bat --color=always {}"'

          # Git shortcuts
          alias add="git add"
          alias push="git push"
          alias pull="git pull"
          alias fetch="git fetch"

          # ============================================
          # Functions
          # ============================================

          # Enhanced man pages with bat
          man() {
            command man "$@" | bat -l man -p
          }

          # Smart package manager runner (detects yarn/npm/pnpm/bun)
          run() {
            if [[ -e bun.lockb ]]; then
              bun run "$@"
            elif [[ -e yarn.lock ]]; then
              yarn run "$@"
            elif [[ -e pnpm-lock.yaml ]]; then
              pnpm run "$@"
            elif [[ -e package-lock.json ]]; then
              npm run "$@"
            else
              echo "No lockfile found, using npm"
              npm run "$@"
            fi
          }

          # Clean up dev servers on common ports
          cleandev() {
            echo "Cleaning up dev servers..."
            for port in 3000 3001 4000 5173 5174 8080 8081 4200 9000; do
              lsof -ti :$port 2>/dev/null | xargs -r kill -9 2>/dev/null
            done
            pkill -f "node.*dev|vite|webpack|next-server" 2>/dev/null || true
            echo "Done"
          }

          # Git: smart commit with type prefix
          commit() {
            case $# in
              1) git commit -m "$1" ;;
              2) git commit -m "$1: $2" ;;
              3) git commit -m "$1: $2" -m "$3" ;;
              *) echo "Usage: commit [type] [subject] [body]"; return 1 ;;
            esac
          }

          # Interactive git status with fzf
          gits() {
            git status -s | fzf --multi --preview 'git diff --color {2}'
          }
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

        # Export starship config path
        packages.starshipConfig = starshipConfig;
      }
    ) // {
      # Export shellHook for custom use (without starship config path - users must set their own)
      lib.shellHook = ''
        export PAGER="bat --plain"
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

        # Shell options (zsh)
        if [[ -n "$ZSH_VERSION" ]]; then
          setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_REDUCE_BLANKS HIST_VERIFY
          setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
          setopt COMPLETE_IN_WORD MENU_COMPLETE NO_CASE_GLOB NO_BEEP INTERACTIVE_COMMENTS
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
          bindkey "^[[1;3D" backward-word
          bindkey "^[[1;3C" forward-word
        fi

        # Tool initialization
        if [[ -n "$ZSH_VERSION" ]]; then
          eval "$(starship init zsh)"
          eval "$(zoxide init zsh)"
          if fzf --zsh &>/dev/null; then
            eval "$(fzf --zsh)"
          elif [[ -f "''${FZF_BASE:-/usr/share/fzf}/key-bindings.zsh" ]]; then
            source "''${FZF_BASE:-/usr/share/fzf}/key-bindings.zsh"
          fi
        elif [[ -n "$BASH_VERSION" ]]; then
          eval "$(starship init bash)"
          eval "$(zoxide init bash)"
          if fzf --bash &>/dev/null; then
            eval "$(fzf --bash)"
          elif [[ -f "''${FZF_BASE:-/usr/share/fzf}/key-bindings.bash" ]]; then
            source "''${FZF_BASE:-/usr/share/fzf}/key-bindings.bash"
          fi
        fi

        # Aliases
        alias ls="eza"
        alias ll="eza -la"
        alias la="eza -lah --git"
        alias tree="eza --tree"
        alias cat="bat --plain"
        alias preview='fzf --preview="bat --color=always {}"'
        alias add="git add"
        alias push="git push"
        alias pull="git pull"
        alias fetch="git fetch"

        # Functions
        man() { command man "$@" | bat -l man -p; }
        run() {
          if [[ -e bun.lockb ]]; then bun run "$@"
          elif [[ -e yarn.lock ]]; then yarn run "$@"
          elif [[ -e pnpm-lock.yaml ]]; then pnpm run "$@"
          elif [[ -e package-lock.json ]]; then npm run "$@"
          else npm run "$@"; fi
        }
        cleandev() {
          for port in 3000 3001 4000 5173 5174 8080 8081 4200 9000; do
            lsof -ti :$port 2>/dev/null | xargs -r kill -9 2>/dev/null
          done
          pkill -f "node.*dev|vite|webpack|next-server" 2>/dev/null || true
        }
        commit() {
          case $# in
            1) git commit -m "$1" ;;
            2) git commit -m "$1: $2" ;;
            3) git commit -m "$1: $2" -m "$3" ;;
            *) echo "Usage: commit [type] [subject] [body]"; return 1 ;;
          esac
        }
        gits() { git status -s | fzf --multi --preview 'git diff --color {2}'; }
      '';
    };
}
