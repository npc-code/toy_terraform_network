resource "aws_vpc" "useast2_docker_example" {
  #provider                         = aws.main-account
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = var.base_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    "Name" = "useast2_docker_example"
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_internet_gateway" "igw-useast2" {
  vpc_id = aws_vpc.useast2_docker_example.id
}

resource "aws_route_table" "internet_route" {
  vpc_id = aws_vpc.useast2_docker_example.id
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

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.useast2_docker_example.id
  route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route"
  }
}

resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  vpc_id         = aws_vpc.useast2_docker_example.id
  route_table_id = aws_route_table.internet_route.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private.id
}

#need a nat gateway, route table, and then associate private subnets with the route table.
resource "aws_eip" "nat_gw_eip" {
  depends_on = [aws_internet_gateway.igw-useast2]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.igw-useast2]
}


resource "aws_subnet" "public_subnet_1" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.useast2_docker_example.id
  cidr_block        = cidrsubnet(var.base_cidr, 8, 1)
}


resource "aws_subnet" "public_subnet_2" {
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.useast2_docker_example.id
  cidr_block        = cidrsubnet(var.base_cidr, 8, 2)
}

resource "aws_subnet" "private_subnet_1" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.useast2_docker_example.id
  cidr_block        = cidrsubnet(var.base_cidr, 8, 3)
}


resource "aws_subnet" "private_subnet_2" {
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.useast2_docker_example.id
  cidr_block        = cidrsubnet(var.base_cidr, 8, 4)
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

output "private_subnet_1_id" {
  value = aws_subnet.private_subnet_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2.id
}

