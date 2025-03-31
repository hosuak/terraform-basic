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

# S3 버킷에 적용할 IAM 정책 문서를 정의
data "aws_iam_policy_document" "demo_policy_documnet" {
  # 정책의 단일 statement를 정의
  statement {
    # CloudFront 서비스에 대한 액세스를 허용하는 주체(principal)를 설정
    principals {
      type        = "Service"                      # 주체 유형: AWS 서비스
      identifiers = ["cloudfront.amazonaws.com"]   # CloudFront 서비스 식별자
    }

    # 허용할 액션을 정의합니다.
    actions = ["s3:GetObject"]                     # S3 객체 읽기(GetObject) 권한

    # 정책이 적용될 리소스를 정의합니다.
    resources = ["${aws_s3_bucket.demo_bucket.arn}/*"] # S3 버킷 내 모든 객체

    # 조건을 추가하여 정책의 적용 범위를 제한합니다.
    condition {
      test     = "StringEquals"                   # 조건 테스트 유형
      variable = "aws:SourceArn"                 # 조건 변수: 요청의 소스 ARN
      values   = [aws_cloudfront_distribution.demo_cf.arn] # CloudFront 배포 ARN
    }
  }
}

# S3 버킷 정책을 생성 및 iam 연결
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.demo_bucket.id                # 정책이 적용될 S3 버킷 ID
  policy = data.aws_iam_policy_document.demo_policy_documnet.json  # 위에서 정의한 IAM 정책 문서(JSON)
}

# s3 object resource 생성
resource "aws_s3_object" "demo_object" {
    bucket = aws_s3_bucket.demo_bucket.id

    key = "index.html"
    content = "Hello World"
    content_type = "text/html"
}