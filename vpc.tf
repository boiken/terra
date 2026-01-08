resource "aws_vpc" "vpc_frankfurt" {
  cidr_block = local.cidr_frankfurt
  tags       = { Name = "VPC_frankfurt" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_frankfurt.id

  tags = {
    Name = "frankfurt-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_frankfurt.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "frankfurt-public-rt"
  }
}

resource "aws_subnet" "vpc_frankfurt_subnet1" {
  vpc_id                  = aws_vpc.vpc_frankfurt.id
  cidr_block              = local.cidr_frankfurt_subnet_1
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = { Name = "frankfurt-Subnet1 "
    "karpenter.sh/discovery" = local.cluster_name
  "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "vpc_frankfurt_subnet2" {
  vpc_id                  = aws_vpc.vpc_frankfurt.id
  availability_zone       = "eu-central-1b"
  cidr_block              = local.cidr_frankfurt_subnet_2
  map_public_ip_on_launch = true
  tags = { Name = "frankfurt-Subnet2 "
    "karpenter.sh/discovery" = local.cluster_name
  "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "vpc_frankfurt_subnet3" {
  vpc_id                  = aws_vpc.vpc_frankfurt.id
  availability_zone       = "eu-central-1c"
  cidr_block              = local.cidr_frankfurt_subnet_3
  map_public_ip_on_launch = true
  tags = { Name = "frankfurt-Subnet3 "
    "karpenter.sh/discovery" = local.cluster_name
  "kubernetes.io/role/elb" = "1" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.vpc_frankfurt_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.vpc_frankfurt_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.vpc_frankfurt_subnet3.id
  route_table_id = aws_route_table.public_rt.id
}
