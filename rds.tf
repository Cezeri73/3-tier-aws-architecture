# 1. DB Subnet Group: RDS'in yerleşebileceği odaların haritası
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.data_1.id, aws_subnet.data_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. Terraform Aracılığıyla Güvenli ve Rastgele Şifre Üretimi
# Bu kaynak, bizim yerimize kimsenin tahmin edemeyeceği 16 karakterlik bir şifre üretir.
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # PostgreSQL'in seveceği özel karakterler
}

# 3. AWS Secrets Manager Kasası Oluşturma
# AWS üzerinde şifreleri saklayacağımız gizli bir kasa (kutu) açıyoruz.
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.project_name}-db-credentials-new" # İsim çakışmaması için benzersiz yaptık
  recovery_window_in_days = 0                                        # PoC bittiğinde kasayı anında silebilmek için (Normalde 7-30 gündür)
}

# 4. Üretilen Şifreyi Kasaya Kilitleme (Secret Value)
# Kasanın içine kullanıcı adı ve ürettiğimiz rastgele şifreyi JSON formatında koyuyoruz.
resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
  })
}

# 5. RDS PostgreSQL Instance: Üretim Ortamı Tasarımı
resource "aws_db_instance" "postgres" {
  identifier        = "db-${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro" # Test ortamı bütçesi için bunu tutuyoruz
  allocated_storage = 20

  db_name = "medresadb"

  # ŞİFRELER ARTIK GÜVENDE!
  # Şifreyi ve kullanıcı adını yukarıdaki güvenli kaynaklardan dinamik besliyoruz.
  username = jsondecode(aws_secretsmanager_secret_version.db_secret_val.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.db_secret_val.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  #  ARTIK HIGH AVAILABLE!
  # Bu parametre true olduğunda AWS, primary veritabanı çökerse AZ-b'deki standby'ı saniyeler içinde devreye alır.
  multi_az = true

  tags = {
    Name = "db-${var.project_name}-postgres-prod"
  }
}