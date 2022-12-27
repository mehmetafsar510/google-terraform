resource "random_id" "db_instance_name" {
  byte_length = 2
  keepers = {
    keyname = "thedoctor"
  }
}

resource "google_sql_database_instance" "instance" {
  name                = "my-database-instance-${random_id.db_instance_name.dec}" #you have to change db instance name every creation
  database_version    = "MYSQL_8_0"
  deletion_protection = "false"
  region              = "us-central1"
  project             = "ultimate-vigil-360607"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "test"
        value = "0.0.0.0/0"
      }
    }
  }
}
resource "google_sql_database" "database" {
  name      = "wordpress"
  instance  = google_sql_database_instance.instance.name
  charset   = "utf8"
  collation = "utf8_general_ci"
}
resource "google_sql_user" "users" {
  name     = "wordpress"
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = "mypassw0rd"
}