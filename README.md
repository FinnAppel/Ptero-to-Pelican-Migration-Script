# Pterodactyl to Pelican Panel Migration Script

This repository contains a migration script to help users transition from **Pterodactyl Panel** to **Pelican Panel**. The script is designed to simplify the migration process by automating key tasks while ensuring a backup of your existing Pterodactyl installation.

> **Warning:** The migration script is in its **beta phase**, and **Pelican Panel** is also in its early development stages. Use this script at your own risk.


## Features
- Automatically migrates your Pterodactyl setup to Pelican Panel.
- Creates a **backup** of your current Pterodactyl installation to allow recovery in case of issues.
- Streamlined migration process to get you up and running with Pelican Panel quickly.


## Prerequisites
1. A working Pterodactyl installation.
2. Administrative access to your server.
3. Basic knowledge of server management.


## Installation

```bash
curl -sSL https://raw.githubusercontent.com/FinnAppel/Ptero-to-Pelican-Migration-Script/main/migrate.sh | sudo bash
```

## Important Notes
- **Backup Creation**: The script will create a full backup of your existing Pterodactyl installation. The backup will be stored in a `backups` directory within the same folder as the script.
- **Beta Status**: Both the script and Pelican Panel are in their early stages of development. Bugs and issues may occur.
- **Liability**: I am not responsible for any damage or data loss that may occur during or after the migration process. Use at your own risk.


## Contribution
Contributions to improve this script are welcome! Feel free to fork the repository, make changes, and submit a pull request.


## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Disclaimer
This script is provided "as is" without any warranties. Use at your own risk.
