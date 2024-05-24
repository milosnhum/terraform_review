variable "ALLOWED_ACCOUNTS_IDS" {
  description = "Allowed accounts IDs."
  default     = ""
}

variable "AWS_REGION" {
  description = "AWS region where infractructure will be created."
  default     = ""
}

variable "AWS_AVAILABILITY_ZONE_USE1_A" {
  description = "AWS availbility zone where infractructure will be created."
  default     = ""
}

variable "AWS_AVAILABILITY_ZONE_USE1_B" {
  description = "AWS availbility zone where infractructure will be created."
  default     = ""
}

variable "AWS_AVAILABILITY_ZONE_USE1_C" {
  description = "AWS availbility zone where infractructure will be created."
  default     = ""
}

variable "AWS_AVAILABILITY_ZONE_USE1_D" {
  description = "AWS availbility zone where infractructure will be created."
  default     = ""
}

variable "AWS_AVAILABILITY_ZONE_USE1_E" {
  description = "AWS availbility zone where infractructure will be created."
  default     = ""
}

variable "AWS_AVAILABILITY_ZONE_USE1_F" {
  description = "AWS availbility zone where infractructure will be created."
  default     = ""
}

variable "INSTANCE_TYPE" {
  default = "c4.2xlarge"
}

variable "RDS_INSTANCE_TYPE" {
  default = "db.x2iedn.8xlarge"
}

variable "DB_NAME" {
  description = "RDS database name"
  default     = ""
}

variable "DB_TABLE_NAME" {
  description = "RDS table name"
  default     = ""
}

variable "DB_USER" {
  description = "RDS user"
  default     = ""
}

variable "DB_PASSWORD" {
  description = "RDS password"
  default     = ""
}
