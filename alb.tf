# 1. Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # İnternete açık olduğunu belirtiyoruz (Public)
  load_balancer_type = "application"

  # ALB'nin nerede yaşayacağı ve hangi güvenlik duvarını kullanacağı
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false # PoC olduğu için kolay silebilmek adına false yapıyoruz

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. Target Group (Hedef Havuzu)
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # ASG'nin sunucuları "Unhealthy" ilan etmek için baktığı yer burasıdır!
  health_check {
    path                = "/"   # Sunucunun ana dizinine istek atar
    healthy_threshold   = 2     # 2 kere başarılı olursa "Sağlıklı" der
    unhealthy_threshold = 2     # 2 kere hata alırsa "Çöktü" der ve ASG'ye haber verir
    timeout             = 3     # 3 saniye cevap bekle
    interval            = 10    # Her 10 saniyede bir kontrol et
    matcher             = "200" # Sadece HTTP 200 dönerse başarılı say
  }
}

# 3. Listener (Dinleyici)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. ASG ile Target Group'u Birbirine Bağlama (Attachment)
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  lb_target_group_arn    = aws_lb_target_group.app_tg.arn
}