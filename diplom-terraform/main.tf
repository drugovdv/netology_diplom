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

resource "yandex_vpc_network" "mysite-net" {
  name = "mysite-network"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
}

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

resource "yandex_vpc_security_group" "group" {
  name        = "Mysite security group"
  description = "  security group"
  network_id     = "${yandex_vpc_network.mysite-net.id}"
  folder_id = "${yandex_resourcemanager_folder.mysite.id}"
}

resource "yandex_vpc_security_group_rule" "ruleSSH" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleSSH"
  v4_cidr_blocks         = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  port                   = 22
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleNode-exp" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleNode-exp"
  v4_cidr_blocks         = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  port                   = 9100
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleLog-exp-nginx" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleLog-exp-nginx"
  v4_cidr_blocks         = ["192.168.1.0/24", "192.168.2.0/24"]
  port                   = 4040
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleHTTP" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleHTTP"
  v4_cidr_blocks         = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24"]
  port                   = 80
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "rulePrometheus" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "rulePrometheus"
  v4_cidr_blocks         = ["192.168.3.10/32"]
  port                   = 9090
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleElastic" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleElastic"
  v4_cidr_blocks         = ["192.168.3.5/32"]
  from_port              = 9200
  to_port                = 9300
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleKibana" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleKibana"
  v4_cidr_blocks         = ["10.1.1.14/32"]
  port                   = 5601
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleGrafana" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "ingress"
  description            = "ruleGrafana"
  v4_cidr_blocks         = ["10.1.1.10/32"]
  port                   = 3000
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "ruleEgress" {
  security_group_binding = yandex_vpc_security_group.group.id
  direction              = "egress"
  description            = "ruleEgress"
  v4_cidr_blocks         = ["10.1.1.0/24", "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  from_port              = 1
  to_port                = 65535
  protocol               = "ANY"
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
  }

  metadata = {
    user-data = "${file("~/netology_diplom/diplom-terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
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
    }
  
    metadata = {
    user-data = "${file("~/netology_diplom/diplom-terraform/meta.txt")}"
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
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
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
  }

  metadata = {
    user-data = "${file("~/netology_diplom/diplom-terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
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
  }

  metadata = {
    user-data = "${file("~/netology_diplom/diplom-terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
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
  }

  metadata = {
    user-data = "${file("~/netology_diplom/diplom-terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
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
  }

  metadata = {
    user-data = "${file("~/netology_diplom/diplom-terraform/meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

#################################


