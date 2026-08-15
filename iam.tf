# IAM USERS & GROUPS DEFINITIONS
# Administrator and standard IAM users
resource "aws_iam_user" "administrator" {
    name = "administrator"
}

resource "aws_iam_user" "user_2" {
    name = "user_2"
}

resource "aws_iam_user" "user_3" {
    name = "user_3"
}

resource "aws_iam_user" "user_4" {
    name = "user_4"
}

resource "aws_iam_user" "user_5" {
    name = "user_5"
}

# IAM Groups for role-based access control
resource "aws_iam_group" "admin_group" {
    name = "admin_group"
}

resource "aws_iam_group" "normal_group_A" {
    name = "normal_group_A"
}

resource "aws_iam_group" "normal_group_B" {
    name = "normal_group_B"
}

# IAM GROUP MEMBERSHIPS
# Assigns administrator user to the admin group
resource "aws_iam_group_membership" "admin_group_membership" {
    name  = "admin-group-membership"
    users = [aws_iam_user.administrator.name]
    group = aws_iam_group.admin_group.name
}

# Assigns User 2 and 3 to Group A
resource "aws_iam_group_membership" "normal_group_A_membership" {
    name  = "normal-group-A-membership"
    users = [
        aws_iam_user.user_2.name,
        aws_iam_user.user_3.name
    ]
    group = aws_iam_group.normal_group_A.name
}

# Assigns User 4 and 5 to Group B
resource "aws_iam_group_membership" "normal_group_B_membership" {
    name  = "normal-group-B-membership"
    users = [
        aws_iam_user.user_4.name,
        aws_iam_user.user_5.name
    ]
    group = aws_iam_group.normal_group_B.name
}

# ADMIN POLICY & ATTACHMENT
# Grants full AWS access restricted strictly to the administrator's IP address
resource "aws_iam_policy" "admin_policy" {
    name        = "admin-policy"
    description = "Policy for admin group with full access to all AWS resources"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid    = "FullAccess"
                Effect = "Allow"
                Action = "*"
                Condition = {
                    IpAddress = {
                        "aws:SourceIp" = "${var.admin_ip}"
                    }
                }
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_policy_attachment" "admin_policy_attachment" {
    name       = "admin_policy_attachment"
    policy_arn = aws_iam_policy.admin_policy.arn
    groups     = [aws_iam_group.admin_group.name]
}

# GROUP A POLICY & ATTACHMENT (General Purpose EC2)
# Tag-based policy allowing management only for EC2 instances tagged as "General Purpose"
resource "aws_iam_policy" "normal_policy_A" {
    name        = "normal_policy_A"
    description = "Policy for normal group A with access to General Purpose EC2 instances and related resources"
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            # Read-only and tagging actions for instances with 'General Purpose' tag
            {
                Sid    = "AllowReadOnlyAndTaggingGlobaly"
                Effect = "Allow"
                Action = [
                    "ec2:DescribeInstances",
                    "ec2:DescribeInstanceStatus",
                    "ec2:DescribeTags",
                    "ec2:CreateTags",
                    "ec2:DeleteTags"
                ]
                Resource = "*"
                Condition = {
                    StringEquals = {
                        "ec2:ResourceTag/Type" = "General Purpose"
                    }
                }
            },
            # Instance state management actions restricted to 'General Purpose' tag
            {
                Sid    = "AllowOnlyGeneralPurposeEC2Instances"
                Effect = "Allow"
                Action = [
                    "ec2:StartInstances",
                    "ec2:StopInstances",
                    "ec2:RebootInstances"
                ]
                Resource = "arn:aws:ec2:*:*:instance/*"
                Condition = {
                    StringEquals = {
                        "ec2:ResourceTag/Type" = "General Purpose"
                    }
                }
            }
        ]
    })
}

resource "aws_iam_policy_attachment" "normal_policy_A_attachment" {
    name       = "normal_policy_A_attachment"
    policy_arn = aws_iam_policy.normal_policy_A.arn
    groups     = [aws_iam_group.normal_group_A.name]
}

# GROUP B POLICY & ATTACHMENT (Compute & Storage Optimized EC2)
# Tag-based policy allowing management only for Compute and Storage Optimized EC2 instances
resource "aws_iam_policy" "normal_policy_B" {
    name        = "normal_policy_B"
    description = "Policy for normal group B with access to Compute Optimized and Storage Optimized EC2 instances, but deny access to General Purpose EC2 instances"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            # Read-only and tagging permissions for Compute & Storage Optimized instances
            {
                Sid    = "AllowReadOnlyAndTaggingGlobaly"
                Effect = "Allow"
                Action = [
                    "ec2:DescribeInstances",
                    "ec2:DescribeInstanceStatus",
                    "ec2:DescribeTags",
                    "ec2:CreateTags",
                    "ec2:DeleteTags"
                ]
                Resource = "*"
                Condition = {
                    StringEquals = {
                        "ec2:ResourceTag/Type" = [
                            "Compute Optimized",
                            "Storage Optimized"
                        ]
                    }
                }
            },
            # Instance control permissions for Compute & Storage Optimized instances
            {
                Sid    = "AllowComputeOptimizedAndStorageOptimizedEC2Instances"
                Effect = "Allow"
                Action = [
                    "ec2:StartInstances",
                    "ec2:StopInstances",
                    "ec2:RebootInstances"
                ]
                Resource = "arn:aws:ec2:*:*:instance/*"
                Condition = {
                    StringEquals = {
                        "ec2:ResourceTag/Type" = [
                            "Compute Optimized",
                            "Storage Optimized"
                        ]
                    }
                }
            }
        ]
    })
}

resource "aws_iam_policy_attachment" "normal_policy_B_attachment" {
    name       = "normal_policy_B_attachment"
    policy_arn = aws_iam_policy.normal_policy_B.arn
    groups     = [aws_iam_group.normal_group_B.name]
}

# EC2 INSTANCE PROFILE & S3 ACCESS ROLE
# IAM Role allowing EC2 instances to assume AWS credentials securely
resource "aws_iam_role" "ec2_s3_access_role" {
    name = "ec2-s3-access-role"

    # Trust policy authorizing EC2 service to assume this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect    = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"            
            }
        ]
    })
}

# Policy allowing read access to all S3 buckets and encrypted write access via VPC Endpoint
resource "aws_iam_policy" "ec2_s3_access_policy" {
    name        = "ec2-s3-access-policy"
    description = "Policy to allow EC2 instances to access S3 buckets via specific VPC Endpoint"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            # Read permissions restricted to traffic passing through the specified S3 VPC Endpoint
            {
                Sid    = "AllowS3Access"
                Effect = "Allow"
                Action = [
                    "s3:ListBucket",
                    "s3:GetObject"
                ]
                Resource = [
                    "arn:aws:s3:::basic-storage-bucket-terraform-project",
                    "arn:aws:s3:::basic-storage-bucket-terraform-project/*"
                ]
                Condition = {
                    StringEquals = {
                        "aws:SourceVpce" = aws_vpc_endpoint.s3_vpc_endpoint.id
                    }
                }
            },
            # Encrypted write permissions restricted to specific bucket and VPC Endpoint
            {
                Sid    = "AllowS3WriteEncryptedFromSpecificVPCEndpoint"
                Effect = "Allow"
                Action = [
                    "s3:PutObject"
                ]
                Resource = "arn:aws:s3:::basic-storage-bucket-terraform-project/*"
                Condition = {
                    StringEquals = {
                        "aws:SourceVpce"                  = aws_vpc_endpoint.s3_vpc_endpoint.id
                        "s3:x-amz-server-side-encryption" = "aws:kms"
                    }
                }
            }
        ]
    })
}

# Instance profile container for passing the IAM role to EC2 instances
resource "aws_iam_instance_profile" "ec2_s3_access_instance_profile" {
    name = "ec2-s3-access-instance-profile"
    role = aws_iam_role.ec2_s3_access_role.name
}

# Attaches the S3 access policy to the EC2 IAM role
resource "aws_iam_role_policy_attachment" "ec2_s3_access_policy_attachment" {
    policy_arn = aws_iam_policy.ec2_s3_access_policy.arn
    role       = aws_iam_role.ec2_s3_access_role.name
}