resource "aws_launch_template" "web" {
  name_prefix   = "${var.env_name}-lt"
  image_id      = var.ami
  instance_type = var.instance_type

vpc_security_group_ids = [var.sg_id]

  user_data = base64encode(file("${path.module}/user_data.sh"))
}

resource "aws_autoscaling_group" "web" {
  count = var.enable_asg ? 1 : 0

  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = var.subnets

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}
