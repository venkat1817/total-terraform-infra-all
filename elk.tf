#security_group
resource "aws_security_group" "ek-sg" {
  name        = "ek-sg"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.stage-vpc.id

  ingress {
    description = "admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "admin"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    description = "admin"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "admin"
    from_port       = 5601
    to_port         = 5601
    protocol        = "tcp"
    security_groups = ["${aws_security_group.siva-alb-sg.id}"]
  }

  ingress {
    description     = "admin"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = ["${aws_security_group.siva-alb-sg.id}"]
    /* cidr_blocks = ["0.0.0.0/0"] */
  }
  ingress {
    description     = "admin"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = ["${aws_security_group.tomcat.id}"]
    /* cidr_blocks = ["0.0.0.0/0"] */
  }
  ingress {
    description     = "admin"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = ["${aws_security_group.jenkins.id}"]
    /* cidr_blocks = ["0.0.0.0/0"] */
  }
  ingress {
    description     = "admin"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = ["${aws_security_group.apache.id}"]
    /* cidr_blocks = ["0.0.0.0/0"] */
  }
  ingress {
    description     = "admin"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = ["${aws_security_group.siva-alb-sg.id}"]
    /* cidr_blocks = ["0.0.0.0/0"] */
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "efk-sg"
  }
}
/* data "template_file" "elkuser" {
  template = file("ek-user-data.sh")

} */

#instance
resource "aws_instance" "elasticsearch-kibana" {
  ami           = var.ami_ubuntu
  instance_type = var.type_ubuntu
  subnet_id     = aws_subnet.privatesubnet[0].id
  # availability_zone = data.aws_availability_zones.available.names[0]
  key_name               = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.ek-sg.id]
  #user_data              = data.template_file.elkuser.rendered
  iam_instance_profile = aws_iam_instance_profile.ssm_agent_instance_profile.name
  user_data            = file("scripts/ek.sh")
  tags = {
    Name = "ek"
  }
}



# alb target-group
resource "aws_lb_target_group" "siva-tg-ek" {
  name     = "tg-elasticsearch"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-ek" {
  target_group_arn = aws_lb_target_group.siva-tg-ek.arn
  target_id        = aws_instance.elasticsearch-kibana.id
  port             = 9200
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-ek-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-ek.arn
  }

  condition {
    host_header {
      values = ["ek.siva.quest"]
    }
  }
}

# alb target-group
resource "aws_lb_target_group" "siva-tg-kibana" {
  name     = "kibana-target"
  port     = 5601
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-kibana" {
  target_group_arn = aws_lb_target_group.siva-tg-kibana.arn
  target_id        = aws_instance.elasticsearch-kibana.id
  port             = 5601
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-kibana-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-kibana.arn
  }

  condition {
    host_header {
      values = ["kibana.siva.quest"]
    }
  }
}