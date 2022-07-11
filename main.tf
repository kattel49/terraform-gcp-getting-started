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
    version = "3.5.0"
    region = "europe-west3"
    zone = "europe-west3-a"
}

#custom network
resource "google_compute_network" "vpc_network" {
    name = "terraform-network"
    auto_create_subnetworks = false
}

#subnetwork
resource "google_compute_subnetwork" "terraform_subnet_eur" {
    name = "terraform-subnet-eur"
    ip_cidr_range = "10.1.0.0/16"
    #attach subnetwork to the vpc_network defined above
    network = google_compute_network.vpc_network.id
}