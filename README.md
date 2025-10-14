# LCM - Linux Command Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)

**Lightweight command monitoring and audit logging for Linux servers**

LCM automatically logs all bash commands executed by users with built-in security filters to protect sensitive data like passwords and API keys.

## Features

✅ **Automatic Command Logging** - Captures every bash command with timestamp, user, and working directory  
🔒 **Security Filters** - Automatically redacts passwords, tokens, and secrets (5 essential patterns)  
📊 **Easy Dashboard** - Simple commands to view, search, and analyze command history  
🪶 **Lightweight** - Pure bash script, no external dependencies  
🔄 **Log Rotation** - Built-in 90-day log rotation  
💻 **VSCode Support** - Works with both terminal and VSCode integrated shells

## Quick Start

### Installation

```bash
# 1. Download the script
sudo curl -o /opt/lcm.sh https://raw.githubusercontent.com/ferbasag/LCM/main/lcm.sh

# OR clone the repository
git clone https://github.com/ferbasag/LCM.git
sudo cp LCM/lcm.sh /opt/lcm.sh

# 2. Make it executable
sudo chmod +x /opt/lcm.sh

# 3. Install
sudo /opt/lcm.sh

# 4. Restart your terminal
exit
```

Log back in and you're ready!

## Usage

### Basic Commands

```bash
lcm                    # 📊 Dashboard - Last 50 commands
lcm-all                # 📝 All commands (last 1000)
lcm-user <username>    # 👤 Commands by specific user
lcm-today              # 📅 Today's commands
lcm-search <term>      # 🔍 Search for specific term
```

### Example Output

```
=== COMMAND MONITORING DASHBOARD ===
Server: webserver01 | 2025-10-14 15:30:45

Currently Logged In Users:
root     pts/0    2025-10-14 15:00

Last 50 Commands:
2025-10-14 15:30:42 | root         | apt update
2025-10-14 15:31:15 | deploy       | docker ps -a
2025-10-14 15:32:08 | root         | systemctl restart nginx

Commands: lcm-all, lcm-user <user>, lcm-today, lcm-search <term>
```

## Security Features

LCM automatically filters sensitive data from logs with **5 essential patterns**:

| Pattern | Example | Logged As |
|---------|---------|-----------|
| MySQL passwords (quoted) | `mysql -p'Secret123'` | `mysql -p\*\*\*FILTERED\*\*\*` |
| MySQL passwords (direct) | `mysql -pSecret123` | `mysql -p\*\*\*FILTERED\*\*\*` |
| Password flags | `--password=secret` | `--password=\*\*\*FILTERED\*\*\*` |
| URL credentials | `https://user:pass@host` | `https://\*\*\*FILTERED\*\*\*@host` |
| Environment variables | `export API_KEY=xyz` | `export API_KEY=\*\*\*FILTERED\*\*\*` |

These filters cover **90% of common password scenarios** while keeping the tool lightweight.

## Optional: Login Message

Show available commands on every login:

```bash
# Create MOTD file
sudo nano /etc/update-motd.d/10-help-text
```

Paste this content:

```bash
#!/bin/sh
printf "\n"
printf " Server Monitoring:\n"
printf " 📊 lcm         - Dashboard\n"
printf " 📝 lcm-all     - All Commands\n"
printf " 👤 lcm-user    - User Commands\n"
printf " 📅 lcm-today   - Today's Commands\n"
printf " 🔍 lcm-search  - Search Commands\n"
printf "\n"
```

Make it executable:

```bash
sudo chmod +x /etc/update-motd.d/10-help-text
```

## How It Works

1. **Logging Script**: Installs to `/etc/profile.d/command_logging.sh`
2. **Hook Mechanism**: Uses bash's `PROMPT_COMMAND` to capture commands after execution
3. **Log Storage**: Saves to `/var/log/bash_commands/<username>_commands.log`
4. **Format**: `TIMESTAMP | USERNAME | DIRECTORY | COMMAND`
5. **Rotation**: Logs are automatically rotated daily, kept for 90 days

## Log Files

- **Location**: `/var/log/bash_commands/`
- **Format**: `<username>_commands.log`
- **Permissions**: `666` (readable by all users)
- **Rotation**: Daily, compressed after 1 day, deleted after 90 days

## Requirements

- Linux with Bash 4.0+
- Root access for installation
- Systemd-based system (for logrotate)

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
# Remove files
sudo rm /etc/profile.d/command_logging.sh
sudo rm /etc/logrotate.d/bash-command-logs
sudo rm -rf /var/log/bash_commands

# Remove functions from bashrc
sudo nano /etc/bash.bashrc
# Delete the "# Load command logging" and "# Command Monitoring Functions" sections

# Restart terminal
exit
```

## Use Cases

- **Security Auditing**: Track all commands on production servers
- **Compliance**: Meet audit trail requirements
- **Debugging**: See what commands were run before an issue occurred
- **Team Collaboration**: Understand what teammates are doing on shared servers
- **Training**: Review commands for learning purposes

## Privacy & Legal

⚠️ **Important**: 
- This tool logs ALL user commands on the system
- Users should be informed that command logging is active
- Ensure compliance with your organization's privacy policies
- Use only on systems you own or are authorized to monitor

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Author

@ferbasag
Created for lightweight server monitoring and audit logging.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions

---

**Note**: Always test in a non-production environment first!
