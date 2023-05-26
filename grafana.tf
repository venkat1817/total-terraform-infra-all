#apache-security group
resource "aws_security_group" "grafana" {
  name        = "grafana"
  description = "this is using for securitygroup"
  vpc_id      = aws_vpc.stage-vpc.id

  ingress {
    description = "this is inbound rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "this is inbound rule"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.siva-alb-sg.id}"]
  }
  ingress {
    description = "this is inbound rule"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "this is inbound rule"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = ["${aws_security_group.siva-alb-sg.id}"]
    /* cidr_blocks = ["0.0.0.0/0"] */
  }
  ingress {
    description     = "this is inbound rule"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "grafana"
  }
}
#apacheuserdata
/* data "template_file" "grafanauser" {
  template = file("grafana.sh")

} */
# apache instance
resource "aws_instance" "grafana" {
  ami                    = var.ami
  instance_type          = var.type
  subnet_id              = aws_subnet.privatesubnet[1].id
  vpc_security_group_ids = [aws_security_group.grafana.id]
  key_name               = aws_key_pair.deployer.id
  #user_data              = data.template_file.grafanauser.rendered
  iam_instance_profile = aws_iam_instance_profile.ssm_agent_instance_profile.name
  user_data            = file("scripts/grafana.sh")
  tags = {
    Name = "stage-grafana"
  }
}

# alb target-group
resource "aws_lb_target_group" "siva-tg-grafana" {
  name     = "grafana"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-grafana" {
  target_group_arn = aws_lb_target_group.siva-tg-grafana.arn
  target_id        = aws_instance.grafana.id
  port             = 3000
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-grafana-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-grafana.arn
  }

  condition {
    host_header {
      values = ["grafana.siva.quest"]
    }
  }
}


# alb target-group
resource "aws_lb_target_group" "siva-tg-prometheus" {
  name     = "prometheus"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-prometheus" {
  target_group_arn = aws_lb_target_group.siva-tg-prometheus.arn
  target_id        = aws_instance.grafana.id
  port             = 9090
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-prometheus-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-prometheus.arn
  }

  condition {
    host_header {
      values = ["prometheus.siva.quest"]
    }
  }
}


