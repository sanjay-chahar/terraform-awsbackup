variable "engine_mode" {
  type    = string
  default = "provisioned"
}

variable "engine" {
  type    = string
  default = "aurora-mysql"
}

variable "engine_version" {
  type    = string
  default = "5.7.mysql_aurora.2.03.2"
}

variable "port" {
  type    = number
  default = 3306
}

variable "db_parameter_group" {
  type    = string
  default = "aurora-mysql5.7"
}
