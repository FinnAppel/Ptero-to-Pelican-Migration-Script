#!/bin/sh


PTERODACTYL_DIR="/var/www/pterodactyl"

PELICAN_DIR="/var/www/pelican"

env_file="/var/www/pterodactyl/.env"

cd "$PTERODACTYL_DIR"

# Detect operating system
OS="$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '\"')"

export DEBIAN_FRONTEND=noninteractive

# Show script startup
echo     
echo     
echo "======================================"
echo "    Pelican Migration Script"
echo "    Your OS: $OS"
echo "    Checking if your OS is supported."
echo "======================================"
echo 
sleep 2


    if [ -d "$PELICAN_DIR" ]; then
      echo "Pelican is already detected at $PELICAN_DIR. Migration cannot continue."
      exit 1
    fi

db_connection=$(grep "^DB_CONNECTION=" "$env_file" | cut -d '=' -f 2)

if [ -z "$db_connection" ]; then
  echo "DB_CONNECTION not found in $env_file."
  exit 0
else
  echo "DB_CONNECTION is set to: $db_connection"

  backup_dir="/var/www/backup"
  mkdir -p "$backup_dir"

  if [ "$db_connection" = "sqlite" ]; then
    db_database=$(grep "^DB_DATABASE=" "$env_file" | cut -d '=' -f 2)

    if [ -z "$db_database" ]; then
      echo "DB_DATABASE not found in $env_file."
      exit 1
    else
      echo "DB_DATABASE is set to: $db_database"
      cp "$install_dir/database/$db_database" "$backup_dir/$db_database.backup"
    fi

  elif [ "$db_connection" = "mysql" ]; then
    read -p "This will now migrate Pterodactyl to Pelican. Use at your own risk. Do you want to continue? (y/n) [y]: " continue_confirm
continue_confirm=${continue_confirm:-y}
  if [ "$continue_confirm" != "y" ]; then
    echo "Migration Canceled."
    exit 0
  fi
  fi

  cp "$env_file" "$backup_dir/.env.backup"
fi


IS_DEBIAN=$(lsb_release -a 2>/dev/null | grep -i "debian" > /dev/null && echo "yes" || echo "no")
if [[ "$OS" == "Ubuntu"* || "$OS" == "Debian"* ]]; then
    WEBSERVER_USER="www-data"
    WEBSERVER_GROUP="www-data"
elif [[ "$OS" == "CentOS"* ]]; then
    if systemctl is-active --quiet nginx; then
        WEBSERVER_USER="nginx"
        WEBSERVER_GROUP="nginx"
        sleep 2
    elif systemctl is-active --quiet httpd; then
        WEBSERVER_USER="apache"
        WEBSERVER_GROUP="apache"
        sleep 2
    else
        echo "Unsupported OS detected. Exiting."
        exit 1
    fi
else
    echo "Unsupported OS detected. Exiting."
    exit 1
fi

sleep 2
# Stopping services to start migration process
echo "Shutting down services"
php artisan down
systemctl stop wings
systemctl stop nginx

find "$PTERODACTYL_DIR" -mindepth 1 -maxdepth 1 ! -name 'backup' -exec rm -rf {} +

echo "Starting migration."
sleep 2

# Backing up .env file
cp "$env_file" "$backup_dir/.env.backup"
mv /var/www/pterodactyl /var/www/pelican


echo "Downloading Files..."
sleep 2
curl -L https://github.com/pelican-dev/panel/releases/download/v1.0.0-beta17/panel.tar.gz | sudo tar -xzv -C "$PELICAN_DIR"

echo "Setting Permissions"
sleep 2
cd "$PELICAN_DIR"
chmod -R 755 /var/www/pelican/storage/* /var/www/pelican/bootstrap/cache
chown -R www-data:www-data /var/www/pelican


# Adding PHP 8.3
echo "Adding more dependencies"
sleep 1
apt update
apt install php8.3-intl php8.3-sqlite3
systemctl stop php8.3-fpm

echo "Installing Composer"
sleep 2

# Install dependencies with Composer
if [[ "$IS_DEBIAN" == "yes" ]]; then
    # Use su for Debian
    su -s /bin/bash -c "COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader"
else
    # Use sudo for other systems
    sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
fi


# Step 10: Restore the .env file and database
echo "Restoring .env"
sleep 1
mv "$backup_dir/.env.backup" "$PELICAN_DIR/.env"
if [ "$db_connection" = "sqlite" ]; then
  echo "Restoring sqlite database"
  sleep 2
  mv "$backup_dir/$db_database.backup" "$PELICAN_DIR/database/$db_database"
fi

echo "Optimizing Filament"
sleep 1
php artisan filament:optimize

echo "Updating database"
sleep 1
php artisan migrate --seed --force
php artisan make:migration add_deleted_at_to_webhook_configurations_table --table=webhook_configurations
php artisan migrate --seed --force

# Set ownership of files to the web server user and group
echo "Setting ownership of the web server"
sleep 1
chown -R "$WEBSERVER_USER":"$WEBSERVER_GROUP" /var/www/pelican/*

# Unlink the existing symbolic link for pterodactyl.conf
echo "Unlink symbolic link"
sleep 1
sudo unlink /etc/nginx/sites-enabled/pterodactyl.conf

# Rename pterodactyl.conf to pelican.conf
echo "Renaming Nginx conf"
sleep 1
sudo mv /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-available/pelican.conf

# Replace all occurrences of 'pterodactyl' with 'pelican' in pelican.conf
echo "Replacing pterodactyl with pelican"
sleep 1
sudo sed -i 's/pterodactyl/pelican/g' /etc/nginx/sites-available/pelican.conf

# Create a new symbolic link for pelican.conf
echo "Creating new symbolic link"
sleep 1
sudo ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf

# Start services after migration
echo "Starting services"
sleep 1
sudo systemctl start nginx
systemctl start php8.3-fpm
systemctl start wings
php artisan queue:restart
php artisan up

echo " "
echo "Migration from Pterodactyl to Pelican has been completed."
echo "If this was helpful consider leaving a star on my GitHub repository."
echo "If you get a database error when creating one, go to your admin settings and link your database to your node."
exit 0

