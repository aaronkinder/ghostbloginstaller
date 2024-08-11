#!/bin/bash
# ghost-install.sh
# https://tomssl.com/the-best-way-to-install-ghost-on-your-server
# Updated for Ubuntu 24.04 with improved sudo permissions
# curl -L -s https://raw.githubusercontent.com/aaronkinder/ghostbloginstaller/main/ghost-install.sh | sudo -E bash

export NCURSES_NO_UTF8_ACS=1

function ensure_package_installed() {
    # Function implementation remains the same
    # ...
}

function input_box() {
    # Function implementation remains the same
    # ...
}

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try again with sudo."
    exit 1
fi

sudo apt-get update &>/dev/null
ensure_package_installed "dialog" "Dialog"

DEFAULT_GHOSTUSER=ghost
DEFAULT_SITEDIRECTORY=ghostblog

input_box "Set Ghost Username" \
"We need to create a user for Ghost
\n\nWe suggest $DEFAULT_GHOSTUSER, but it's up to you.
\n\nGhost Username:" \
"$DEFAULT_GHOSTUSER" \
GHOSTUSER

if [ -z "$GHOSTUSER" ]; then
    # user hit ESC/cancel
    exit
fi

input_box "Set Ghost Blog Directory" \
"Now it's time to create a directory inside /var/www/ to install \
your first Ghost blog.
\n\nI have suggested $DEFAULT_SITEDIRECTORY, but you should probably change that.
\n\nBlog Directory (inside /var/www/):" \
"$DEFAULT_SITEDIRECTORY" \
SITEDIRECTORY

if [ -z "$SITEDIRECTORY" ]; then
    # user hit ESC/cancel
    exit
fi

(
    sleep 0.5
    echo "XXX"
    echo 1
    echo "Adding $GHOSTUSER user..."
    echo "XXX"
    sleep 0.5
    sudo useradd --system --user-group $GHOSTUSER
    echo "XXX"
    echo 3
    echo "Modifying permissions of $GHOSTUSER..."
    echo "XXX"
    sleep 0.5
    # Add $GHOSTUSER to sudoers file with NOPASSWD option for all commands
    echo "$GHOSTUSER ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo
    echo "XXX"
    echo 5
    echo "Permissions modified"
    echo "XXX"
    sleep 0.5
    ensure_package_installed "nginx" "Nginx" "10" "15" result
    ensure_package_installed "ufw" "ufw [Firewall]" "16" "20" result
    echo "XXX"
    echo 21
    echo "Configuring ufw..."
    echo "XXX"
    sudo ufw default deny incoming >/dev/null &&
        sudo ufw default allow outgoing >/dev/null &&
        sudo ufw allow ssh >/dev/null &&
        sudo ufw allow 'Nginx Full' >/dev/null
    yes | sudo ufw enable >/dev/null || exit 1
    echo "XXX"
    echo 30
    echo "XXX"
    ensure_package_installed "mysql-server" "MySQL" "31" "40" result
    if [ $result -eq 1 ]; then
        # We just installed mysql-server, so we should set the root password
        data="something"
        until [ "$data" = "$data2" ]; do
            data=$(dialog --title "Set MySQL root password" --insecure --passwordbox "Please enter a password for the mysql root user. You will need this password when you install each of your Ghost blogs." 10 60 3>&1- 1>&2- 2>&3-)
            data2=$(dialog --title "Set MySQL root password" --insecure --passwordbox "Please re-enter your password." 10 60 3>&1- 1>&2- 2>&3-)
        done
        sql="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$data';FLUSH PRIVILEGES;"
        sudo mysql -u root -e "$sql" >/dev/null
    fi
) | dialog --title "Installing Ghost..." --gauge "Installing required packages..." 10 60 0

(
    echo "XXX"
    echo 51
    echo "Installing Node.js v18.x source repo"
    echo "XXX"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - &>/dev/null
    ensure_package_installed "nodejs" "Node.js" "65" "75" result
    echo "Ensuring latest Ghost-CLI installed..."
    echo "XXX"
    sudo npm install ghost-cli@latest -g --quiet --no-progress &>/dev/null
    echo "XXX"
    echo 95
    echo "Creating directory /var/www/$SITEDIRECTORY and setting permissions"
    echo "XXX"
    sudo mkdir -p /var/www/$SITEDIRECTORY
    sudo chown $GHOSTUSER:$GHOSTUSER /var/www/$SITEDIRECTORY
    sudo chmod 775 /var/www/$SITEDIRECTORY
    echo "XXX"
    echo 100
    echo "Installation complete. To finish setting up Ghost, run:
sudo -u $GHOSTUSER -i
cd /var/www/$SITEDIRECTORY
ghost install"
    echo "XXX"
) | dialog --title "Installing Ghost..." --gauge "Installing required packages..." 10 60 50

echo "Ghost installation preparation complete. Please follow the final steps displayed above to complete the installation."
