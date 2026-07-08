resource "aws_security_group" "db" {
  name   = "${var.name}-db-sg"
  vpc_id = var.vpc_id
  ingress { from_port = 3306 to_port = 3306 protocol = "tcp" security_groups = [var.app_security_group] }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.db_subnet_ids
}

resource "random_password" "db" { length = 20 special = true }

resource "aws_secretsmanager_secret" "db" { name = "${var.name}/db-password" }
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

resource "aws_db_instance" "this" {
  identifier             = "${var.name}-mysql"
  engine                 = var.engine
  instance_class         = var.instance_class
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  username               = "adminuser"
  password               = random_password.db.result
  multi_az               = var.multi_az
  backup_retention_period = var.backup_retention
  storage_encrypted      = true
  skip_final_snapshot    = false
  deletion_protection    = true
}
