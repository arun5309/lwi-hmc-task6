variable "db_password" {
	type = string
}

provider "aws" {
  region = "ap-southeast-1"
  profile = "adminuser_profile"
}


resource "aws_db_instance" "wordpressdb" {
  name                 = "wpdb"
  identifier           = "wordpressdb"
  parameter_group_name = "default.mysql5.7"
  instance_class       = "db.t2.micro"
  allocated_storage    = 5
  max_allocated_storage = 10
  storage_type         = "gp2"
  port = 3306
  engine               = "mysql"
  engine_version       = "5.7"
  username             = "root"
  password             = var.db_password
  skip_final_snapshot = true
  publicly_accessible = true
  delete_automated_backups = true
}

provider "kubernetes" {
  config_context_cluster = "minikube"
}

resource "kubernetes_deployment" "wpdeployment" {
  metadata {
    name = "wpdeployment"
    labels = {
      App = "WordPress"
    }
  }
  spec {
    replicas = 1
    strategy {
      type = "RollingUpdate"
    }
    selector {
      match_labels = {
        type = "webserver"
        env = "Production"
      }
    }
    template {
      metadata {
        labels = {
          type = "webserver"
          env = "Production"
        }
      }
      spec {
        container {
          name = "webserver"
          image = "wordpress"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wpservice" {
  metadata {
    name = "wpservice"
  }
  spec {
    type = "NodePort"
    selector = {
      type = "webserver"
    }
    port {
      port = 80
      target_port = 80
      protocol = "TCP"
      name = "http"
    }
  }
}

