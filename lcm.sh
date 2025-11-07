#!/bin/bash
#
# LCM User-Installer (v5 - Enhanced Logging + fzf TUI)
# Kombiniert v4-Filter mit einer interaktiven TUI.
#

set -euo pipefail

readonly LOG_DIR="$HOME/.lcm/logs"
readonly CONFIG_FILE="$HOME/.lcm/command_logging.sh"
readonly BASHRC="$HOME/.bashrc"

echo "Installing Command Monitoring System (User-specific)..."

# Create user-specific log directory
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR" # 700 = Nur Eigentümer darf rein

#
# --- v4 LOGGING SCRIPT (PERFEKT!) ---
#
cat << 'LOGGING_SCRIPT' > "$CONFIG_FILE"
#!/bin/bash
[ -n "$BASH_VERSION" ] || return
case $- in *i*) ;; *) return ;; esac

readonly USER_LOG="$HOME/.lcm/logs/$(whoami)_commands.log"

if [[ ! -f "$USER_LOG" ]]; then
    mkdir -p "$HOME/.lcm/logs" 2>/dev/null
    : >"$USER_LOG" 2>/dev/null || true
    chmod 600 "$USER_LOG" 2>/dev/null || true
fi

_lcm_log_command() {
    history -a
    
    if [[ ! -f "$HISTFILE" ]]; then
        return
    fi
    
    local last_cmd
    last_cmd=$(tail -n 1 "$HISTFILE" | sed 's/^[ ]*[0-9]\+[ ]*//')

    if [[ -n "$last_cmd" && "$last_cmd" != "_lcm_log_command" ]]; then
        local safe_cmd="$last_cmd"

        # Deine v4-Filter (sind super)
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/-p'[^']+'/***FILTERED***/g")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/-p[[:alnum:]@#$%^&*()_+=!-]+/-p***FILTERED***/g")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(--password[= ])[^ ]+/\1***FILTERED***/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s|://[^:]+:[^@]+@|://***FILTERED***@|g")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(--(secret|token|key)[= ])[^ ]+/\1***FILTERED***/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(--password-stdin[[:space:]]*<<<[[:space:]]*)[^ ]+/\1***FILTERED***/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(echo[[:space:]]+['\"])([^'\"]+)(['\"][[:space:]]*\|[[:space:]]*docker login)/echo ***FILTERED*** \3/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(--from-literal=[^=]+=)[^ ]+/\1***FILTERED***/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(^|[[:space:]])([A-Z_]*(PASSWORD|SECRET|TOKEN|KEY|API)[A-Z_]*=)[^ ]+/\1\2***FILTERED***/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(Authorization:[[:space:]]*Basic[[:space:]]+)[A-Za-z0-9+\/=]+/\1***FILTERED***/gi")
        safe_cmd=$(echo "$safe_cmd" | sed -E "s/(Authorization:[[:space:]]*Bearer[[:space:]]+)[A-Za-z0-9._~+\/-]+/\1***FILTERED***/gi")

        printf "%s | %s | %s | %s\n" \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$(whoami)" \
            "$(pwd)" \
            "$safe_cmd" >> "$USER_LOG" 2>/dev/null
    fi
}

# Deine v4 PROMPT_COMMAND-Logik (auch super)
PROMPT_COMMAND="${PROMPT_COMMAND%%;}"
PROMPT_COMMAND="${PROMPT_COMMAND%%+([[:space:]])}"

if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="_lcm_log_command"
else
    case ";$PROMPT_COMMAND;" in
        *";_lcm_log_command;"*) : ;;
        *) PROMPT_COMMAND="${PROMPT_COMMAND}; _lcm_log_command" ;;
    esac
fi
export PROMPT_COMMAND
LOGGING_SCRIPT
# --- ENDE v4 LOGGING SCRIPT ---

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

#
# --- NEU: fzf TUI FUNCTIONS (MIT AWK BUGFIX) ---
#
if ! grep -q "^lcm()" "$BASHRC" 2>/dev/null; then
    cat << 'MONITORING_FUNCTIONS' >> "$BASHRC"

# --- LCM Monitoring Functions (v5 - fzf TUI + awk bugfix) ---

# Interne Helper-Funktion
_lcm_get_log_file() {
    local logfile="$HOME/.lcm/logs/$(whoami)_commands.log"
    if [[ ! -f "$logfile" ]]; then
        echo "No logs found at $logfile" >&2
        return 1
    fi
    echo "$logfile"
}

# fzf-basierte interaktive TUI
_lcm_interactive_ui() {
    local USER_LOG="$1"
    local query="$2"
    
    # Lädt den gesamten Log-Inhalt (umgekehrt) in fzf
    grep -E '^[0-9]' "$USER_LOG" | \
    fzf --reverse --height 80% \
        --prompt="LCM Log > " \
        --query="$query" \
        --preview="echo {} | awk -F'[|]' '{print \"Time:  \" \$1 \"\nUser:  \" \$2 \"\nDir:   \" \$3 \"\nCmd:   \" \$4}'" \
        --preview-window=up:6
}

# Fallback-Funktion (wenn fzf nicht installiert ist)
_lcm_fallback_list() {
    local USER_LOG="$1"
    local tail_count="$2"
    
    echo "HINWEIS: 'fzf' nicht gefunden. Zeige statische Liste." >&2
    echo "Installiere 'fzf' (z.B. sudo apt install fzf) für eine interaktive TUI!" >&2
    echo
    
    # AWK-BUGFIX HIER: -F'[|]' statt -F' \| '
    grep -E '^[0-9]' "$USER_LOG" 2>/dev/null | \
    tail -n "$tail_count" | \
    awk -F'[|]' '{printf "%-20s | %s\n", $1, $4}'
}


lcm() {
    local USER_LOG
    USER_LOG=$(_lcm_get_log_file) || return
    
    if command -v fzf &> /dev/null; then
        _lcm_interactive_ui "$USER_LOG" ""
    else
        echo "=== COMMAND MONITORING DASHBOARD ==="
        echo "User: $(whoami) | $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "Last 50 Commands:"
        _lcm_fallback_list "$USER_LOG" 50
    fi
}

lcm-all() {
    local USER_LOG
    USER_LOG=$(_lcm_get_log_file) || return
    
    if command -v fzf &> /dev/null; then
        _lcm_interactive_ui "$USER_LOG" ""
    else
        echo "=== ALL COMMANDS (Last 1000) ==="
        _lcm_fallback_list "$USER_LOG" 1000
    fi
}

lcm-today() {
    local USER_LOG
    USER_LOG=$(_lcm_get_log_file) || return
    local today=$(date '+%Y-%m-%d')
    
    if command -v fzf &> /dev/null; then
        _lcm_interactive_ui "$USER_LOG" "$today"
    else
        echo "=== TODAY'S COMMANDS - $today ==="
        # AWK-BUGFIX HIER: -F'[|]'
        grep "^$today" "$USER_LOG" 2>/dev/null | \
        awk -F'[|]' '{printf "%-20s | %s\n", $1, $4}'
    fi
}

lcm-search() {
    [ -z "$1" ] && { echo "Usage: lcm-search <term>"; return 1; }
    
    local USER_LOG
    USER_LOG=$(_lcm_get_log_file) || return
    
    if command -v fzf &> /dev/null; then
        _lcm_interactive_ui "$USER_LOG" "$1"
    else
        echo "=== SEARCH: $1 ==="
        # AWK-BUGFIX HIER: -F'[|]'
        grep -i "$1" "$USER_LOG" 2>/dev/null | \
        grep -E '^[0-9]' | tail -100 | \
        awk -F'[|]' '{printf "%-20s | %s\n", $1, $4}'
    fi
}

MONITORING_FUNCTIONS
fi
# --- ENDE NEUER BLOCK ---

echo "✓ Installation completed"
echo "✓ Enhanced (v4) security filters enabled"
echo "✓ Logs stored in: $LOG_DIR"
echo "✓ Only you can see your commands"
echo "✓ PROMPT_COMMAND conflict protection enabled"
echo "✓ fzf TUI support enabled (install 'fzf' for best experience)"
echo "✓ Restart your terminal or run: source ~/.bashrc"
echo "✓ Run 'lcm' to view your logs"
