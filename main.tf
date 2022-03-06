resource "aws_rds_cluster" "rds" {
  cluster_identifier      = "aurora-cluster-demo"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  database_name           = "mydb"
  master_username         = "admin"
  master_password         = "sanjayi123"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  port                    = var.port
  skip_final_snapshot       = true

  tags = {
    Key = "Environment"
    Value = "test"
  }
}



resource "aws_rds_cluster_instance" "instances" {
  count              = 2
  #identifier         = "aws_rds_cluster.rds.cluster_identifier"
  cluster_identifier = aws_rds_cluster.rds.cluster_identifier
  instance_class     = "db.t3.small"
  engine             = var.engine
  engine_version     = var.engine_version
  tags = {
    Key = "Environment"
    value = "test"
  }
}


resource "aws_kms_key" "my-key" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
}

resource "aws_backup_vault" "backup-vault" {
  name        = "backup_vault"
  kms_key_arn = aws_kms_key.my-key.arn
}

resource "aws_backup_plan" "test" {
  name = "test_plan"

  rule {
    rule_name         = "tf_example_backup_rule"
    target_vault_name = aws_backup_vault.backup-vault.name
    schedule          = "cron(10 21 * * ? *)"
    start_window      = "65"
    completion_window = "180"
    enable_continuous_backup = true
            lifecycle {
            delete_after = 10
        }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "disabled"
    }
    resource_type = "EC2"
  }
    tags = {
    Environment = "test"
  }
}

resource "aws_backup_selection" "rds-backup" {
  iam_role_arn = aws_iam_role.backup-role.arn
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.test.id
    resources = [
    "arn:aws:rds:eu-west-2:415002233766:cluster:aurora-cluster-demo"
    ]
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = "test"
  }
}

resource "aws_iam_role" "backup-role" {
  name               = "backup-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "backup-role-att" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup-role.name
}




