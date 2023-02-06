# Диплом

Разворачиваем инфраструктуру с помощью Terraform

https://github.com/drugovdv/netology_diplom/blob/main/diplom-terraform/main.tf

Переходим на хост admin и далее работем с него 

Устанавливаем git, ansible

Клонируем репозиторий https://github.com/drugovdv/netology_diplom.git

С помощью ansible 

  1 устанавливаем на webservers - nginx, mysite, log-exporter для prometheus

https://github.com/drugovdv/netology_diplom/blob/main/ansible/nginx_log-exp_install.yml

  2 устанавливаем на prometheus - prometheus, и node-exporter на все hosts

https://github.com/drugovdv/netology_diplom/blob/main/ansible/prometheus_node-exp_install.yml

  3 устанавливаем на grafana - docker, grafana в контейнере docker

https://github.com/drugovdv/netology_diplom/blob/main/ansible/grafana_docker_install.yaml

  4 устанавливаем на elasticsearch - elasticsearch

https://github.com/drugovdv/netology_diplom/blob/main/ansible/elastic_install.yml

Подключаемся с хоста admin к хосту elasticsearch

 1 редактируем конфиг

![screenshot1](https://github.com/drugovdv/netology_diplom/blob/main/screen/%D0%A1%D0%BA%D1%80%D0%B8%D0%BD%D1%88%D0%BE%D1%82%2028-01-2023%20172140.jpg)
![screenshot2](https://github.com/drugovdv/netology_diplom/blob/main/screen/%D0%A1%D0%BA%D1%80%D0%B8%D0%BD%D1%88%D0%BE%D1%82%2028-01-2023%20172150.jpg)

 2 создаем пароли для доступа к ELK

![screenshot3](https://github.com/drugovdv/netology_diplom/blob/main/screen/%D0%A1%D0%BA%D1%80%D0%B8%D0%BD%D1%88%D0%BE%D1%82%2028-01-2023%20173128.jpg)
 
 3 перезапускаем elasticsearch

Выходим из хоста elasticsearch

С помощью ansible 

 1 устанавливаем на kibana - kibana

https://github.com/drugovdv/netology_diplom/blob/main/ansible/kibana_install.yml

 2 устанавливаем на webservers - filebeat

https://github.com/drugovdv/netology_diplom/blob/main/ansible/filebeat_nginx_install.yml

Заходим в grafana и настраиваем подключение к prometheus и dashboards для log-exporter и node-exporter

ip_grafana:3000   Логин: admin Пароль: ******

Заходим в kibana и настраиваем на просмотр логов от webservers

ip_kibana:5601 Логин: elastic Пароль: ******
