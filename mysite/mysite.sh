#!/bin/bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo cp -R /home/admin/netology_diplom-main/mysite/My_site /var/www/
sudo rm -rf /etc/nginx/sites-available/default
sudo rm -rf /etc/nginx/sites-enabled/default
sudo cp /home/admin/netology_diplom-main/mysite/my_nginx.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/my_nginx.conf /etc/nginx/sites-enabled/my_nginx.conf
sudo mkdir /var/log/nginx/mysite/
sudo rm -rf /etc/nginx/nginx.conf
sudo cp /home/admin/netology_diplom-main/mysite/nginx.conf /etc/nginx/
sudo systemctl restart nginx
