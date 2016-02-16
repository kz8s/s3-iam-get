provider "aws" { region = "${ var.region }" }

variable "ami" {}
variable "bucket" {}
variable "cidr-allow-ssh" {}
variable "key-name" {}
variable "region" {}

output "bucket" { value = "${ var.bucket }" }
output "ip" { value = "${ aws_instance.ai.public_ip }" }

# ---

resource "aws_s3_bucket" "s3-iam-get" {
  acl = "private"
  bucket = "${ var.bucket }"
  force_destroy = true
  tags {
    bucket = "${ var.bucket }"
    Name = "s3-iam-get"
    circleci = "yes"
  }

  provisioner "local-exec" {
    command = <<LOCAL_EXEC
echo "test" | aws s3 cp - s3://${ var.bucket }/test && \
echo "deep" | aws s3 cp - s3://${ var.bucket }/deep/deep
LOCAL_EXEC
  }
}

# ---

resource "aws_iam_role" "air" {
  name = "air-${ var.bucket }"
  assume_role_policy = <<EOS
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOS
}

resource "aws_iam_instance_profile" "aiip" {
  name = "aiip-${ var.bucket }"
  roles = [ "${ aws_iam_role.air.name }", ]
}

resource "aws_iam_role_policy" "airp" {
  name = "${ var.bucket }"
  role = "${ aws_iam_role.air.id }"
  policy = <<EOS
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:List*",
        "s3:Get*"
      ],
      "Resource": [ "arn:aws:s3:::${ var.bucket }/*" ]
    }
  ]
}
EOS
}

# ---

resource "aws_security_group" "asg" {
  name = "s3-iam-get"

  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "${ var.cidr-allow-ssh }" ]
  }

  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_instance" "ai" {
  ami = "${ var.ami }"
  associate_public_ip_address = true
  iam_instance_profile = "${ aws_iam_instance_profile.aiip.name }"
  instance_type = "t2.nano"
  key_name = "${ var.key-name }"

  connection {
    user = "core"
    private_key = "${ file("${ var.bucket }.pem") }"
  }

  provisioner "file" {
    source = "../s3-iam-get"
    destination = "/tmp/s3-iam-get"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/s3-iam-get",
      "/tmp/s3-iam-get s3://${ var.bucket }/test ~/test",
      "/tmp/s3-iam-get s3://${ var.bucket }/deep/deep ~/deep",
    ]
  }

  security_groups = [ "${ aws_security_group.asg.name }", ]

  tags  {
    Name = "ai"
    Cluster = "${ var.bucket }"
    env = "circleci"
  }
}
