# =============================================================
# Damolak_cloudwatch.tf — CloudWatch Log Groups & Alarms
# Project : Damolak DevOps Challenge
# =============================================================

# ── Log Groups — Jenkins ──────────────────────────────────────
resource "aws_cloudwatch_log_group" "jenkins_application" {
  name              = "/damolak/jenkins/application"
  retention_in_days = 7

  tags = {
    Name   = "damolak-jenkins-application-logs"
    Server = "jenkins"
  }
}

resource "aws_cloudwatch_log_group" "jenkins_userdata" {
  name              = "/damolak/jenkins/userdata"
  retention_in_days = 7

  tags = {
    Name   = "damolak-jenkins-userdata-logs"
    Server = "jenkins"
  }
}

# ── Log Groups — App Server ───────────────────────────────────
resource "aws_cloudwatch_log_group" "app_apache_access" {
  name              = "/damolak/app/apache-access"
  retention_in_days = 7

  tags = {
    Name   = "damolak-app-apache-access-logs"
    Server = "app"
  }
}

resource "aws_cloudwatch_log_group" "app_apache_error" {
  name              = "/damolak/app/apache-error"
  retention_in_days = 7

  tags = {
    Name   = "damolak-app-apache-error-logs"
    Server = "app"
  }
}

resource "aws_cloudwatch_log_group" "app_userdata" {
  name              = "/damolak/app/userdata"
  retention_in_days = 7

  tags = {
    Name   = "damolak-app-userdata-logs"
    Server = "app"
  }
}

# ── CloudWatch Alarms — Jenkins ───────────────────────────────
resource "aws_cloudwatch_metric_alarm" "jenkins_cpu_alarm" {
  alarm_name          = "${var.project_name}-jenkins-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Jenkins CPU utilization above 80%"

  dimensions = {
    InstanceId = aws_instance.damolak_jenkins_server.id
  }

  tags = {
    Name   = "${var.project_name}-jenkins-cpu-alarm"
    Server = "jenkins"
  }
}

# ── CloudWatch Alarms — App Server ───────────────────────────
resource "aws_cloudwatch_metric_alarm" "app_cpu_alarm" {
  alarm_name          = "${var.project_name}-app-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "App server CPU utilization above 80%"

  dimensions = {
    InstanceId = aws_instance.damolak_app_server.id
  }

  tags = {
    Name   = "${var.project_name}-app-cpu-alarm"
    Server = "app"
  }
}