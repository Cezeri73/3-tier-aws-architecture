# 1. Ana Sanal Veri Merkezi (VPC)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # EC2'ların DNS isimleri alabilmesi için şart
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. İnternet Kapısı (Internet Gateway) - Public subnet'ler için
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# 3. NAT Gateway İçin Sabit IP (Elastic IP)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

# 4. TIER 1: PUBLIC SUBNETS (Trafik Polisleri - Load Balancer burada yaşar)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # Buraya düşen her kaynağa otomatik Public IP ver
  tags                    = { Name = "${var.project_name}-public-1a" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-2b" }
}

# 5. NAT Gateway (Sadece Public Subnet 1a içine kurulur)
# Private Subnet'lerdeki sunucuların internetten paket indirebilmesi için tek yönlü çıkış kapısı.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "${var.project_name}-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

# 6. TIER 2: PRIVATE SUBNETS (Gizli Odalar - EC2'lar burada yaşar)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.11.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-private-1a" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.12.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "${var.project_name}-private-2b" }
}

# 7. TIER 3: DATA SUBNETS (Veritabanı Kasası - En Sıkı İzolasyon)
resource "aws_subnet" "data_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.21.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-data-1a" }
}

resource "aws_subnet" "data_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.22.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "${var.project_name}-data-2b" }
}

# 8. ROUTE TABLES (Trafik Tabelaları)
# Public Route Table: Doğrudan Internet Gateway'e fırlatır
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# Private Route Table: İnternet çıkışlarını NAT Gateway'e fırlatır
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

# 9. ROUTE TABLE ASSOCIATIONS 
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}
# DİKKAT: Data subnet'leri için herhangi bir Route Table ataması YAPMADIK.