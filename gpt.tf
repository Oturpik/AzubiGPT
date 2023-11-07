# Define the provider and AWS region
provider "aws" {
  region = "us-east-1"
}

# Create an IAM role for EC2 instances to access DynamoDB
resource "aws_iam_role" "dynamodb_access_role" {
  name = "dynamodb_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "dynamodb_access_policy_attachment" {
  name = "dynamodb_access_policy_attachment"

  roles = [aws_iam_role.dynamodb_access_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}


# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create two subnets in different availability zones
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Create a security group for the DynamoDB
resource "aws_security_group" "dynamodb_sg" {
  name        = "azubigptsgr"
  description = "DynamoDB Security Group"
  vpc_id      = aws_vpc.my_vpc.id

  # Ingress rule to allow access to DynamoDB
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a DynamoDB table
resource "aws_dynamodb_table" "my_table" {
  name           = "azubigpt"
  billing_mode  = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "question"
  range_key      = "response"
  
  attribute {
    name = "question"
    type = "S"
  }

  attribute {
    name = "response"
    type = "S"
  }

  # vpc_config {
  #   subnet_ids        = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  #   security_group_ids = [aws_security_group.dynamodb_sg.id]
  # }
  
}


# Launch an EC2 instance with the IAM role attached
resource "aws_instance" "azubigptinstance" {
  ami           = "ami-05c13eab67c5d8861"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id
  #iam_instance_profile = aws_iam_role.dynamodb_access_role.name

  # Additional EC2 instance configuration...
}

# # Output the DynamoDB endpoint and how to connect to it
# output "dynamodb_endpoint" {
#   value = aws_dynamodb_table.my_table.endpoint
# }

# output "dynamodb_connection_instructions" {
#   value = "To connect to the DynamoDB table, use AWS SDK or AWS CLI with appropriate credentials and the DynamoDB endpoint provided above."
# }
