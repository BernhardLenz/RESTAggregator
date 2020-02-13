resource "aws_vpc" "this" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "10.0.0.0/16"
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    "Name" = "RestAggUsE1Vpc"
  }
}

resource "aws_subnet" "PrivateSubnetA" {
  vpc_id = aws_vpc.this.id

  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1a"
  cidr_block                      = "10.0.0.0/24"
  map_public_ip_on_launch         = false
  tags = {
    "Name" = "RestAggUsE1APrivateSubnet"
  }
}

resource "aws_subnet" "PrivateSubnetB" {
  vpc_id = aws_vpc.this.id

  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1b"
  cidr_block                      = "10.0.1.0/24"
  map_public_ip_on_launch         = false
  tags = {
    "Name" = "RestAggUsE1BPrivateSubnet"
  }
}

resource "aws_subnet" "PublicSubnetA" {
  vpc_id = aws_vpc.this.id

  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1a"
  cidr_block                      = "10.0.128.0/24"
  map_public_ip_on_launch         = true
  tags = {
    "Name" = "RestAggUsE1APublicSubnet"
  }
}

resource "aws_subnet" "PublicSubnetB" {
  vpc_id = aws_vpc.this.id

  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1b"
  cidr_block                      = "10.0.129.0/24"
  map_public_ip_on_launch         = true
  tags = {
    "Name" = "RestAggUsE1BPublicSubnet"
  }
}


resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "RestAggUsE1VpcInternetGateway"
  }
}



resource "aws_eip" "PublicSubnetANatGatewayEip" {
  vpc  = true
  tags = { "Name" = "RestAggUsE1APublicSubnetNatGatewayEip" }
}

resource "aws_eip" "PublicSubnetBNatGatewayEip" {
  vpc  = true
  tags = { "Name" = "RestAggUsE1BPublicSubnetNatGatewayEip" }
}



resource "aws_nat_gateway" "PublicSubnetANatGateway" {
  subnet_id     = aws_subnet.PublicSubnetA.id
  allocation_id = aws_eip.PublicSubnetANatGatewayEip.id
  depends_on    = [aws_internet_gateway.this]
  tags = {
    "Name" = "RestAggUsE1APublicSubnetNATGateway"
  }
}

resource "aws_nat_gateway" "PublicSubnetBNatGateway" {
  subnet_id     = aws_subnet.PublicSubnetB.id
  allocation_id = aws_eip.PublicSubnetBNatGatewayEip.id
  depends_on    = [aws_internet_gateway.this]
  tags = {
    "Name" = "RestAggUsE1BPublicSubnetNATGateway"
  }
}


resource "aws_route_table" "PublicSubnetRouteTable" {
  vpc_id = aws_vpc.this.id
  route = [
    {
      cidr_block                = "0.0.0.0/0"
      gateway_id                = aws_internet_gateway.this.id
      nat_gateway_id            = ""
      ipv6_cidr_block           = ""
      egress_only_gateway_id    = ""
      instance_id               = ""
      network_interface_id      = ""
      transit_gateway_id        = ""
      vpc_peering_connection_id = ""
    },
  ]
  tags = {
    "Name" = "RestAggUsE1VpcPublicRouteTable"
  }
}
resource "aws_route_table" "PrivateSubnetARouteTable" {
  vpc_id = aws_vpc.this.id
  route = [
    {
      cidr_block                = "0.0.0.0/0"
      nat_gateway_id            = aws_nat_gateway.PublicSubnetANatGateway.id
      gateway_id                = ""
      ipv6_cidr_block           = ""
      egress_only_gateway_id    = ""
      instance_id               = ""
      network_interface_id      = ""
      transit_gateway_id        = ""
      vpc_peering_connection_id = ""
    },
  ]
  tags = {
    "Name" = "RestAggUsE1APrivateRouteTable"
  }
}
resource "aws_route_table" "PrivateSubnetBRouteTable" {
  vpc_id = aws_vpc.this.id
  route = [
    {
      cidr_block                = "0.0.0.0/0"
      nat_gateway_id            = aws_nat_gateway.PublicSubnetBNatGateway.id
      gateway_id                = ""
      ipv6_cidr_block           = ""
      egress_only_gateway_id    = ""
      instance_id               = ""
      network_interface_id      = ""
      transit_gateway_id        = ""
      vpc_peering_connection_id = ""
    },
  ]
  tags = {
    "Name" = "RestAggUsE1BPrivateRouteTable"
  }
}

resource "aws_route_table_association" "PublicRouteTablePublicSubnetAAssociation" {
  subnet_id      = aws_subnet.PublicSubnetA.id
  route_table_id = aws_route_table.PublicSubnetRouteTable.id
}

resource "aws_route_table_association" "PublicRouteTablePublicSubnetBAssociation" {
  subnet_id      = aws_subnet.PublicSubnetB.id
  route_table_id = aws_route_table.PublicSubnetRouteTable.id
}

resource "aws_route_table_association" "PrivateRouteTableAPrivateSubnetAAssociation" {
  subnet_id      = aws_subnet.PrivateSubnetA.id
  route_table_id = aws_route_table.PrivateSubnetARouteTable.id
}

resource "aws_route_table_association" "PrivateRouteTableBPrivateSubnetBAssociation" {
  subnet_id      = aws_subnet.PrivateSubnetB.id
  route_table_id = aws_route_table.PrivateSubnetBRouteTable.id
}

resource "aws_vpc_endpoint" "this" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.us-east-1.s3"
  tags = {
    "Name" = "RestAggUsE1VpcS3Endpoint"
  }
}
