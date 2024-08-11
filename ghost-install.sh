#!/bin/bash
# ghost-install.sh
# https://tomssl.com/the-best-way-to-install-ghost-on-your-server
# Updated for Ubuntu 24.04 and to fix directory creation, sudo permission issues, and syntax errors
# curl -L -s https://raw.githubusercontent.com/aaronkinder/ghostbloginstaller/main/ghost-install.sh | sudo -E bash

export NCURSES_NO_UTF8_ACS=1

function ensure_package_installed() {
    # $1 is package name, $2 Package description, $3 Start Percentage, $4 End Percentage
    # $5 Exit Code # 0 means package was already installed, 1 means this function installed it.
    local __resultvar=$5
    local myresult='0'
    if dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -q "ok installed"; then
        if [ ! -t 1 ]; then
            echo "XXX"
            echo $4
        fi
        echo "$2 ($1) is already installed"
        if [ ! -t 1 ]; then echo "XXX"; fi
    else
        if [ ! -t 1 ]; then
            echo "XXX"
            echo $3
        fi
        echo Installing $2...
        if [ ! -t 1 ]; then echo "XXX"; fi
        sudo apt-get install -y $1 &>/dev/null || exit 1
        echo $4
        local myresult=1
    fi
    eval $__resultvar="'$myresult'" # 0 = package was already installed. 1 = package installed in here.
}

function input_box() {
    # $1 is Title, $2 Prompt, $3 Default Value, $4 VARIABLE
    declare -n result=$4
    declare -n result_code=$4_EXITCODE
    set +e
    result=$(dialog --stdout --title "$1" --inputbox "$2" 0 0 "$3")
    result_code=$?
    set -e
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
su - $GHOSTUSER
cd /var/www/$SITEDIRECTORY
ghost install"
    echo "XXX"
) | dialog --title "Installing Ghost..." --gauge "Installing required packages..." 10 60 50

echo "Ghost installation preparation complete. Please follow the final steps displayed above to complete the installation."
