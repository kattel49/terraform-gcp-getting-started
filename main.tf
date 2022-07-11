#source code for the providers
terraform {
    required_providers{
        google = {
            source = "hashicorp/google"
        }
    }
}
#google
provider "google" {
    project = "sapient-cycling-355714"
    region = "europe-west3"
    zone = "europe-west3-c"
}

#custom network
resource "google_compute_network" "vpc_network" {
    name = "terraform-network"
    auto_create_subnetworks = false
}

#subnetwork
resource "google_compute_subnetwork" "terraform_subnet_eur" {
    name = "terraform-subnet-eur"
    depends_on = [
      google_compute_network.vpc_network
    ]
    ip_cidr_range = "10.1.0.0/16"
    #attach subnetwork to the vpc_network defined above
    network = google_compute_network.vpc_network.id
}

#firewall rules
resource "google_compute_firewall" "terraform_network_allow_icmp_ssh_rdp"{
    name = "terraform-network-allow-icmp-ssh-rdp"
    network = google_compute_network.vpc_network.name
    depends_on = [
      google_compute_subnetwork.terraform_subnet_eur
    ]
    allow{
        protocol = "icmp"
    }
    allow{
        protocol = "tcp"
        ports = ["22", "3389"]
    }
    #allow everyone with the credentials to connect to instances
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "terraform_network_allow_http_https" {
    name = "terraform-network-allow-http-https"
    network = google_compute_network.vpc_network.name
    depends_on = [
      google_compute_subnetwork.terraform_subnet_eur
    ]
    allow{
        protocol = "tcp"
        ports = ["80", "443"]
    }
    #instances with http-server will have :80 and :443 open to all connections
    target_tags = ["http-server"]
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "terraform_network_allow_internal" {
    name = "terraform-network-allow-internal"
    network = google_compute_network.vpc_network.name
    depends_on = [
      google_compute_subnetwork.terraform_subnet_eur
    ]
    allow{
        protocol = "udp"
        ports = ["0-65535"]
    }
    allow{
        protocol = "tcp"
        ports = ["0-65535"]
    }
    #add along as subnetwork grows in the vpc network
    source_ranges = ["10.1.0.0/16"]
}

# test vms
resource "google_compute_instance" "example" {
    name = "test-instance"
    machine_type = "f1-micro"
    depends_on = [
      google_compute_network.vpc_network
    ]
    boot_disk {
        initialize_params {
          image = "debian-cloud/debian-10"
        }
    }

    network_interface {
      subnetwork = google_compute_subnetwork.terraform_subnet_eur.self_link
      access_config{
      }
    }
}

resource "google_compute_instance" "example_http_instance" {
    name = "test-http-instance"
    machine_type = "f1-micro"
    depends_on = [
      google_compute_network.vpc_network
    ]
    boot_disk{
        initialize_params{
            image = "debian-cloud/debian-9"
        }
    }

    network_interface{
        subnetwork = google_compute_subnetwork.terraform_subnet_eur.self_link
        access_config{

        }
    }
    #the startup script did not work
    metadata_startup_script = <<SCRIPT
    #! /bin/bash
    sleep 10
    apt update && apt install apache2 -y
    echo "<!doctype html><html><body><h1>Hello World! from test-http-instance </h1></body></html>" | tee /var/www/html/index.html
    systemctl restart apache2
    SCRIPT
    tags = ["http-server"]
}