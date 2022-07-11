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
