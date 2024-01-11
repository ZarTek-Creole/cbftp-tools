# cbftp-tools 🚀

## Introduction 📌

`cbftp-tools` is a Bash script designed to streamline the management and automatic updating of the cbftp installation via Subversion (SVN). It offers an efficient solution for keeping your cbftp installation up to date with ease. This tool is tested on Debian 12 and Ubuntu 22.04.

## Table of Contents 📚

- [Installation](#installation) 🛠️
- [Usage](#usage) 💻
- [Features](#features) ✨
- [Examples](#examples) 📝
- [Dependencies](#dependencies) 📦
- [Configuration](#configuration) ⚙️
- [Troubleshooting](#troubleshooting) 🔍
- [Contributing](#contributing) 🤝
- [Contributors](#contributors) 👥
- [License](#license) 📜
- [Acknowledgements](#acknowledgements) 🙏
- [Official CBFTP Website](#official-cbftp-website) 🔗
- [Donation](#donation) 💖
- [Author](#author) 👤
- [Repository](#repository) 📁
- [Support](#support) 🆘
- [Contact](#contact) 📞

## Installation 🛠️

```bash
curl -s https://raw.githubusercontent.com/ZarTek-Creole/cbftp-tools/master/cbftp-tools_install.sh | bash -s -- --install
```

## Usage 💻

```bash
sudo cbftp-tools [command]
```

Commands include:
- `--help`
- `--install`
- `--uninstall`
- `--reinstall`
- `--update`

Subcommands for managing `cbftp` and related services like `crontab`, `init.d`, and `systemd` are available.

## Features ✨

- **cbftp Binary Management**: Install, uninstall, and update the cbftp binary.
- **Service Management**: Handle `cbftp` services using `init.d` or `systemd`.
- **Crontab Integration**: Automate updates through a crontab script.

## Examples 📝

### Installing cbftp
```bash
cbftp-tools cbftp -i
```

### Updating cbftp-tools
```bash
cbftp-tools --update
```

### Reinstalling cbftp
```bash
cbftp-tools cbftp --reinstall
```

### Updating cbftp
```bash
cbftp-tools cbftp --update
Starting cbftp update.
Updating cbftp from revision 1244 to 1246.
Updating '.':
A    src/ui/siteselection.cpp
A    src/ui/siteselection.h
U    src/ui/ui.h
U    src/ui/ui.cpp
U    src/ui/screens/alltransferjobsscreen.h
U    src/ui/screens/sitestatusscreen.cpp
A    src/ui/screens/transferjobsfilterscreen.cpp
U    src/ui/screens/mainscreen.cpp
U    src/ui/screens/allracesscreen.cpp
U    src/ui/screens/alltransferjobsscreen.cpp
U    src/ui/screens/transfersscreen.h
A    src/ui/screens/transferjobsfilterscreen.h
U    src/ui/screens/transfersfilterscreen.cpp
U    src/ui/screens/browsescreensite.h
U    src/ui/screens/allracesscreen.h
A    src/ui/screens/spreadjobsfilterscreen.cpp
U    src/ui/screens/transfersscreen.cpp
A    src/ui/screens/spreadjobsfilterscreen.h
U    src/transfermonitor.cpp
Updated to revision 1246.
Changing to directory: /usr/local/src/cbftp
Building cbftp...
Stopping cbftp_zartek.service service...
cbftp_zartek.service service stopped successfully.
No init.d service starting with cbftp* was found.
Deploying new cbftp binary...
cbftp deployed.
Starting cbftp_zartek.service service...
cbftp_zartek.service service started successfully.
Latest changes:
r1246 2024-01-08 - fixed how local and in-memory transfers are displayed in
                   transfers/transferstatus
cbftp update completed successfully.
```

## Dependencies 📦

```bash
sudo apt-get install subversion git build-essential screen libxml2-utils curl
```

## Configuration ⚙️

Configuration details for individual scripts are included within each script.

## Troubleshooting 🔍

For common issues and their solutions, please refer to the [GitHub Issues page](https://github.com/ZarTek-Creole/cbftp-tools/issues).

## Contributing 🤝

Contributions are welcome! Please submit pull requests on GitHub. For specific guidelines, refer to the [CONTRIBUTING.md](https://github.com/ZarTek-Creole/cbftp-tools/CONTRIBUTING.md) file in the repository.

## Contributors 👥

Authored by ZarTek. Additional contributions are listed on the GitHub repository.

## License 📜

The project is licensed under [LICENSE](https://github.com/ZarTek-Creole/cbftp-tools/LICENSE). Please refer to the link for the full text.

## Acknowledgements 🙏

Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene.

## Official CBFTP Website 🔗

For more information, visit [cbftp.glftpd.io](https://cbftp.glftpd.io/).

## Donation 💖

If you find this script useful and want to support its development, consider making a donation [here](https://github.com/ZarTek-Creole/DONATE).

## Author 👤

- ZarTek
- GitHub: [ZarTek-Creole](https://github.com/ZarTek-Creole)

## Repository 📁

GitHub Repository: [cbftp-tools](https://github.com/ZarTek-Creole/cbftp-tools)

## Support 🆘

For any issues, questions, or suggestions related to this script, please visit the [GitHub Issues](https://github.com/ZarTek-Creole/cbftp-tools/issues) page.

## Contact 📞

For support or inquiries, please use the [GitHub Issues page](https://github.com/ZarTek-Creole/cbftp-tools/issues) or the contact method specified on the [official CBFTP website](https://cbftp.glftpd.io/).