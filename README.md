# Диплом

Разворачиваем инфраструктуру с помощью Terraform

Переходим на хост admin и далее работем с него 

Устанавливаем git, ansible

Клонируем репозиторий https://github.com/drugovdv/netology_diplom.git

С помощью ansible 

  1 устанавливаем на webservers - nginx, mysite, log-exporter для prometheus

  2 устанавливаем на prometheus - prometheus, и node-exporter на все hosts

  3 устанавливаем на grafana - docker, grafana в контейнере docker

  4 устанавливаем на elasticsearch - elasticsearch
  

Подключаемся с хоста admin к хосту elasticsearch

 1 редактируем конфиг

 2 создаем пароли для доступа к ELK
 
 3 перезапускаем elasticsearch

Выходим из хоста elasticsearch

С помощью ansible 

 1 устанавливаем на kibana - kibana

 2 устанавливаем на webservers - filebeat

Заходим в grafana и настраиваем подключение к prometheus и dashboards для log-exporter и node-exporter

Заходим в kibana и настраиваем на просмотр логов от webservers

