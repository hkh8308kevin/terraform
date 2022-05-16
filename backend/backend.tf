terraform {
  backend "s3" {
   bucket = "terraform-up-and-running-state-kevin"
   key    = "global/s3/terraform.tfstate"
   region = "ap-northeast-2"
-------------
   dynamodb_table = "terraform-up-and-running-locks"
   billing_mode   = "PAY_PER_REQUEST" 
   hash_ key      = "LockID" 
   attribute { 
    name = "LockID" 
    type = "s" 
   } 
 }
}

------------
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
