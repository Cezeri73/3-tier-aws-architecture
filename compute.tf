# 1. Veri Kaynağı (Data Source): En güncel Amazon Linux 2023 imajını otomatik bulur
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Launch Template: Sunucunun DNA'sı
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # Daha önce oluşturduğumuz EC2 Security Group'u buraya bağlıyoruz
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Sunucu doğduğunda çalışacak olan "Hit Counter / PoC" script'i
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Sistemi güncelle ve Apache Web Server kur
              yum update -y
              yum install -y httpd
              
              # Servisi başlat
              systemctl start httpd
              systemctl enable httpd
              
              # Sunucunun kendi private IP'sini bul
              TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
              EC2_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
              
              # Web sayfasını oluştur (ALB'nin çalıştığını kanıtlamak için IP'yi basıyoruz)
              echo "<h1>Medresa Digital PoC - 3-Tier Architecture</h1>" > /var/www/html/index.html
              echo "<p>Response coming from EC2 Instance IP: <b>$EC2_IP</b></p>" >> /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-server"
    }
  }
}

# 3. Auto Scaling Group (ASG): Fabrika Yöneticisi
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id] # Sunucular Private odalarda doğacak

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  # Mülakatta konuştuğumuz o kritik ayar: ELB Health Check
  health_check_type         = "ELB"
  health_check_grace_period = 300 # Yeni doğan sunucuya nefes alması (script'i çalıştırması) için 5 dk süre ver

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}