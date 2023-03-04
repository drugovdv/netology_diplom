# Диплом

------

### Разворачиваем инфраструктуру и сайт на webservers с помощью Terraform

https://github.com/drugovdv/netology_diplom/tree/main/terraform

------

### Подключаемся по SSH к хосту admin по ip из файла terraform/external_ip/admin_external_ip

  - копируем на хост admin id_rsa.
  
------

### С помощью ansible устанавливаем все остальное 

https://github.com/drugovdv/netology_diplom/tree/main/ansible

предварительно заменив в файле **ansible/group_vars/all** :

   - ip на внешний ip из файла terraform/eternal_ip/admin_external_ip 
 
   - password_elastic на свой пароль

### Подключение по ip из файлов в terraform/external_ip

grafana_external_ip:3000 -  Логин:  admin    Пароль: password_elastic

kibana_external_ip:5601  -  Логин:  elastic  Пароль: password_elastic

site_external_ip  - сайт