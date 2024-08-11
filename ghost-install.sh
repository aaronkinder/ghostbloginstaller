#!/bin/bash
# Simplified Ghost installation script for Ubuntu 24.04

set -e

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try again with sudo."
    exit 1
fi

# Update package list
apt-get update

# Install required packages
apt-get install -y nginx mysql-server nodejs npm

# Create Ghost user
useradd --system --user-group ghost

# Set up Ghost directory
mkdir -p /var/www/ghost
chown ghost:ghost /var/www/ghost
chmod 775 /var/www/ghost

# Install Ghost-CLI
npm install ghost-cli@latest -g

# Set up MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password'; FLUSH PRIVILEGES;"

# Add Ghost user to sudoers
echo "ghost ALL=(ALL) NOPASSWD: ALL" | EDITOR='tee -a' visudo

# Print instructions
echo "Ghost installation preparation complete."
echo "To finish setting up Ghost, run:"
echo "sudo -u ghost -i"
echo "cd /var/www/ghost"
echo "ghost install"

echo "After installation, remember to secure your MySQL installation and restrict Ghost user permissions."
