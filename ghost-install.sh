#!/bin/bash
# ghost-install.sh
# https://tomssl.com/the-best-way-to-install-ghost-on-your-server
# Updated for Ubuntu 24.04 and to fix directory creation and sudo permission issues
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

DEFAULT_GHOSTUSER=ghostuser
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
    adduser --disabled-password --gecos "" $GHOSTUSER &>/dev/null &&
        echo "User $GHOSTUSER added. To set password, run 'sudo passwd $GHOSTUSER'"
    sleep 1
    echo "XXX"
    echo 3
    echo "Modifying permissions of $GHOSTUSER..."
    echo "XXX"
    sleep 0.5
    usermod -aG sudo $GHOSTUSER || echo "Couldn't modify user"
    # Add $GHOSTUSER to sudoers file with NOPASSWD option for specific commands
    echo "$GHOSTUSER ALL=(ALL) NOPASSWD: /usr/bin/node, /usr/bin/npm, /usr/bin/ghost, /usr/sbin/nginx, /usr/sbin/service nginx start, /usr/sbin/service nginx stop, /usr/sbin/service nginx restart" | sudo EDITOR='tee -a' visudo
    echo "XXX"
    echo 5
    echo "Permissions modified"
    echo "XXX"
    sleep 0.5
    
    # Rest of the installation process remains the same
    # ...

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
su - $GHOSTUSER
cd /var/www/$SITEDIRECTORY
ghost install"
    echo "XXX"
) | dialog --title "Installing Ghost..." --gauge "Installing required packages..." 10 60 50

echo "Ghost installation preparation complete. Please follow the final steps displayed above to complete the installation."
