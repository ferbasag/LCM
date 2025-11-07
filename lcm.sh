#!/bin/bash

set -euo pipefail

readonly LOG_DIR="$HOME/.lcm/logs"
readonly CONFIG_FILE="$HOME/.lcm/command_logging.sh"
readonly BASHRC="$HOME/.bashrc"

echo "Installing Command Monitoring System (User-specific)..."

# Create user-specific log directory
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# Create logging script
cat << 'LOGGING_SCRIPT' > "$CONFIG_FILE"
#!/bin/bash

[ -n "$BASH_VERSION" ] || return
case $- in *i*) ;; *) return ;; esac

USER_LOG="$HOME/.lcm/logs/$(whoami)_commands.log"

if [[ ! -f "$USER_LOG" ]]; then
    mkdir -p "$HOME/.lcm/logs" 2>/dev/null
    : >"$USER_LOG" 2>/dev/null || true
    chmod 600 "$USER_LOG" 2>/dev/null || true
fi

log_command() {
    local last_cmd
    last_cmd="$(history 1 | sed 's/^[ ]*[0-9]\+[ ]*//')"

    if [[ -n "$last_cmd" && "$last_cmd" != "log_command" ]]; then
        local safe_cmd="$last_cmd"

        # Essential Security Filters (5 most common patterns)
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/-p'[^']+'/***FILTERED***/g")                                    # MySQL -p'pass'
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/-p[[:alnum:]@#$%^&*()_+=!-]+/-p***FILTERED***/g")              # MySQL -ppass
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(--password[= ])[^ ]+/\1***FILTERED***/gi")                    # --password=
        safe_cmd=$(echo "$safe_cmd" | sed -E "s|://[^:]+:[^@]+@|://***FILTERED***@|g")                         # URLs user:pass@
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(export[[:space:]]+[A-Z_]*(PASSWORD|SECRET|TOKEN|KEY|API)[A-Z_]*=)[^ ]+/\1***FILTERED***/gi")  # ENV vars

        printf "%s | %s | %s | %s\n" \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$(whoami)" \
            "$(pwd)" \
            "$safe_cmd" >> "$USER_LOG" 2>/dev/null
    fi
}

# Simple PROMPT_COMMAND setup
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="history -a; log_command"
else
    case ";$PROMPT_COMMAND;" in
        *";log_command;"*) : ;;
        *) PROMPT_COMMAND="${PROMPT_COMMAND}; log_command" ;;
    esac
fi

export PROMPT_COMMAND
LOGGING_SCRIPT

chmod +x "$CONFIG_FILE"

# Add to bashrc if not already present
if ! grep -q ".lcm/command_logging.sh" "$BASHRC" 2>/dev/null; then
    cat << 'BASHRC_SOURCE' >> "$BASHRC"

# LCM Command Logging
if [ -f "$HOME/.lcm/command_logging.sh" ]; then
    source "$HOME/.lcm/command_logging.sh"
fi
BASHRC_SOURCE
fi

# Add monitoring functions to bashrc if not already present
if ! grep -q "^lcm()" "$BASHRC" 2>/dev/null; then
    cat << 'MONITORING_FUNCTIONS' >> "$BASHRC"

# LCM Monitoring Functions
lcm() {
    echo "=== COMMAND MONITORING DASHBOARD ==="
    echo "User: $(whoami) | $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    local USER_LOG="$HOME/.lcm/logs/$(whoami)_commands.log"

    echo "Last 50 Commands:"
    if [ -f "$USER_LOG" ]; then
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' "$USER_LOG" 2>/dev/null | \
        tail -50 | \
        awk -F' \| ' '{printf "%-20s | %s\n", $1, $4}'
    else
        echo "No logs available. Restart terminal."
    fi
    echo

    echo "Commands: lcm-all, lcm-today, lcm-search <term>"
}

lcm-all() {
    local USER_LOG="$HOME/.lcm/logs/$(whoami)_commands.log"
    echo "=== ALL COMMANDS (Last 1000) ==="
    if [ -f "$USER_LOG" ]; then
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' "$USER_LOG" 2>/dev/null | \
        tail -1000 | \
        awk -F' \| ' '{printf "%-20s | %s\n", $1, $4}'
    else
        echo "No logs found."
    fi
}

lcm-today() {
    local USER_LOG="$HOME/.lcm/logs/$(whoami)_commands.log"
    local today=$(date '+%Y-%m-%d')
    echo "=== TODAY'S COMMANDS - $today ==="
    if [ -f "$USER_LOG" ]; then
        grep "^$today" "$USER_LOG" 2>/dev/null | \
        awk -F' \| ' '{printf "%-20s | %s\n", $1, $4}'
    else
        echo "No logs found."
    fi
}

lcm-search() {
    [ -z "$1" ] && { echo "Usage: lcm-search <term>"; return 1; }

    local USER_LOG="$HOME/.lcm/logs/$(whoami)_commands.log"
    echo "=== SEARCH: $1 ==="
    if [ -f "$USER_LOG" ]; then
        grep -i "$1" "$USER_LOG" 2>/dev/null | \
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -100 | \
        awk -F' \| ' '{printf "%-20s | %s\n", $1, $4}'
    else
        echo "No logs found."
    fi
}

MONITORING_FUNCTIONS
fi

echo "✓ Installation completed"
echo "✓ Basic security filters enabled"
echo "✓ Logs stored in: $LOG_DIR"
echo "✓ Only you can see your commands"
echo "✓ Restart your terminal or run: source ~/.bashrc"
echo "✓ Run 'lcm' to view your logs"
