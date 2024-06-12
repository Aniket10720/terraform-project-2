#created awc vpc using terraform 

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }

} 

#created public subnet using terraform 

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public subnet"
  }

}

#created private subnet using terraform 

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "private subnet"
  }
}

#created internet getway using terraform 

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }

}

#created rout table and route table association using terraform 

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

#created security group using terraform 
resource "aws_security_group" "ssh_acsses" {
  name   = "ssh_acsses"
  vpc_id = aws_vpc.main.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

#created elastic ip using terraform 
resource "aws_eip" "eip" {
  instance = aws_instance.web_server.id

  tags = {
    Name = "test-eip"
  }

}

#created aws ec2 instance using terraform 
resource "aws_instance" "web_server" {
  ami                         = "ami-00fa32593b478ad6e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key-tf.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ssh_acsses.id]




  #script 
  user_data = <<-EOF
#!/bin/bash
# Update the package list
sudo yum update -y

# Install httpd
sudo yum install -y httpd

# Create a simple HTML file
cat <<'HTML' > /var/www/html/index.html
<!DOCTYPE html>
<html>
  <body><h1>Welcome to my website</h1></body>
</html>
HTML

# Restart httpd to apply changes
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl restart httpd
EOF

} 

#ssh_key 
resource "aws_key_pair" "key-tf" {
  key_name   = "terraform-key"
  public_key = file("${path.module}/terraform-key.pub")
}
output "terraform-key" {
  value = "aws_key_pair.terraform-key.key_name"
}
