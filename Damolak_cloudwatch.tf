# =============================================================
# Damolak_cloudwatch.tf — Production CloudWatch Logs, Metrics & Alerts
# Project : Damolak DevOps Challenge
# =============================================================

# =============================================================
# SNS ALERT TOPIC
# =============================================================
resource "aws_sns_topic" "damolak_alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.damolak_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =============================================================
# CLOUDWATCH LOG GROUPS — JENKINS
# =============================================================
resource "aws_cloudwatch_log_group" "jenkins_application" {
  name              = "/damolak/jenkins/application"
  retention_in_days = 30

  tags = {
    Name   = "damolak-jenkins-application-logs"
    Server = "jenkins"
  }
}

resource "aws_cloudwatch_log_group" "jenkins_userdata" {
  name              = "/damolak/jenkins/userdata"
  retention_in_days = 30

  tags = {
    Name   = "damolak-jenkins-userdata-logs"
    Server = "jenkins"
  }
}

# =============================================================
# CLOUDWATCH LOG GROUPS — APP SERVER
# =============================================================
resource "aws_cloudwatch_log_group" "app_apache_access" {
  name              = "/damolak/app/apache-access"
  retention_in_days = 30

  tags = {
    Name   = "damolak-app-apache-access-logs"
    Server = "app"
  }
}

resource "aws_cloudwatch_log_group" "app_apache_error" {
  name              = "/damolak/app/apache-error"
  retention_in_days = 30

  tags = {
    Name   = "damolak-app-apache-error-logs"
    Server = "app"
  }
}

resource "aws_cloudwatch_log_group" "app_userdata" {
  name              = "/damolak/app/userdata"
  retention_in_days = 30

  tags = {
    Name   = "damolak-app-userdata-logs"
    Server = "app"
  }
}

# =============================================================
# JENKINS CPU ALARM
# =============================================================
resource "aws_cloudwatch_metric_alarm" "jenkins_cpu_alarm" {
  alarm_name          = "${var.project_name}-jenkins-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Jenkins CPU above 80%"

  dimensions = {
    InstanceId = aws_instance.damolak_jenkins_server.id
  }

  alarm_actions             = [aws_sns_topic.damolak_alerts.arn]
  ok_actions                = [aws_sns_topic.damolak_alerts.arn]
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  tags = {
    Name   = "${var.project_name}-jenkins-cpu-alarm"
    Server = "jenkins"
  }
}

# =============================================================
# APP CPU ALARM
# =============================================================
resource "aws_cloudwatch_metric_alarm" "app_cpu_alarm" {
  alarm_name          = "${var.project_name}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "App Server CPU above 80%"

  dimensions = {
    InstanceId = aws_instance.damolak_app_server.id
  }

  alarm_actions             = [aws_sns_topic.damolak_alerts.arn]
  ok_actions                = [aws_sns_topic.damolak_alerts.arn]
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  tags = {
    Name   = "${var.project_name}-app-cpu-alarm"
    Server = "app"
  }
}

# =============================================================
# JENKINS STATUS CHECK ALARM
# =============================================================
resource "aws_cloudwatch_metric_alarm" "jenkins_status_alarm" {
  alarm_name          = "${var.project_name}-jenkins-status-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Jenkins instance failed AWS status checks"

  dimensions = {
    InstanceId = aws_instance.damolak_jenkins_server.id
  }

  alarm_actions             = [aws_sns_topic.damolak_alerts.arn]
  ok_actions                = [aws_sns_topic.damolak_alerts.arn]
  insufficient_data_actions = []
  treat_missing_data        = "breaching"
}

# =============================================================
# APP STATUS CHECK ALARM
# =============================================================
resource "aws_cloudwatch_metric_alarm" "app_status_alarm" {
  alarm_name          = "${var.project_name}-app-status-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "App instance failed AWS status checks"

  dimensions = {
    InstanceId = aws_instance.damolak_app_server.id
  }

  alarm_actions             = [aws_sns_topic.damolak_alerts.arn]
  ok_actions                = [aws_sns_topic.damolak_alerts.arn]
  insufficient_data_actions = []
  treat_missing_data        = "breaching"
}