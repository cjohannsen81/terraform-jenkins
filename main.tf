provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.myvpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "default" {
  name        = "terraform"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.myvpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SQL access from anywhere
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 8065
    to_port     = 8065
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami           = var.aws_amis[var.aws_region]
  instance_type = "t2.micro"
  key_name      = "cjohannsen1981"
  vpc_security_group_ids = [aws_security_group.default.id]
  tags = {
    Name = "Jenkins"
  }
  subnet_id = aws_subnet.default.id

  provisioner "file" {
    source      = "app-server.sh"
    destination = "/tmp/app-server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "chmod +x /tmp/app-server.sh",
      "/tmp/app-server.sh ${aws_instance.jenkins.public_ip}"
    ]
  }

  provisioner "local-exec" {
    command = "ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' -u ubuntu --private-key /Users/cjohannsen/.ssh/cjohannsen1981.pem -i '${self.public_ip},'  master.yml --extra-vars 'hostname=${self.private_ip}'"
  }

  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("/Users/cjohannsen/.ssh/cjohannsen1981.pem")
  }
}


output "instance_ips" {
  value = ["${aws_instance.jenkins.*.public_ip}"]
}
