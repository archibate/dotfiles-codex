#!/usr/bin/env bash
# Ensure pueue daemon running with memory cap via user-scope cgroup.
# Needs `loginctl enable-linger $USER` once so user@$UID.service stays up.

if ! pgrep -x pueued &>/dev/null; then
    mem_cap="${PUEUE_MEMORY_MAX:-$(awk '/MemTotal/{printf "%d\n", $2/2}' /proc/meminfo)K}"
    uid="$(id -u)"
    pueued_bin="$(command -v pueued)"
    if [[ -z "$pueued_bin" ]]; then
        echo "❌ pueued not found in PATH" >&2
        exit 1
    fi

    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$uid}"
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

    if ! systemctl --user is-active --quiet default.target 2>/dev/null \
       && ! loginctl show-user "$uid" -p Linger --value 2>/dev/null | grep -qx yes; then
        echo "❌ user@$uid.service not running. Run: loginctl enable-linger $USER" >&2
        exit 1
    fi

    echo "🔄 Starting pueue daemon (MemoryMax=$mem_cap)..."
    systemd-run --user \
        --unit=pueued-limited \
        -p MemoryMax="$mem_cap" \
        "$pueued_bin"

    sleep 1
    if ! pgrep -x pueued &>/dev/null; then
        echo "❌ Failed to start pueue daemon" >&2
        exit 1
    fi
    echo "✅ Daemon started under user systemd with MemoryMax=$mem_cap"
fi
