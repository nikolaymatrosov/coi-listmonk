data "yandex_compute_image" "container-optimized-image" {
  family = "container-optimized-image"
}

resource "yandex_vpc_network" "listmonk" {
  name = "listmonk-network"
}

resource "yandex_vpc_subnet" "listmonk-a" {
  network_id = yandex_vpc_network.listmonk.id
  v4_cidr_blocks = [
    "10.0.0.0/24"
  ]
}

resource "yandex_compute_instance" "instance-based-on-coi" {
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
      size     = 33
      type     = "network-ssd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.listmonk-a.id
    nat       = true
  }
  resources {
    cores  = 2
    memory = 2
  }

  service_account_id = yandex_iam_service_account.image-puller.id

  metadata = {
    docker-compose = templatefile("./docker-compose.yaml", {
      listmonk_image = local.listmonk_image
      postgres_image = local.postgres_image
    })
    user-data = templatefile("./user-data.yaml", {
      SSH_PUBLIC_KEY = file("~/.ssh/id_rsa.pub")
    })
  }
}