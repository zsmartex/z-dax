provider "google" {
  credentials = "${file("${var.credentials}")}"
  project = "${var.project}"
  region = "${var.region}"
}

provider "random" {}

resource "random_id" "z-dax" {
  byte_length = 2
}

resource "google_compute_instance" "z-dax" {
  name         = "${var.instance_name}-${random_id.z-dax.hex}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "${var.image}"
      type = "pd-ssd"
      size = 120
    }
  }

  network_interface {
    network = "${google_compute_network.z-dax.name}"

    access_config {
      nat_ip = "${google_compute_address.z-dax.address}"
    }
  }

  tags = ["allow-webhook"]

  metadata {
    sshKeys = "${var.ssh_user}:${file("${var.ssh_public_key}")}"
  }

  provisioner "file" {
    source      = "../config/app.yml"
    destination = "/home/${var.ssh_user}/app.yml"

    connection {
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${file("${var.ssh_private_key}")}"
    }
  }

  provisioner "remote-exec" {
    script = "../bin/install.sh"

    connection {
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${file("${var.ssh_private_key}")}"
    }
  }
}

resource "google_compute_firewall" "z-dax" {
  name    = "z-dax-firewall-${random_id.z-dax.hex}"
  network = "${google_compute_network.z-dax.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1337", "443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["allow-webhook"]
}

resource "google_compute_address" "z-dax" {
  name = "z-dax-ip-${random_id.z-dax.hex}"
}

resource "google_compute_network" "z-dax" {
  name = "z-dax-network-${random_id.z-dax.hex}"
}
