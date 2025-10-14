#!/bin/bash

set -euo pipefail

readonly LOG_DIR="/var/log/bash_commands"
readonly PROFILE_SCRIPT="/etc/profile.d/command_logging.sh"
readonly BASHRC_CONFIG="/etc/bash.bashrc"
readonly LOGROTATE_CONFIG="/etc/logrotate.d/bash-command-logs"

if [[ $EUID -ne 0 ]]; then
    echo "Error: Root privileges required"
    echo "Run with: sudo $0"
    exit 1
fi

echo "Installing Command Monitoring System..."

mkdir -p "$LOG_DIR"
chmod 777 "$LOG_DIR"

cat << 'LOGGING_SCRIPT' > "$PROFILE_SCRIPT"
#!/bin/bash

[ -n "$BASH_VERSION" ] || return
case $- in *i*) ;; *) return ;; esac

USER_LOG="/var/log/bash_commands/$(whoami)_commands.log"

if [[ ! -f "$USER_LOG" ]]; then
    : >"$USER_LOG" 2>/dev/null || true
    chmod 666 "$USER_LOG" 2>/dev/null || true
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

chmod +x "$PROFILE_SCRIPT"

# Source in bashrc for VSCode support
if ! grep -q "command_logging.sh" "$BASHRC_CONFIG" 2>/dev/null; then
    cat << 'BASHRC_SOURCE' >> "$BASHRC_CONFIG"

# Command Logging
if [ -f /etc/profile.d/command_logging.sh ]; then
    source /etc/profile.d/command_logging.sh
fi
BASHRC_SOURCE
fi

# Add monitoring functions
cat << 'MONITORING_FUNCTIONS' >> "$BASHRC_CONFIG"

lcm() {
    echo "=== COMMAND MONITORING DASHBOARD ==="
    echo "Server: $(hostname) | $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    echo "Currently Logged In Users:"
    w 2>/dev/null || who
    echo
    
    echo "Last 50 Commands:"
    if ls /var/log/bash_commands/*_commands.log &>/dev/null; then
        cat /var/log/bash_commands/*_commands.log 2>/dev/null | \
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | \
        sort -k1,2 | tail -50 | \
        awk -F' \\| ' '{printf "%-20s | %-12s | %s\n", $1, $2, $4}'
    else
        echo "No logs available. Restart terminal."
    fi
    echo
    
    echo "Commands: lcm-all, lcm-user <user>, lcm-today, lcm-search <term>"
}

lcm-all() {
    echo "=== ALL COMMANDS (Last 1000) ==="
    if ls /var/log/bash_commands/*_commands.log &>/dev/null; then
        cat /var/log/bash_commands/*_commands.log 2>/dev/null | \
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | \
        sort -k1,2 | tail -1000 | \
        awk -F' \\| ' '{printf "%-20s | %-12s | %s\n", $1, $2, $4}'
    else
        echo "No logs found."
    fi
}

lcm-user() {
    [ -z "$1" ] && { echo "Usage: lcm-user <username>"; return 1; }
    
    local logfile="/var/log/bash_commands/${1}_commands.log"
    if [ -f "$logfile" ]; then
        echo "=== COMMANDS - USER: $1 ==="
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' "$logfile" | tail -500 | \
        awk -F' \\| ' '{printf "%-20s | %s\n", $1, $4}'
    else
        echo "No logs for user '$1'"
    fi
}

lcm-today() {
    local today=$(date '+%Y-%m-%d')
    echo "=== TODAY'S COMMANDS - $today ==="
    if ls /var/log/bash_commands/*_commands.log &>/dev/null; then
        grep "^$today" /var/log/bash_commands/*_commands.log 2>/dev/null | \
        awk -F' \\| ' '{printf "%-20s | %-12s | %s\n", $1, $2, $4}'
    else
        echo "No logs found."
    fi
}

lcm-search() {
    [ -z "$1" ] && { echo "Usage: lcm-search <term>"; return 1; }
    
    echo "=== SEARCH: $1 ==="
    if ls /var/log/bash_commands/*_commands.log &>/dev/null; then
        grep -i "$1" /var/log/bash_commands/*_commands.log 2>/dev/null | \
        grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -100 | \
        awk -F' \\| ' '{printf "%-20s | %-12s | %s\n", $1, $2, $4}'
    else
        echo "No logs found."
    fi
}

MONITORING_FUNCTIONS

cat << 'LOGROTATE' > "$LOGROTATE_CONFIG"
/var/log/bash_commands/*_commands.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0666 root root
}
LOGROTATE

echo "✓ Installation completed"
echo "✓ Basic security filters enabled"
echo "✓ Users must restart terminals"
echo "✓ Run 'lcm' to view logs"
