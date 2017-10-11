job "site-index" {
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
            tag = "${NOMAD_TASK_NAME} ${NOMAD_ALLOC_ID} ${attr.unique.hostname} "
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
}
