resource "yandex_container_registry" "listmonk" {
  name = "listmonk"
}

resource "yandex_container_repository" "listmonk" {
  name = "${yandex_container_registry.listmonk.id}/listmonk"
}

resource "yandex_container_repository" "postgres" {
  name = "${yandex_container_registry.listmonk.id}/postgres"
}

locals {
    listmonk_image = "cr.yandex/${yandex_container_registry.listmonk.id}/listmonk:latest"
    postgres_image  = "cr.yandex/${yandex_container_registry.listmonk.id}/postgres:latest"
}

resource "null_resource" "images" {
  provisioner "local-exec" {
    command = <<EOT
        docker pull --platform linux/amd64 listmonk/listmonk:latest
        docker tag listmonk/listmonk:latest ${local.listmonk_image}
        docker push ${local.listmonk_image}

        docker pull --platform linux/amd64 postgres:17-alpine
        docker tag postgres:17-alpine ${local.postgres_image}
        docker push ${local.postgres_image}
        EOT
  }
}

resource "yandex_iam_service_account" "image-puller" {
  name = "listmonk-image-puller"
  description = "Service account for pulling images from Yandex Container Registry"
}

resource "yandex_resourcemanager_folder_iam_binding" "image-puller-binding" {
  folder_id = var.folder_id
  role = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.image-puller.id}"
  ]
}