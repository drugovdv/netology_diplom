# Диплом

Разворачиваем инфраструктуру с помощью Terraform

https://github.com/drugovdv/netology_diplom/tree/main/terraform

Подключаемся по SSH к хосту admin по ip из файла terraform/admin_external_ip

С помощью ansible устанавливаем все остальное 

https://github.com/drugovdv/netology_diplom/tree/main/ansible

предварительно заменив в ansible/group_vars/all :

 ip на внешний ip из файла terraform/admin_external_ip 
 
 password_elastic на свой пароль

ip_grafana:3000   Логин:  admin    Пароль: password_elastic

ip_kibana:5601    Логин:  elastic  Пароль: password_elastic
