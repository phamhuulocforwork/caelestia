function setup_android_dev
    set -l ANDROID_SDK_PATH "$HOME/Android/Sdk"

    echo "🤖 Bắt đầu setup Android dev environment..."
    echo ""

    # ── 1. Kiểm tra yay ──────────────────────────────────────────────
    echo "📦 [1/5] Kiểm tra AUR helper (yay)..."
    if not command -q yay
        echo "  → yay chưa có, đang cài..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        and pushd /tmp/yay
        and makepkg -si --noconfirm
        and popd
        and rm -rf /tmp/yay
        or begin
            echo "  ❌ Cài yay thất bại!"
            return 1
        end
    else
        echo "  ✔ yay đã có"
    end

    # ── 2. Cài JDK 17 ────────────────────────────────────────────────
    echo ""
    echo "☕ [2/5] Cài JDK 17..."
    if not command -q java; or not java -version 2>&1 | grep -q "17"
        sudo pacman -S --needed --noconfirm jdk17-openjdk
        and sudo archlinux-java set java-17-openjdk
        or begin
            echo "  ❌ Cài JDK thất bại!"
            return 1
        end
    else
        echo "  ✔ JDK 17 đã có"
    end

    # ── 3. Cài Android Studio ─────────────────────────────────────────
    echo ""
    echo "🤖 [3/5] Cài Android Studio..."
    if not command -q android-studio
        yay -S --needed --noconfirm android-studio
        or begin
            echo "  ❌ Cài Android Studio thất bại!"
            return 1
        end
    else
        echo "  ✔ Android Studio đã có"
    end

    # ── 4. Cài android-udev rules ─────────────────────────────────────
    echo ""
    echo "🔌 [4/5] Cài udev rules cho USB device..."
    sudo pacman -S --needed --noconfirm android-udev
    and sudo udevadm control --reload-rules
    and sudo udevadm trigger
    or echo "  ⚠ Không cài được android-udev, bỏ qua..."

    # ── 5. Set biến môi trường trong Fish ─────────────────────────────
    echo ""
    echo "🐟 [5/5] Ghi biến môi trường vào Fish config..."

    # Tránh duplicate nếu chạy lại
    if not grep -q "ANDROID_HOME" $__fish_config_dir/config.fish 2>/dev/null
        echo "" >> $__fish_config_dir/config.fish
        echo "# Android SDK" >> $__fish_config_dir/config.fish
        echo "set -x ANDROID_HOME $ANDROID_SDK_PATH" >> $__fish_config_dir/config.fish
        echo 'set -x PATH $PATH $ANDROID_HOME/tools $ANDROID_HOME/tools/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/build-tools/34.0.0' >> $__fish_config_dir/config.fish
        echo "  ✔ Đã ghi vào config.fish"
    else
        echo "  ✔ Biến môi trường đã có sẵn, bỏ qua"
    end

    # Apply ngay trong session hiện tại
    set -x ANDROID_HOME $ANDROID_SDK_PATH
    fish_add_path $ANDROID_HOME/tools $ANDROID_HOME/tools/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/build-tools/34.0.0

    # ── Done ───────────────────────────────────────────────────────────
    echo ""
    echo "✅ Setup xong! Tóm tắt:"
    echo "   Java   : "(java -version 2>&1 | head -1)
    echo "   ADB    : "(adb version 2>/dev/null | head -1; or echo 'chưa thấy — mở Android Studio để cài SDK trước')
    echo "   SDK    : $ANDROID_SDK_PATH"
    echo ""
    echo "👉 Bước tiếp theo:"
    echo "   1. Mở Android Studio: android-studio &"
    echo "   2. Vào SDK Manager → cài Platform + Build-Tools"
    echo "   3. Tạo AVD trong Device Manager nếu dùng emulator"
    echo "   4. Bật USB Debugging trên điện thoại nếu dùng real device"
    echo "   5. Test kết nối: adb devices"
end