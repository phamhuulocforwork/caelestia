function helium_debug --description 'Launch Helium with remote debugging enabled for chrome-devtools-mcp'
    set -l port 9222
    set -l profile_dir /tmp/helium-profile-debug

    # tùy chọn: truyền port khác, vd `helium-debug 9333`
    if test (count $argv) -ge 1
        set port $argv[1]
    end

    mkdir -p $profile_dir

    helium-browser --remote-debugging-port=$port --user-data-dir=$profile_dir
end
