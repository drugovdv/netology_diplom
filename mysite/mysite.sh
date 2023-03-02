#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo cp -R ~/netology_diplom/mysite/My_site /var/www/
sudo rm -rf /etc/nginx/sites-available/default
sudo rm -rf /etc/nginx/sites-enabled/default
sudo cp ~/netology_diplom/mysite/my_nginx.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/my_nginx.conf /etc/nginx/sites-enabled/my_nginx.conf
sudo mkdir /var/log/nginx/mysite/
sudo rm -rf /etc/nginx/nginx.conf
sudo cp ~/netology_diplom/mysite/nginx.conf /etc/nginx/
sudo systemctl enable nginx
sudo systemctl restart nginx
