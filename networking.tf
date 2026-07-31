# 1. MAIN VPC
# Create the Virtual Private Cloud (VPC)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Main-Virtual-Network"
  }
}

# 2. PUBLIC SUBNETS
# Public Subnet 1 in availability zone eu-central-1a
resource "aws_subnet" "public_subnet_one" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.16.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1"
  }
}

# Public Subnet 2 in availability zone eu-central-1b (for High Availability)
resource "aws_subnet" "public_subnet_two" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.16.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2"
  }
}

# 3. PRIVATE SUBNETS
# Private Subnet 1 in availability zone eu-central-1a
resource "aws_subnet" "private_subnet_one" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.16.3.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet-1"
  }
}

# Private Subnet 2 in availability zone eu-central-1b
resource "aws_subnet" "private_subnet_two" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.16.4.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet-2"
  }
}

# 4. INTERNET GATEWAY
# Gateway enabling communication between the VPC and the internet
resource "aws_internet_gateway" "the_internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main-Internet-Gateway"
  }
}

# 5. ROUTE TABLES
# Route table for public subnets (routes IPv4 and IPv6 traffic to the Internet Gateway)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.the_internet_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.the_internet_gateway.id
  }
}

# Route table for private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
}

# 6. ROUTE TABLE ASSOCIATIONS
# Associate public subnets with the public route table
resource "aws_route_table_association" "public_subnet_one_association" {
  subnet_id      = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_two_association" {
  subnet_id      = aws_subnet.public_subnet_two.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_subnet_one_association" {
  subnet_id      = aws_subnet.private_subnet_one.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_two_association" {
  subnet_id      = aws_subnet.private_subnet_two.id
  route_table_id = aws_route_table.private_route_table.id
}