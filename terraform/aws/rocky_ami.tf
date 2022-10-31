
data "aws_ami" "rocky" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Rocky-8-ec2-8.6-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}
