resource "aws_s3_bucket" "tfstatefile" {
  bucket = "devops-remote-tfstatefile-filestate"

  tags = {
    Name        = "devops-remote-tfstatefile-filestate"
    Environment = "Dev"
  }
}