# modules/vpc/main.tf
# A simple network: one VPC, an internet gateway, and public subnets in
# two availability zones (AZs), all routed to the internet.
#
# Design choice: the app runs in PUBLIC subnets with public IPs, so it
# can pull images from ECR without a NAT gateway. A NAT gateway costs
# about $35+/month, which is a lot for a learning project. The app is
# still protected, because its security group only accepts traffic from
# the load balancer. In production you'd usually put tasks in private
# subnets behind a NAT gateway or VPC endpoints.

# Ask AWS which AZs exist in this region, instead of hardcoding names
# like eu-west-2a. Makes the module work in any region.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # DNS support lets resources inside the VPC resolve AWS service names
  # (like the ECR endpoint). Both should almost always be on.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name}-vpc" }
}

# The internet gateway is the VPC's door to the internet.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-igw" }
}

# One public subnet per AZ. count creates N copies of this resource.
# cidrsubnet() carves the VPC range into smaller /24 blocks:
#   10.0.0.0/16 -> 10.0.0.0/24, 10.0.1.0/24, ...
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.name}-public-${data.aws_availability_zones.available.names[count.index]}" }
}

# A route table decides where traffic goes. This one sends all
# non-local traffic (0.0.0.0/0) to the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-public-rt" }
}

# Attach the route table to each public subnet. This is what actually
# makes a subnet "public".
resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
