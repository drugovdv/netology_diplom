terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     =  var.yandex_token
  cloud_id  =  var.yandex_cloud_id
}

resource "yandex_resourcemanager_folder" "mysite" {
  cloud_id = var.yandex_cloud_id
  name        = "mysite"
  description = "folder to mysite"
}

resource "yandex_iam_service_account" "admin" {
  name        = "admin"
  description = "service account to manage mysite"
  folder_id   = "${yandex_resourcemanager_folder.mysite.id}"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  role      = "editor"
  members   = [
    "serviceAccount:${yandex_iam_service_account.admin.id}",
  ]
}

#################################################################################################################

resource "yandex_vpc_network" "mysite-net" {
  name = "mysite-network"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
}

##################################################################################################################

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "private_net1"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = "${yandex_vpc_route_table.mysite-rt.id}"
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "private_net2"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  zone           = "ru-central1-c"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = "${yandex_vpc_route_table.mysite-rt.id}"
}

resource "yandex_vpc_subnet" "subnet-3" {
  name           = "private_net3"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  v4_cidr_blocks = ["192.168.3.0/24"]
  route_table_id = "${yandex_vpc_route_table.mysite-rt.id}"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "public_net"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  v4_cidr_blocks = ["10.1.1.0/24"]
}

################################################################################################################

resource "yandex_vpc_gateway" "egress-gateway" {
  name = "egress-gateway"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "mysite-rt" {
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  network_id     = "${yandex_vpc_network.mysite-net.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = "${yandex_vpc_gateway.egress-gateway.id}"
  }
}

####################################################################################################################

resource "yandex_vpc_security_group" "adm" {
  name        = "security adm"
  description = "security adm"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    port           = 22
  }
  
    ingress {
    protocol       = "TCP"
    description    = "prometheus1"
    v4_cidr_blocks  = ["192.168.3.10/32"]
    port           = 9100
  }

  ingress {
    protocol       = "ICMP"
    description    = "ismp"
    v4_cidr_blocks  = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  }

  egress {
    protocol       = "ANY"
    description    = "admEgress"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }
}

resource "yandex_compute_instance" "admin" {
  name        = "admin"
  hostname = "admin"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20    
  }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.yandex_instance_id
        size = 10
      }
  }

  network_interface {
    subnet_id     = "${yandex_vpc_subnet.subnet.id}"
    nat       = true
    ip_address = "10.1.1.100"
    security_group_ids = ["${yandex_vpc_security_group.adm.id}"]
  }

  metadata = {
    user-data = "${file("~/netology_diplom/terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

###############################################################################################################

resource "yandex_vpc_security_group" "web" {
  name        = "Mysite security web"
  description = " Mysite security web"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  ingress {
    protocol       = "TCP"
    description    = "http"
    v4_cidr_blocks  = ["10.1.1.0/24"]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "loadbal"
    predefined_target =  "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks  = ["10.1.1.100/32"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "prometheus1"
    v4_cidr_blocks  = ["192.168.3.10/32"]
    port           = 9100
  }

  ingress {
    protocol       = "TCP"
    description    = "prometheus2"
    v4_cidr_blocks  = ["192.168.3.10/32"]
    port           = 4040
  }

  ingress {
    protocol       = "ICMP"
    description    = "ismp"
    v4_cidr_blocks  = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  }

  egress {
    protocol       = "ANY"
    description    = "admEgress"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }
}

resource "yandex_compute_instance_group" "web" {
  name               = "mysite-web"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  service_account_id = "${yandex_iam_service_account.admin.id}"

  instance_template {
    platform_id = "standard-v1"
    name = "web-{instance.index}"
    hostname = "web-{instance.index}"

    resources {
      memory = 4
      cores  = 2
      core_fraction = 20
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.yandex_webservers_image_id
        size = 12
      }
    }

    network_interface {
    network_id     = "${yandex_vpc_network.mysite-net.id}"
    subnet_ids     = ["${yandex_vpc_subnet.subnet-1.id}","${yandex_vpc_subnet.subnet-2.id}"]
    nat       = false
    security_group_ids = ["${yandex_vpc_security_group.web.id}"]
    }
  
    metadata = {
    user-data = "${file("~/netology_diplom/terraform/nginx.meta.txt")}"
    }

    scheduling_policy {
    preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
        size    = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-b","ru-central1-c"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  application_load_balancer {
    target_group_name        = "target-group"
    target_group_description = "load balancer target group"
  }
}

data "yandex_compute_instance_group" "web" {
  instance_group_id = "${yandex_compute_instance_group.web.id}"
}

resource "yandex_alb_backend_group" "backend-group" {
  name      = "mysite-backend-group"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  http_backend {
    name = "mysite-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${data.yandex_compute_instance_group.web.application_load_balancer.0.target_group_id}"]
   
  load_balancing_config {
      panic_threshold = 50
    }    

  healthcheck {
      timeout = "10s"
      interval = "2s"
      http_healthcheck {
        path  = "/"
      }
    } 
  }
}

resource "yandex_alb_http_router" "tf-router" {
  name      = "mysite-http-router"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
}

resource "yandex_alb_virtual_host" "mysite-virtual-host" {
  name      = "mysite-virtual-host"
  http_router_id = "${yandex_alb_http_router.tf-router.id}"

  route {
    name = "mysite-route"
    http_route {
      http_route_action {
        backend_group_id = "${yandex_alb_backend_group.backend-group.id}"
        timeout = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "mysite-balancer" {
  name           = "mysite-load-balancer"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  depends_on = [
    yandex_compute_instance_group.web
  ]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet.id}"
    }
  }

  listener {
    name = "mysite-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = "${yandex_alb_http_router.tf-router.id}"
      }
    }
  }
}

##################################################################################################################################

resource "yandex_vpc_security_group" "graf" {
  name        = "Mysite security grafana"
  description = " Mysite security grafana"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  ingress {
    protocol       = "TCP"
    description    = "graf"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    port           = 3000
  }
  
  ingress {
    protocol       = "TCP"
    description    = "prometheus1"
    v4_cidr_blocks  = ["192.168.3.10/32"]
    port           = 9100
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    security_group_id = "${yandex_vpc_security_group.adm.id}"
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "ismp"
    v4_cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "admEgress"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }
}

resource "yandex_compute_instance" "grafana" {
  name        = "grafana"
  hostname = "grafana"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }
  
  boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.yandex_instance_id
        size = 15
      }
  }

  network_interface {
    subnet_id     = "${yandex_vpc_subnet.subnet.id}"
    nat       = true
    ip_address = "10.1.1.10"
    security_group_ids = ["${yandex_vpc_security_group.graf.id}"]
  }

  metadata = {
    user-data = "${file("~/netology_diplom/terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

##################################################################################################################

resource "yandex_vpc_security_group" "kib" {
  name        = "Mysite security kibana"
  description = " Mysite security kibana"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "TCP"
    description    = "prometheus1"
    v4_cidr_blocks  = ["192.168.3.10/32"]
    port           = 9100
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    security_group_id = "${yandex_vpc_security_group.adm.id}"
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "ismp"
    v4_cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "admEgress"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname        = "kibana"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }
  
  boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.yandex_instance_id
        size = 15
      }
  }

  network_interface {
    subnet_id     = "${yandex_vpc_subnet.subnet.id}"
    nat       = true
    ip_address = "10.1.1.14"
    security_group_ids = ["${yandex_vpc_security_group.kib.id}"]
  }

  metadata = {
    user-data = "${file("~/netology_diplom/terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

#########################################################################################################################

resource "yandex_vpc_security_group" "prom" {
  name        = "Mysite security prometheus"
  description = " Mysite security prometheus"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  ingress {
    protocol       = "TCP"
    description    = "prometheus"
    v4_cidr_blocks  = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
    port           = 9090
  }
  
  ingress {
    protocol       = "TCP"
    description    = "ssh"
    security_group_id = "${yandex_vpc_security_group.adm.id}"
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "ismp"
    v4_cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "admEgress"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }
}

resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  hostname        = "prometheus"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  platform_id = "standard-v1"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }
  
  boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.yandex_instance_id
        size = 15
      }
  }
  
  network_interface {
    subnet_id     = "${yandex_vpc_subnet.subnet-3.id}"
    nat       = false
    ip_address = "192.168.3.10"
    security_group_ids = ["${yandex_vpc_security_group.prom.id}"]
  }

  metadata = {
    user-data = "${file("~/netology_diplom/terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

########################################################################################################

resource "yandex_vpc_security_group" "el" {
  name        = "Mysite security elastic"
  description = " Mysite security elastic"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"

  ingress {
    protocol       = "TCP"
    description    = "elastic"
    v4_cidr_blocks  = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
    port           = 9200
  }

  ingress {
    protocol       = "TCP"
    description    = "prometheus1"
    v4_cidr_blocks  = ["192.168.3.10/32"]
    port           = 9100
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    security_group_id = "${yandex_vpc_security_group.adm.id}"
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "ismp"
    v4_cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "admEgress"
    v4_cidr_blocks  = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }
}

resource "yandex_compute_instance" "elastic" {
  name        = "elasticsearch"
  hostname        = "elasticsearch"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
  platform_id = "standard-v1"
  zone        = "ru-central1-b"

  resources {
    cores  = 4
    memory = 8
    core_fraction = 20
  }
  
  boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.yandex_instance_id
        size = 20
      }
  }

  network_interface {
    subnet_id     = "${yandex_vpc_subnet.subnet-3.id}"
    nat       = false
    ip_address = "192.168.3.5"
    security_group_ids = ["${yandex_vpc_security_group.el.id}"]
  }

  metadata = {
    user-data = "${file("~/netology_diplom/terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

#######################################################################################

resource "yandex_compute_snapshot_schedule" "snapshot" {
  name           = "my-snapshot"
  folder_id   = "${yandex_resourcemanager_folder.mysite.id}"

  schedule_policy {
    expression = "00 00 ? * *"
  }

  snapshot_count = 7

  snapshot_spec {
      description = "snapshot-everyday"
  }

  disk_ids = ["${yandex_compute_instance.admin.boot_disk.0.disk_id}", "${yandex_compute_instance.elastic.boot_disk.0.disk_id}", "${yandex_compute_instance.kibana.boot_disk.0.disk_id}", "${yandex_compute_instance.prometheus.boot_disk.0.disk_id}", "${yandex_compute_instance.grafana.boot_disk.0.disk_id}"]
}

#######################################################################

data "yandex_compute_instance" "admin" {
  instance_id = "${yandex_compute_instance.admin.id}"
}

data "yandex_compute_instance" "kibana" {
  instance_id = "${yandex_compute_instance.kibana.id}"
}

data "yandex_compute_instance" "grafana" {
  instance_id = "${yandex_compute_instance.grafana.id}"
}

resource "local_file" "admin_external_ip" {
  content = "${data.yandex_compute_instance.admin.network_interface.0.nat_ip_address}"
  filename = "external_ip/admin_external_ip"
}

resource "local_file" "kibana_external_ip" {
  content = "${data.yandex_compute_instance.kibana.network_interface.0.nat_ip_address}"
  filename = "external_ip/kibana_external_ip"
}

resource "local_file" "grafana_external_ip" {
  content = "${data.yandex_compute_instance.grafana.network_interface.0.nat_ip_address}"
  filename = "external_ip/grafana_external_ip"
}

data "yandex_alb_load_balancer" "mysite-balancer" {
  load_balancer_id = "${yandex_alb_load_balancer.mysite-balancer.id}"
}

resource "local_file" "alb_external_ip" {
  content = "${data.yandex_alb_load_balancer.mysite-balancer.listener.0.endpoint.0.address.0.external_ipv4_address.0.address}"
  filename = "external_ip/site_external_ip"
}