provider "aws" {
  access_key = "AKIAI6KY2NIYSF25LLRQ"
  secret_key = "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"
  region     = "us-east-1"
}

## 1. Create VPC
# -------------------------------
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-main"
  }
}

## 2. Create Internet Gateway
#----------------------------------
resource "aws_internet_gateway" "myGateWay" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "IGW-main"
  }
}


## 3. Create a Subnet Table (first)
#----------------------------------
resource "aws_subnet" "mySubnet" {
  vpc_id            = aws_vpc.myVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet-main1"
  }
}




## 4. Create Security group to allow port 22, 80, 443
#-----------------------------------------------------
resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


## 5. Create AWS Instance with volume 
#-----------------------------------------------------
resource "aws_instance" "MyInstance" {
  ami                    = "ami-0947d2ba12ee1ff75"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.mySubnet.id
  key_name               = "main-key"
  tags = {
    Name = "LinuxMachine"
  }
}


## 5. Create EBS volume
#-----------------------------------------------------
resource "aws_ebs_volume" "dataVolume" {
  availability_zone = "us-east-1a"
  size              = 1
  tags = {
    Name = "data-volume"
  }

}

## 5. Attach EBS volume to instance
#-----------------------------------------------------
resource "aws_volume_attachment" "first-vol" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.dataVolume.id
  instance_id = aws_instance.MyInstance.id

}


## 8. Assign an elastic IP  
#----------------------------------------------------------
resource "aws_eip" "myEIP" {
  instance = aws_instance.MyInstance.id
  vpc      = true
}
output "server_public_ip" {
  value = aws_eip.myEIP.public_ip
}




## 8. Create a Load Balancer
#----------------------------------------------------------
resource "aws_lb" "MyLoadBalancer" {
  name               = "lb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [aws_subnet.mySubnet.id, aws_subnet.mySubnet2.id]

  tags = {
    Name = "DevOps"
  }
}
