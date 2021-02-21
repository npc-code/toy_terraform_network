resource "aws_vpc" "useast2_docker_example" {
    #provider                         = aws.main-account
    assign_generated_ipv6_cidr_block = false
    cidr_block                       = var.base_cidr
    enable_dns_hostnames             = true
    enable_dns_support               = true
    instance_tenancy                 = "default"
    tags                             = {
        "Name" = "useast2_docker_example"
    }
}

resource "aws_internet_gateway" "igw-useast2" {
  vpc_id   = aws_vpc.useast2_docker_example.id
  #tags = {
  #    Name = "main"
  #  }
}

resource "aws_route_table" "internet_route" {
  vpc_id   = aws_vpc.useast2_docker_example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-useast2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "internet-route-table"
  }
}

resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  vpc_id         = aws_vpc.useast2_docker_example.id
  route_table_id = aws_route_table.internet_route.id
}

data "aws_availability_zones" "azs" {
  state    = "available"
}

resource "aws_subnet" "public_subnet_1" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.useast2_docker_example.id
  #cidr_block        = "10.1.1.0/24"
  cidr_block = cidrsubnet(var.base_cidr, 8, 1)
}


resource "aws_subnet" "public_subnet_2" {
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.useast2_docker_example.id
  #cidr_block        = "10.1.2.0/24"
  cidr_block = cidrsubnet(var.base_cidr, 8, 2)
}


output "vpc_id" {
  value = aws_vpc.useast2_docker_example.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2.id
}

