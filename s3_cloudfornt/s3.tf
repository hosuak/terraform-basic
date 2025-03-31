resource "aws_s3_bucket" "demo_bucket" {
    # bucket 생성 시 bucket name 뒤 hash값이 붙어 이름을 유일하게 함. 
    bucket_prefix = "demo-bucket"
    # bucket  삭제 시 해당 bucket의 object까지 함께 정리
    force_destroy = true
}

# s3 bucket의 public access 차단 - 보안강화
resource "aws_s3_bucket_public_access_block" "block_public_access" {
    bucket = aws_s3_bucket.demo_bucket.id

    #  public ACL을 차단(bucket = private)
    block_public_acls = true
    # public policy 차단
    block_public_policy = true
    # public ACL 무시
    ignore_public_acls = true
    # 다른 public bucket과 함께 사용되지 않도록 제한
    restrict_public_buckets = true
}

