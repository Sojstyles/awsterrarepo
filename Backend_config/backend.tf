#this will create a S3 bucket in AWS
resource "aws_s3_bucket" "terraform_state_s3" {
  #make sure you give unique bucket name
  bucket        = "terraform-mentordevops-state"
  force_destroy = true
  # Enable versioning to see full revision history of our state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#this Creates Dynamo Table
resource "aws_dynamodb_table" "terraform_locks" {
  # Give unique name for dynamo table name
  name         = "tf-state-run-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

#this will push tf.state file to remote s3 backend
terraform {
  backend "s3" {
    #Replace this with your bucket name!
    bucket = "terraform-mentordevops-state"
    key    = "dc/s3/terraform.tfstate"
    region = "us-east-1"
    #Replace this with your DynamoDB table name!
    dynamodb_table = "tf-state-run-locks"
    encrypt        = true
  }
}

