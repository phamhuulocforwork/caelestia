if status is-interactive

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Custom colours
    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
    
    # Custom fish config
    source ~/.config/caelestia/user-config.fish 2> /dev/null
end

#####################################
##==> Aliases
#####################################
# Windows Development Aliases
alias github="cd ~/Github"
alias update-all='sudo pacman -Syu && yay -Sua && flatpak update'
alias cleanup-update='sudo pacman -Sc && yay -Sc && flatpak uninstall --unused -y'

# Github alias
alias python="python3"

# Laravel Aliases
alias art="php artisan"
alias pas="php artisan serve"
alias parl="php artisan route:clear"
alias pajob="php artisan queue:work --daemon"

# Quick Navigation
alias home="cd ~"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# File Operations
alias ls='eza --icons --group-directories-first -1'
alias ll="ls -la"
alias la="ls -la"
alias l="ls -l"
alias cls="clear"

# Git Shortcuts
alias gs="git status"
alias gsp="git stash push"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gcp="git cherry-pick"
alias gb="git branch"
alias gd="git diff"
alias glog="git log --oneline --graph --decorate"

# Node.js/NPM Shortcuts
alias ni="npm install"
alias ns="npm start"
alias nt="npm test"
alias nb="npm run build"
alias nd="npm run dev"
alias nrd="npm run dev"
alias nrs="npm run start"
alias nrt="npm run test"
alias nrb="npm run build"

# Yarn Shortcuts
alias ys="yarn start"
alias yi="yarn install"
alias yt="yarn test"
alias yb="yarn build"
alias yd="yarn dev"

# System Utils
alias reload="source ~/.config/fish/config.fish"
alias editrc="code ~/.config/fish/config.fish"
alias editfish="code ~/.config/fish/config.fish"

# Docker Shortcuts
alias dc="docker-compose" 
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcb="docker-compose build"
alias dps="docker ps"
alias di="docker images"

# IDE/Editor Shortcuts
alias chown-code="sudo chown -R $(whoami) /opt/visual-studio-code"
alias code="code ."
alias cursor="cursor ."
alias anti="antigravity ."
alias zed="zeditor ."
alias codeh="code ~"
alias cursorh="cursor ~"
alias antih="antigravity ~"
alias zedh="zeditor ~"

#####################################
##==> Custom Functions
#####################################
function codebase-index
    codebase-memory-mcp cli index_repository --repo-path "$PWD" --mode full
end

function git-setup
    git config --show-origin --get-all core.hooksPath
end

function wget
    command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" $argv
end

function nvidia-settings
    mkdir -p $XDG_CONFIG_HOME/nvidia/
    command nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" $argv
end

function mkcd
    mkdir -p "$argv[1]"; and cd "$argv[1]"
end

function ginit
    git init
    git add .
    git commit -m "feat: initial commit"
end

function gclone
    git clone "git@github.com:phamhuulocforwork/$argv[1].git"
    if test (count $argv) -ge 2
        cd "$argv[2]"
    else
        cd "$argv[1]"
    end
end

function mclone
    set file "$argv[1]"

    if test -z "$file"; or not test -f "$file"
        echo "Usage: mclone <file_with_repo_urls>"
        return 1
    end

    set repos
    while read -l line
        set line (echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if test -z "$line"; or string match -r '^#' "$line"
            continue
        end
        set repos $repos "$line"
    end < "$file"

    set n (count $repos)
    if test $n -eq 0
        echo "File does not have a valid repo"
        return 1
    end

    echo "Cloning $n repos in parallel..."

    if command -v parallel >/dev/null 2>&1
        printf "%s\n" $repos | parallel -j "$n" 'GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git clone {}'
    else
        for repo in $repos
            env GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git clone $repo &
        end
        wait
    end
end

function clone
    git clone "$argv[1]"
    if test (count $argv) -ge 2
        cd "$argv[2]"
    else
        cd (basename "$argv[1]" .git)
    end
end

function venv-clean
    echo "Deleting 'venv' folders..."
    find . -type d -name "venv" -exec rm -rf {} +
    echo "Done"
end

function npkill
    echo "Deleting node_modules, dist, build, .next, .cache, coverage, .turbo, .vite ..."
    find . -type d \( \
      -name "node_modules" -o \
      -name "dist" -o \
      -name "build" -o \
      -name ".next" -o \
      -name ".cache" -o \
      -name "coverage" -o \
      -name ".turbo" -o \
      -name ".vite" \
    \) -prune -exec rm -rf '{}' + 2>/dev/null
    echo "Done"
end

function ssh-setup
    echo -e "Generating SSH key..."

    set SSH_KEY "$HOME/.ssh/id_ed25519"
    if test ! -f "$SSH_KEY"
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "phamhuulocforwork@gmail.com" -f "$SSH_KEY" -N ""
        echo -e "SSH key generated at $SSH_KEY "
    else
        echo -e "SSH key already exists at $SSH_KEY "
    end

    if command -v wl-copy >/dev/null 2>&1
        cat "$SSH_KEY.pub" | wl-copy
        echo -e "SSH public key copied to clipboard (Wayland) "
    else if command -v xclip >/dev/null 2>&1
        cat "$SSH_KEY.pub" | xclip -selection clipboard
        echo -e "SSH public key copied to clipboard (X11) "
    else
        echo -e "Neither wl-copy nor xclip found. Please install one to copy SSH key to clipboard. "
        echo -e "You can still get your key with: cat $SSH_KEY.pub "
    end
end

function anti --wraps=antigravity --description 'alias anti=antigravity'
    set -l UNIT_NAME "antigravity-"(date +%s)
    set -l APP_BIN "/usr/bin/antigravity --verbose"
    set -l TRIGGER "Lifecycle#onWillShutdown - end 'antigravityAnalytics'"
    set -l ARGV $argv

    begin
        systemd-run --user --scope --unit="$UNIT_NAME" --property=KillMode=control-group \
            /bin/bash -c "exec prlimit --core=0 $APP_BIN $argv 2>&1 | systemd-cat --identifier=$UNIT_NAME" & disown

        fish -c "
            journalctl --user --identifier=$UNIT_NAME --follow | \
            grep --line-buffered --max-count=1 $TRIGGER >/dev/null 2>&1; and \
                systemctl --user kill --signal=SIGKILL $UNIT_NAME.scope
        " & disown
    end >/dev/null 2>&1
end

#####################################
##==> Shell Customization
#####################################
starship init fish | source

#####################################
##==> Fun Stuff
#####################################
if test "$PWD" = "$HOME"
    fastfetch
    cd ~/Github
end

# opencode
fish_add_path /home/billarch/.opencode/bin
# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<


# Added by Antigravity CLI installer
set -gx PATH "/home/billarch/.local/bin" $PATH

# pnpm
set -gx PNPM_HOME "/home/billarch/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end

fish_add_path /home/billarch/.spicetify
