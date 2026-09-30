function cleanup --description "Audit/Cleanup Arch-based system safely"
    argparse 'a/audit' 'c/clean' 'd/deep' 'f/flatpak-only' 'y/yes' 'h/help' 'm/manual' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: cleanup [--audit] [--clean] [--deep] [--flatpak-only] [--yes] [--manual]"
        echo "  --audit         Show what can be cleaned"
        echo "  --clean         Run cleanup"
        echo "  --deep          Stronger cleanup (implies --clean)"
        echo "  --flatpak-only  Cleanup Flatpak only"
        echo "  --yes           Non-interactive orphan removal"
        echo "  --manual        Clean items BleachBit does not handle"
        return 0
    end

    set -l do_audit 0
    set -l do_clean 0
    set -l do_deep 0
    set -l flatpak_only 0
    set -l assume_yes 0
    set -l manual_only 0
    set -l do_manual 0

    set -q _flag_audit; and set do_audit 1
    set -q _flag_clean; and set do_clean 1
    set -q _flag_deep; and set do_deep 1; and set do_clean 1
    set -q _flag_flatpak_only; and set flatpak_only 1; and set do_clean 1
    set -q _flag_yes; and set assume_yes 1
    set -q _flag_manual; and set manual_only 1; and set do_manual 1; and set do_clean 1

    if test $do_audit -eq 0 -a $do_clean -eq 0
        set do_audit 1
    end

    if test $do_audit -eq 1
        echo "== OS =="
        if test -r /etc/os-release
            grep -E '^(PRETTY_NAME|ID|ID_LIKE)=' /etc/os-release
        end
        echo

        echo "== Disk usage =="
        df -h /
        echo

        if test $flatpak_only -eq 0
            echo "== Pacman cache =="
            du -sh /var/cache/pacman/pkg 2>/dev/null
            echo

            echo "== Orphan packages =="
            set -l orphans (pacman -Qdtq 2>/dev/null)
            if test (count $orphans) -gt 0
                echo "Count: "(count $orphans)
                printf '%s\n' $orphans
            else
                echo "No orphan packages."
            end
            echo

            echo "== Journal usage =="
            journalctl --disk-usage 2>/dev/null
            echo

            if type -q yay
                echo "== AUR orphan packages (yay) =="
                set -l aur_orphans (yay -Qdtq 2>/dev/null)
                if test (count $aur_orphans) -gt 0
                    echo "Count: "(count $aur_orphans)
                    printf '%s\n' $aur_orphans
                else
                    echo "No AUR orphans."
                end
                echo
            end
        end

        echo "== Flatpak apps =="
        if type -q flatpak
            set -l flatpak_apps (flatpak list --app --columns=application 2>/dev/null)
            if test (count $flatpak_apps) -gt 0
                echo "Count: "(count $flatpak_apps)
                printf '%s\n' $flatpak_apps
            else
                echo "No flatpak apps."
            end
            echo

            echo "== Flatpak unused (dry-run) =="
            flatpak uninstall --unused --noninteractive --dry-run
        else
            echo "flatpak not installed"
        end
        # Manual cleanup section
        if test $manual_only -eq 1 -o $do_audit -eq 1
            echo "== Manual cleanup =="
            set -l manual_total 0

            # npm cache (5.6GB) — not a BleachBit cleaner
            if test -d ~/.npm/_cacache
                set -l npm_size (du -sh ~/.npm/_cacache 2>/dev/null | cut -f1)
                echo "  npm cache (~/.npm/_cacache): $npm_size"
                set manual_total (math "$manual_total + 0")
            else
                echo "  npm cache: not present"
            end

            # Helium browser cache (~1.7GB) — no BleachBit rule for it
            if test -d ~/.cache/net.imput.helium
                set -l helium_size (du -sh ~/.cache/net.imput.helium 2>/dev/null | cut -f1)
                echo "  Helium cache (~/.cache/net.imput.helium): $helium_size"
            else
                echo "  Helium cache: not present"
            end

            # extension.js Electron app cache
            if test -d ~/.cache/extension.js
                set -l extjs_size (du -sh ~/.cache/extension.js 2>/dev/null | cut -f1)
                echo "  extension.js cache: $extjs_size"
            else
                echo "  extension.js cache: not present"
            end

            # opencode AI cache + data (~959MB)
            set -l opencode_cache_size ""
            set -l opencode_data_size ""
            if test -d ~/.cache/opencode
                set opencode_cache_size (du -sh ~/.cache/opencode 2>/dev/null | cut -f1)
            end
            if test -d ~/.local/share/opencode
                set opencode_data_size (du -sh ~/.local/share/opencode 2>/dev/null | cut -f1)
            end
            if test -n "$opencode_cache_size" -o -n "$opencode_data_size"
                echo "  opencode cache: $opencode_cache_size | data: $opencode_data_size"
            else
                echo "  opencode cache: not present"
            end

            # phpactor cache (~370MB)
            if test -d ~/.cache/phpactor
                set -l phpactor_size (du -sh ~/.cache/phpactor 2>/dev/null | cut -f1)
                echo "  phpactor cache: $phpactor_size"
            else
                echo "  phpactor cache: not present"
            end

            # codebase-memory-mcp cache (~189MB)
            if test -d ~/.cache/codebase-memory-mcp
                set -l mem_size (du -sh ~/.cache/codebase-memory-mcp 2>/dev/null | cut -f1)
                echo "  codebase-memory-mcp cache: $mem_size"
            else
                echo "  codebase-memory-mcp cache: not present"
            end

            # caelestia (COSMIC DE) cache (~96MB)
            if test -d ~/.cache/caelestia
                set -l caelestia_size (du -sh ~/.cache/caelestia 2>/dev/null | cut -f1)
                echo "  caelestia (COSMIC DE) cache: $caelestia_size"
            else
                echo "  caelestia cache: not present"
            end

            # mesa shader cache (~45MB)
            if test -d ~/.cache/mesa_shader_cache
                set -l mesa_size (du -sh ~/.cache/mesa_shader_cache 2>/dev/null | cut -f1)
                echo "  mesa shader cache: $mesa_size"
            else
                echo "  mesa shader cache: not present"
            end

            # cliphist (Wayland clipboard history via cliphist)
            if type -q cliphist
                set -l cliphist_size (cliphist list 2>/dev/null | wc -l)
                echo "  cliphist entries: $cliphist_size (run 'cliphist wipe' to clear)"
            else
                echo "  cliphist: not installed"
            end

            echo
        end

        echo
    end

    if test $do_clean -eq 1
        if test $flatpak_only -eq 0
            echo "== Cleaning pacman cache (keep 2 versions) =="
            if type -q paccache
                sudo paccache -rk2
                sudo paccache -ruk0
            else
                echo "paccache not found. Install pacman-contrib."
            end

            echo
            echo "== Cleaning old journals (keep 14 days) =="
            sudo journalctl --vacuum-time=14d

            echo
            set -l orphans (pacman -Qdtq 2>/dev/null)
            # Packages cấm xóa — không gì được phép gỡ dù là orphan
            set -l protected_packages adw-gtk-theme breeze-icons kiconthemes kiconthemes5 adwaita-icon-theme papirus-icon-theme numix-icon-theme
            set -l filtered_orphans
            for pkg in $orphans
                set -l skip 0
                for p in $protected_packages
                    if test "$pkg" = "$p"
                        echo "  ⚠ Bảo vệ, bỏ qua: $pkg"
                        set skip 1
                        break
                    end
                end
                if test $skip -eq 0
                    set filtered_orphans $filtered_orphans $pkg
                end
            end

            if test (count $filtered_orphans) -gt 0
                echo "== Orphan packages (an toàn để xóa) =="
                printf '%s\n' $filtered_orphans
                echo
                set -l remove_orphans 0
                if test $assume_yes -eq 1
                    set remove_orphans 1
                else
                    read -l -P "Xóa orphan packages? [y/N] " ans
                    if string match -qi "y" -- $ans
                        set remove_orphans 1
                    end
                end

                if test $remove_orphans -eq 1
                    sudo pacman -Rns $filtered_orphans
                else
                    echo "Skip orphan removal."
                end
            else
                echo "No orphan packages to remove."
            end

            if type -q yay
                echo
                echo "== Cleaning yay cache =="
                yay -Sc --noconfirm
            end
        end

        echo
        echo "== Cleaning Flatpak unused runtimes =="
        if type -q flatpak
            # Flatpak apps installed by user — không tự động bỏ nếu chưa xác nhận
            set -l protected_flatpak "com.systemcosmic.CosmicFiles\|org.gnome.Nautilus\|org.kde.dolphin\|org.xfce.thunar"
            flatpak uninstall --unused --dry-run 2>/dev/null | grep -v "No unusable runtimes"
            set -l flatpak_answer "n"
            if test $assume_yes -eq 1
                set flatpak_answer "y"
            else
                read -l -P "Remove unused Flatpak runtimes/apps? [y/N] " flatpak_answer
            end
            if string match -qi "y" -- $flatpak_answer
                flatpak uninstall --unused -y
            else
                echo "  Skip Flatpak cleanup."
            end
        else
            echo "flatpak not installed"
        end
    end

    # Manual cleanup items
    if test $do_manual -eq 1
        echo
        echo "== Manual cleanup (BleachBit không chạm) =="
        echo ""
        echo "  Chuẩn bị xóa các cache sau:"
        echo "    • npm cache (~/.npm/_cacache)"
        echo "    • Helium browser cache (~/.cache/net.imput.helium) — sẽ phải đăng nhập lại"
        echo "    • opencode cache (~/.cache/opencode — an toàn)"
        echo "    • phpactor cache (~/.cache/phpactor)"
        echo "    • codebase-memory-mcp cache (~/.cache/codebase-memory-mcp)"
        echo "    • caelestia/COSMIC cache (~/.cache/caelestia)"
        echo "    • mesa shader cache (~/.cache/mesa_shader_cache)"
        echo "    • cliphist entries (nếu đã cài)"
        echo ""
        echo "  ⚠ ~/.local/share/opencode có chứa opencode.db (session chat) — KHÔNG bị xóa"
        echo "  ⚠ Helium cache sẽ làm mất đăng nhập web"
        echo ""

        set -l confirm 0
        if test $assume_yes -eq 1
            set confirm 1
        else
            read -l -P "Tiếp tục? [y/N] " ans
            if string match -qi "y" -- $ans
                set confirm 1
            end
        end

        if test $confirm -eq 0
            echo "  Đã hủy."
        else
            echo ""

        # npm cache
        if test -d ~/.npm/_cacache
            echo "  npm cache clean --force"
            npm cache clean --force 2>/dev/null
            echo "    ✓ npm cache cleaned"
        else
            echo "  npm cache: (--not-present, skipping)"
        end

        # Helium browser
        if test -d ~/.cache/net.imput.helium
            echo "  Removing Helium cache"
            rm -rf ~/.cache/net.imput.helium
            echo "    ✓ Helium cache removed"
        else
            echo "  Helium cache: (--not-present, skipping)"
        end

        # opencode AI cache (~604MB) — SAFE: chỉ chứa models.json + npm packages
        # ⚠️  ~/.local/share/opencode chứa opencode.db (session chat) — KHÔNG xóa
        set -l did_opencode 0
        if test -d ~/.cache/opencode
            echo "  Removing opencode cache (~/.cache/opencode — safe)"
            rm -rf ~/.cache/opencode
            echo "    ✓ opencode cache removed"
            set did_opencode 1
        end
        if test -d ~/.local/share/opencode
            echo "  ⚠  ~/.local/share/opencode chứa opencode.db (session chat)"
            echo "     → giữ nguyên, không xóa"
            set did_opencode 1
        end
        if test $did_opencode -eq 0
            echo "  opencode cache: (--not-present, skipping)"
        end

        # phpactor cache
        if test -d ~/.cache/phpactor
            echo "  Removing phpactor cache"
            rm -rf ~/.cache/phpactor
            echo "    ✓ phpactor cache removed"
        else
            echo "  phpactor cache: (--not-present, skipping)"
        end

        # codebase-memory-mcp cache
        if test -d ~/.cache/codebase-memory-mcp
            echo "  Removing codebase-memory-mcp cache"
            rm -rf ~/.cache/codebase-memory-mcp
            echo "    ✓ codebase-memory-mcp cache removed"
        else
            echo "  codebase-memory-mcp cache: (--not-present, skipping)"
        end

        # caelestia / COSMIC DE cache
        if test -d ~/.cache/caelestia
            echo "  Removing caelestia (COSMIC DE) cache"
            rm -rf ~/.cache/caelestia
            echo "    ✓ caelestia cache removed"
        else
            echo "  caelestia cache: (--not-present, skipping)"
        end

        # mesa shader cache
        if test -d ~/.cache/mesa_shader_cache
            echo "  Removing mesa shader cache"
            rm -rf ~/.cache/mesa_shader_cache
            echo "    ✓ mesa shader cache removed"
        else
            echo "  mesa shader cache: (--not-present, skipping)"
        end

        # cliphist — Wayland clipboard history manager
        if type -q cliphist
            set -l clip_count (cliphist list 2>/dev/null | wc -l)
            if test $clip_count -gt 0
                echo "  cliphist wipe ($clip_count entries)"
                cliphist wipe
                echo "    ✓ cliphist wiped"
            else
                echo "  cliphist: already empty"
            end
        else
            echo "  cliphist: (--not-installed, skipping)"
        end

        echo "  Manual cleanup complete."
        end
    end

    if test $do_deep -eq 1 -a $flatpak_only -eq 0
        echo
        echo "== Deep mode: keep only 1 package version in cache =="
        if type -q paccache
            sudo paccache -rk1
        else
            echo "paccache not found. Install pacman-contrib."
        end
    end

    if test $do_clean -eq 1
        echo
        echo "Done. Run: cleanup --audit"
    end
end
