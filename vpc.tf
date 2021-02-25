resource "aws_vpc" "main_vpc" {
  #provider                         = aws.main-account
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = var.base_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    "Name" = "main_vpc"
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "internet_route" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "internet-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route"
  }
}

resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  vpc_id         = aws_vpc.main_vpc.id
  route_table_id = aws_route_table.internet_route.id
}

#TODO
#make count dynamic 
resource "aws_route_table_association" "private_route" {
    count = 2
    subnet_id = element(aws_subnet.private_subnet.*.id, count.index)
    route_table_id = aws_route_table.private.id
}

#need a nat gateway, route table, and then associate private subnets with the route table.
resource "aws_eip" "nat_gw_eip" {
  depends_on = [aws_internet_gateway.igw]
}

#TODO
#best practice would be to have a nat gateway in each public subnet, for now will just route through one
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.public_subnet.0.id
  depends_on    = [aws_internet_gateway.igw]
}

#TODO
#change count to be dynamic, will want to adjust this via a variable
resource "aws_subnet" "public_subnet" {
    count = 2
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.base_cidr, 8, count.index + 1)
    availability_zone = element(data.aws_availability_zones.azs.names, count.index)
    map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
    count = 2
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.base_cidr, 8, count.index + 3)
    availability_zone = element(data.aws_availability_zones.azs.names, count.index)
}





