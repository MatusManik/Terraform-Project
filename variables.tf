variable "aws_region" {
    description = "AWS Region, where infrastructure will be created."
    type = string
    default = "eu-central-1" 
}

variable "ami_id" {
    description = "ID of AMI for EC2 instances."
    type = string
    default = "ami-0c55b159cbfafe1f0"

}

variable "admin_ip" {
  description = "IP address for SSH access of administrator"
  type        = string
  default     = "203.0.113.41/32"
}