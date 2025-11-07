# LCM - Linux Command Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)

**Lightweight personal command monitoring and audit logging for Linux**

LCM automatically logs all your bash commands with built-in security filters to protect sensitive data like passwords and API keys. Each user installs LCM individually and can only see their own command history.

## Features

✅ **Personal Command Logging** - Captures every bash command with timestamp and working directory
🔒 **Security Filters** - Automatically redacts passwords, tokens, and secrets (5 essential patterns)
🔐 **Privacy First** - Only you can see your own commands (chmod 600)
📊 **Easy Dashboard** - Simple commands to view, search, and analyze your command history
🪶 **Lightweight** - Pure bash script, no external dependencies
💻 **VSCode Support** - Works with both terminal and VSCode integrated shells
🚫 **No sudo required** - Installs in your home directory

## Quick Start

### Installation

```bash
# 1. Download the script
curl -o lcm.sh https://raw.githubusercontent.com/ferbasag/LCM/main/lcm.sh

# OR clone the repository
git clone https://github.com/ferbasag/LCM.git
cd LCM

# 2. Make it executable
chmod +x lcm.sh

# 3. Install (no sudo needed!)
./lcm.sh

# 4. Reload your bashrc
source ~/.bashrc
```

You're ready! Every user who wants to use LCM must install it individually.

## Usage

### Basic Commands

```bash
lcm                    # 📊 Dashboard - Your last 50 commands
lcm-all                # 📝 All your commands (last 1000)
lcm-today              # 📅 Today's commands
lcm-search <term>      # 🔍 Search for specific term in your history
```

### Example Output

```
=== COMMAND MONITORING DASHBOARD ===
User: john | 2025-11-07 15:30:45

Last 50 Commands:
2025-11-07 15:30:42 | apt update
2025-11-07 15:31:15 | docker ps -a
2025-11-07 15:32:08 | git status

Commands: lcm-all, lcm-today, lcm-search <term>
```

## Security Features

LCM automatically filters sensitive data from logs with **5 essential patterns**:

| Pattern | Example | Logged As |
|---------|---------|-----------|
| MySQL passwords (quoted) | `mysql -p'Secret123'` | `mysql -p***FILTERED***` |
| MySQL passwords (direct) | `mysql -pSecret123` | `mysql -p***FILTERED***` |
| Password flags | `--password=secret` | `--password=***FILTERED***` |
| URL credentials | `https://user:pass@host` | `https://***FILTERED***@host` |
| Environment variables | `export API_KEY=xyz` | `export API_KEY=***FILTERED***` |

These filters cover **90% of common password scenarios** while keeping the tool lightweight.

## How It Works

1. **Logging Script**: Installs to `~/.lcm/command_logging.sh` in your home directory
2. **Hook Mechanism**: Uses bash's `PROMPT_COMMAND` to capture commands after execution
3. **Log Storage**: Saves to `~/.lcm/logs/$(whoami)_commands.log`
4. **Format**: `TIMESTAMP | USERNAME | DIRECTORY | COMMAND`
5. **Privacy**: Log files have permissions `600` (only you can read them)

## Log Files

- **Location**: `~/.lcm/logs/` in your home directory
- **Format**: `<username>_commands.log`
- **Permissions**: `600` (only you can read/write)
- **Personal**: Each user has their own isolated logs

## Requirements

- Linux with Bash 4.0+
- No root access needed
- Works on any Linux system

## Compatibility

Tested on:
- Ubuntu 18.04, 20.04, 22.04, 24.04
- Debian 10, 11, 12
- CentOS 7, 8
- Rocky Linux 8, 9

Works with:
- Standard terminal (SSH, local)
- VSCode integrated terminal
- tmux / screen sessions

## Uninstallation

```bash
# Remove LCM directory
rm -rf ~/.lcm

# Remove from bashrc
nano ~/.bashrc
# Delete the "# LCM Command Logging" and "# LCM Monitoring Functions" sections

# Restart terminal
exit
```

## Use Cases

- **Personal Audit Trail**: Keep track of your own command history
- **Learning**: Review commands you've used to remember workflows
- **Debugging**: See what commands you ran before an issue occurred
- **Security**: Monitor your own activity and detect suspicious commands
- **Documentation**: Export your workflow for documentation purposes

## Privacy & Legal

✅ **Personal Use**:
- Each user controls their own logs
- No system-wide monitoring
- Only you can see your commands
- Logs stored in your home directory with private permissions (600)

⚠️ **Important**:
- Use only on systems you own or are authorized to use
- The tool logs YOUR commands for YOUR reference
- Ensure compliance with your organization's policies

## Multi-User Environments

In shared environments:
- Each user must install LCM individually
- Users cannot see each other's commands
- No special privileges required
- Perfect for personal productivity tracking

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Author

[ferbasag](https://github.com/ferbasag) – Created for lightweight personal command monitoring.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions

---

**Note**: LCM is designed for personal use. Each user manages their own installation and logs independently.
