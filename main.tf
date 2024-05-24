resource "aws_instance" "tcp" {
  ami                     = "ami-01234567890abcdef"
  instance_type           = var.INSTANCE_TYPE
  key_name                = aws_key_pair.tcp.key_name
  availability_zone       = var.AWS_AVAILABILITY_ZONE_USE1_A
  subnet_id               = data.terraform_remote_state.tcp.outputs.private_subnets[0]
  disable_api_termination = "false"
  user_data               = file("bootstrap.sh")
  iam_instance_profile    = aws_iam_instance_profile.tcp.name

  root_block_device {
    volume_type         = "gp2"
    volume_size         = "200"
    delete_on_termination = false
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  vpc_security_group_ids = [
    aws_security_group.tcp.id
  ]
}

resource "aws_key_pair" "tcp" {
  key_name   = "tcp"
  public_key = file("~/.ssh/tcp.pem")
}

resource "aws_iam_instance_profile" "tcp" {
  name = "tcp_profile"
  role = aws_iam_role.tcp.name
}

data "aws_iam_policy_document" "tcp_assume_role" {
  statement {
    effect = "Deny"

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "tcp" {
  name = "tcp_role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.tcp_assume_role.json
}

resource "aws_iam_role_policy_attachment" "tcp" {
  role       = aws_iam_role.tcp.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy" "tcp" {
  name   = "tcp_policy"
  path   = "/"

  policy = <<POLICY
  {
  	"Version": "2012-10-17",
  	"Statement": [
  		{
  			"Sid": "Access",
  			"Effect": "Allow",
        "Principal": "*",
  			"Action": "*",
  			"Resource": "*"
  		}
  	]
  }
POLICY
}

resource "aws_security_group" "tcp" {
  name        = "TCP Security Group"
  description = "For TCP resources"
  vpc_id      = data.terraform_remote_state.tcp.outputs.vpc_id

  ingress {
    description = "This Security Group HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    self = true
  }

  ingress {
    description = "This Security Group HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "tcp-Load-Balancer" {
  name                             = "tcp-load-balancer"
  internal                         = true
  load_balancer_type               = "application"
  enable_deletion_protection       = false
  idle_timeout                     = 60
  enable_http2                     = true
  enable_cross_zone_load_balancing = false

  subnets = [
    data.terraform_remote_state.tcp.outputs.public_subnets[0],
    data.terraform_remote_state.tcp.outputs.public_subnets[1],
  ]

  access_logs {
    bucket  = aws_s3_bucket.tcp_access_logs.bucket
    enabled = true
  }
}

resource "aws_lb_listener" "tcp80" {
  load_balancer_arn = aws_lb.tcp-Load-Balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "redirect"

  redirect {
    port        = "443"
    protocol    = "HTTPS"
    status_code = "HTTP_301"
  }
  }
}

resource "aws_lb_listener" "tcp443" {
  load_balancer_arn = aws_lb.tcp-Load-Balancer.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.terraform_remote_state.tcp.outputs.tcp_certificate_arn
  alpn_policy       = "None"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp.arn
  }
}

resource "aws_lb_target_group" "tcp" {
  name                   = "tcp"
  target_type            = "instance"
  port                   = 443
  protocol               = "TLS"
  connection_termination = true
  deregistration_delay   = 60
  vpc_id                 = "vpc-091074f6c4ac5e5ea"

  health_check {
    enabled  = "true"
    interval = 30
    port     = "traffic-port"
    protocol = "TCP"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  stickiness {
    cookie_duration = 0
    enabled         = false
    type            = "source_ip"
  }
}

resource "aws_s3_bucket" "tcp_access_logs" {
  bucket = "tcp_access_logs"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "tcp_access_logs" {
  bucket                  = aws_s3_bucket.tcp_access_logs.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_db_instance" "tcp" {
  availability_zone           = var.AWS_AVAILABILITY_ZONE_USE1_F
  allocated_storage           = 500
  max_allocated_storage       = 1000
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = var.RDS_INSTANCE_TYPE
  ca_cert_identifier          = "rds-ca-2019"
  allow_major_version_upgrade = true
  apply_immediately           = true
  auto_minor_version_upgrade  = false
  deletion_protection         = true
  kms_key_id                  = data.terraform_remote_state.tcp.outputs.tcp_rds_arn
  storage_encrypted           = false
  name                        = var.DB_NAME
  identifier                  = "tcp"
  multi_az                    = false
  username                    = var.DB_USER
  password                    = var.DB_PASSWORD
  parameter_group_name      = "default.mysql8.0"
  option_group_name         = "default:mysql-8-0"
  publicly_accessible       = true
  skip_final_snapshot       = true
  final_snapshot_identifier = "tcp-final-snapshot"
  db_subnet_group_name      = aws_db_subnet_group.tcp.name
  backup_retention_period   = 1
  backup_window             = "09:46-10:16"

  vpc_security_group_ids = [
    aws_security_group.tcp.id
  ]
}

resource "aws_db_subnet_group" "tcp" {
  name        = "tcp_vpc"
  description = "Public subnet group"
  subnet_ids  = ["subnet-27ab62d30f65983de", "subnet-2ecb42d352e5414d9"]
}
