# S3 BUCKET DEFINITION
# S3 bucket for general storage and application data
resource "aws_s3_bucket" "basic_storage_bucket" {
    bucket = "basic-storage-bucket-terraform-project"

    tags = {
        Name        = "Basic-Storage-Bucket"
        Environment = "Dev"
    }
}

# S3 VPC ENDPOINT (GATEWAY)
# Allows EC2 instances in private subnets to access S3 securely 
# via the internal AWS network without going through the public internet
resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
    vpc_id            = aws_vpc.main_vpc.id
    service_name      = "com.amazonaws.eu-central-1.s3"
    vpc_endpoint_type = "Gateway"

    # Automatically routes S3 traffic from the private subnet through this endpoint
    route_table_ids   = [aws_route_table.private_route_table.id]
}