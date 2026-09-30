function reset_navicat
    set -l BGRED "\e[1;97;41m"
    set -l ENDCOLOR "\e[0m"

    echo -e "$BGRED                                            $ENDCOLOR"
    echo -e "$BGRED  ┌──────────────────────────────────────┐  $ENDCOLOR"
    echo -e "$BGRED  │            !!! WARNING !!!           │  $ENDCOLOR"
    echo -e "$BGRED  ├──────────────────────────────────────┤  $ENDCOLOR"
    echo -e "$BGRED  │      ALL DATA can be destroyed.      │  $ENDCOLOR"
    echo -e "$BGRED  │   Always BACKUP before continuing.   │  $ENDCOLOR"
    echo -e "$BGRED  └──────────────────────────────────────┘  $ENDCOLOR"
    echo -e "$BGRED                                            $ENDCOLOR"

    echo -e "Reset trial \e[1mNavicat Premium\e[0m:"

    # Check for -y / --yes / -Y / --Yes flag
    if not string match -qr '^--?[Yy]([eE][sS])?$' -- $argv[1]
        read -l -P "Are you sure? (y/N) " reply
        echo
        if not string match -qr '^[Yy]([eE][sS])?$' -- $reply
            echo "Aborted."
            return 0
        end
    end

    echo "Starting reset..."
    set -l DATE (date '+%Y%m%d_%H%M%S')

    # Backup
    echo "=> Creating a backup..."
    mkdir -p ~/.config/dconf/user-backup ~/.config/navicat/Premium/preferences-backup
    cp ~/.config/dconf/user ~/.config/dconf/user-backup/user.$DATE
    echo "The user dconf backup was created at $HOME/.config/dconf/user-backup/user.$DATE"
    cp ~/.config/navicat/Premium/preferences.json ~/.config/navicat/Premium/preferences-backup/preferences.json.$DATE
    echo "The Navicat preferences backup was created at $HOME/.config/navicat/Premium/preferences-backup/preferences.json.$DATE"

    # Install dconf if missing
    if not command -q dconf
        echo "=> dconf is not installed. Installing..."

        if command -q apt-get
            sudo apt-get update
            sudo apt-get install -y dconf-cli
        else if command -q dnf
            sudo dnf install -y dconf
        else if command -q yum
            sudo yum install -y dconf
        else if command -q pacman
            sudo pacman -Sy --noconfirm dconf
        else
            echo "Package manager not supported. Please install dconf manually."
            return 1
        end
    end

    # Clear data in dconf
    echo "=> Resetting..."
    dconf reset -f /com/premiumsoft/navicat-premium/
    echo "The user dconf data was reset"

    # Remove data fields in config file
    sed -i -E 's/,?"([A-F0-9]+)":\{([^\}]+)},?//g' ~/.config/navicat/Premium/preferences.json
    echo "The Navicat preferences was reset"

    echo "Done."
end