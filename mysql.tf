module "mysql" {
  source = "git::https://fefc@dev.azure.com/fefc/terraform-azure-mysql/_git/terraform-azure-mysql"

  ARM_REGION  = "${var.ARM_REGION}"
  db_name     = "${var.db_name}"
  website     = "${var.website}"
  db_server   = "${var.db_server}"
  environment = "${var.environment}"
  project     = "${var.project}"
  owner       = "${var.owner}"
  support     = "${var.support}"
}

