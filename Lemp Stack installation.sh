#!/bin/bash

# Set your domain and web root directory
domain="lemp.addressholding"
web_root="/var/www/$domain"

# Update package lists
echo "Updating packages..."
sudo apt update

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx
sudo ufw allow 'Nginx HTTP'  # Allow HTTP traffic through the firewall

# Install MySQL Server
echo "Installing MySQL..."
sudo apt install -y mysql-server
sudo mysql_secure_installation  

# Install PHP and required modules
echo "Installing PHP..."
sudo apt install -y php-fpm php-mysql

# Create web root directory and set permissions
sudo mkdir -p "$web_root"
sudo chmod -R 755 "$web_root"

# test PHP setup
echo "<?php phpinfo(); ?>" | sudo tee "$web_root/index.php"

# Create Nginx server block config
config_file="/etc/nginx/sites-available/$domain"

sudo tee "$config_file" > /dev/null << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root $web_root;

    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock; # Adjust PHP version if needed
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Enable the new site and disable default
sudo ln -s "/etc/nginx/sites-available/$domain" /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default

# Test and reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# Download and set up WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz
sudo mv wordpress/* "$web_root/"
sudo chown -R www-data:www-data "$web_root"

# Success message
echo "LEMP Stack with WordPress is successfully set up at http://$domain"
