# HIGH CPU ALARM
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {

    alarm_name = "high-cpu-alarm"

    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = 120
    statistic = "Average"
    threshold = 70

    alarm_description = "Scale out when CPU is above 70 percent"

      alarm_actions = [
    aws_autoscaling_policy.scale_out_policy.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_server_asg.name
  }  
}

# LOW CPU ALARM
resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {

  alarm_name = "low-cpu-alarm"

  comparison_operator = "LessThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 30

  alarm_description = "Scale in when CPU is below 20 percent"

  alarm_actions = [
    aws_autoscaling_policy.scale_in_policy.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_server_asg.name
  }
}