job "site-proxy" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "web" {
    count = 1
    ephemeral_disk {
      size = 20
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "site-index" {
      driver = "docker"
      config {
        image = "registry.311cub.net:5000/site-index:latest"
        port_map { http = 5000 }
        logging {
          type = "syslog"
          config {
            syslog-address = "udp://syslog.service.consul:5514"
            tag = "$${NOMAD_TASK_NAME} $${NOMAD_ALLOC_ID} $${attr.unique.hostname} "
          }   
        }   
      }
      env {
        "CONSUL_HTTP_ADDR" = "consul.service.consul:8500"
      }

      service { # consul service checks
        name = "site-index"
        tags = ["http"]
        port = "http"
        check {
          name     = "avaliable"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path = "/"
        }
      }

      resources {
        cpu    = 20 # MHz 
        memory = 256 # MB 
        network {
          mbits = 10
          port "http" {}
        }
      }

      logs {
        max_files     = 3
        max_file_size = 2
      }
    }
  }
 
  group "proxy" {
    count = 1
    ephemeral_disk {
      size = 20  # in MB
    }

    task "traefik" {

      constraint {
        attribute = "${node.class}"
        operator  = "="
        value     = "leader"
      }

      driver = "docker"

      config {
        image = "traefik:1.2.3"
        volumes = [ "/mnt/syn-docker/traefik:/etc/traefik" ]
        port_map = { "admin" = 8080 }
        logging {
          type = "syslog"
          config {
            syslog-address = "udp://syslog.service.consul:5514"
            tag = "$${NOMAD_TASK_NAME} $${NOMAD_ALLOC_ID} $${attr.unique.hostname} "
          }   
        }   
      }

      service {
        name = "traefik"
        port = "admin"
        tags = [ "http" ]
        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 50 # MHz
        memory = 256 # MB
        network {
          mbits = 10
          port "http"  { static = 80  }
          port "https" { static = 443 }
          port "admin" { }
        }
      }

      logs {
        max_files     = 3
        max_file_size = 2
      }
    }
  }
}
