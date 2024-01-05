# cbftp-updater

[![GitHub](https://img.shields.io/github/license/ZarTek-Creole/cbftp-updater)](https://github.com/ZarTek-Creole/cbftp-updater)
[![Bash](https://img.shields.io/badge/Language-Bash-blue)](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen)](https://github.com/ZarTek-Creole/cbftp-updater/releases)
[![Issues](https://img.shields.io/github/issues/ZarTek-Creole/cbftp-updater)](https://github.com/ZarTek-Creole/cbftp-updater/issues)
[![Contributors](https://img.shields.io/github/contributors/ZarTek-Creole/cbftp-updater)](https://github.com/ZarTek-Creole/cbftp-updater/graphs/contributors)
[![Last Commit](https://img.shields.io/github/last-commit/ZarTek-Creole/cbftp-updater)](https://github.com/ZarTek-Creole/cbftp-updater/commits/main)


## Table of Contents

- [Description](#description)
- [Donation](#donation)
- [Author](#author)
- [Repository](#repository)
- [Support](#support)
- [Configuration](#configuration)
- [Usage](#usage)
- [Automating Updates with Cron](#automating-updates-with-cron)
- [Creating a CBFTP Service](#creating-a-cbftp-service)
- [Attaching to the CBFTP Screen Session](#attaching-to-the-cbftp-screen-session)
- [Acknowledgments](#acknowledgments)

## Description

"cbftp-updater.sh" is a Bash script designed for the management and automatic updating of cbftp via Subversion (SVN). It simplifies the task of keeping your cbftp installation up to date with an efficient script.

## Donation

If you find this script useful and want to support its development, consider making a donation [here](https://github.com/ZarTek-Creole/DONATE).

## Author

- ZarTek
- GitHub: [ZarTek-Creole](https://github.com/ZarTek-Creole)

## Repository

GitHub Repository: [cbftp-updater](https://github.com/ZarTek-Creole/cbftp-updater)

## Support

For any issues, questions, or suggestions related to this script, please visit the [GitHub Issues](https://github.com/ZarTek-Creole/cbftp-updater/issues) page.

## Configuration

Before using the script, please make sure to configure the following variables in the script:

```bash
CBUSER=your_user
CBSERVICE=cbftp.service
CBDIRSRC="/path/to/source/directory"
CBDIRDEST="/path/to/destination/directory"
SVN_URL="https://cbftp.glftpd.io/svn"
```

- `CBUSER`: The user for cbftp.
- `CBSERVICE`: The service name for cbftp.
- `CBDIRSRC`: The source directory path for cbftp.
- `CBDIRDEST`: The destination directory path for cbftp.
- `SVN_URL`: The SVN repository URL for cbftp.

## Usage

1. Clone this repository:

   ```bash
   git clone https://github.com/ZarTek-Creole/cbftp-updater.git
   ```

2. Navigate to the cloned directory:

   ```bash
   cd cbftp-updater
   ```

3. Make the script executable:

   ```bash
   chmod +x cbftp-updater.sh
   ```

4. Edit the script to configure the variables mentioned in the "Configuration" section.

5. Run the script:

   ```bash
   ./cbftp-updater.sh
   ```

The script will manage and update your cbftp installation as needed.

## Automating Updates with Cron

To automate the execution of this script once a week, you can use the cron scheduling feature in your Linux Debian system. Here's how to set it up:

1. Open a terminal on your Debian system.

2. To edit the cron table for the current user, type the following command:

   ```bash
   crontab -e
   ```

   This will open the default text editor to edit your user's cron table.

3. Add the following line to schedule the script to run once a week:

   ```bash
   0 0 * * 0 /path/to/your/script/cbftp-updater.sh
   ```

   This line schedules the script to run at midnight (00:00) every Sunday (day of the week 0). Replace "/path/to/your/script" with the full path to the directory where your "cbftp-updater.sh" script is located.

4. Save and close the text editor.

5. The cron is now configured to run your script once a week, automatically keeping your cbftp installation up to date.

Make sure your script is still executable with the `chmod +x cbftp-updater.sh` command so that it can be executed by the cron. You can customize the schedule by adjusting the values in the cron line according to your needs.

## Creating a CBFTP Service

To create a systemd service for cbftp, you can use the following service unit file. Save it as `cbftp.service` in the `/etc/systemd/system/` directory:

```ini
[Unit]
Description=CBFTP Service
After=network.target

[Service]
Type=oneshot
WorkingDirectory=/path/to/destination/directory/cbftp
ExecStart=/usr/bin/screen -dmS cbftp /path/to/destination/directory/cbftp/cbftp
ExecStop=/usr/bin/screen -S cbftp -X quit
RemainAfterExit=yes
User=your_user
Group=your_user
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Once you've saved the unit file, run the following commands to enable and start the CBFTP service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cbftp.service
sudo systemctl start cbftp.service
```

This will create and start the CBFTP service, ensuring it runs on system startup.

## Attaching to the CBFTP Screen Session

To attach to the CBFTP screen session as a specific user, use the following command:

```bash
su your_user -c 'screen -x cbftp'
```

Replace `your_user` with the actual user you want to use to attach to the screen session.

## Acknowledgments

Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene.
Special thanks to all the contributors and users of cbftp-updater for their support and contributions to the project.

## Official CBFTP Website

For more information about cbftp, please visit the [official CBFTP website](https://cbftp.glftpd.io/).
