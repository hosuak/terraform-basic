
# S3 버킷에 대한 접근 제어를 구성하여 CloudFront 배포와 S3 간의 보안 연결을 설정
resource "aws_cloudfront_origin_access_control" "demo_origin_access_control" {
  name                              = "demo-oac" # OAC 이름
  origin_access_control_origin_type = "s3"       # 오리진 유형(S3 버킷)
  signing_behavior                  = "always"   # 항상 요청 서명
  signing_protocol                  = "sigv4"    # 서명 프로토콜 버전
}

# CloudFront 배포 구성
resource "aws_cloudfront_distribution" "demo_cf" {
  enabled             = true         # CloudFront 배포 활성화
  default_root_object = "index.html" # 기본 루트 객체 지정

  # 오리진 설정 (S3 버킷 연결)
  origin {
    origin_id                = aws_s3_bucket.demo_bucket.id                                       # 오리진 식별자
    domain_name              = aws_s3_bucket.demo_bucket.bucket_regional_domain_name              # S3 지역 도메인
    origin_access_control_id = aws_cloudfront_origin_access_control.demo_origin_access_control.id # OAC ID
  }

  # 기본 캐싱 동작 설정
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"] # 허용 HTTP 메소드
    cached_methods  = ["GET", "HEAD"] # 캐싱 대상 메소드

    cache_policy_id  = data.aws_cloudfront_cache_policy.demo_cache_policy.id
    target_origin_id = aws_s3_bucket.demo_bucket.id # 대상 오리진 지정

    viewer_protocol_policy = "redirect-to-https" # HTTPS 강제 리다이렉트
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # 지역 제한 없음(전체 허용)
    }
  }

  # 뷰어 인증서 설정
  viewer_certificate {
    cloudfront_default_certificate = true # CloudFront 기본 SSL 인증서 사용
  }
}

# AWS 관리형 캐시 정책 조회
# "Managed-CachingOptimized" 정책은 성능 최적화를 위한 기본 캐싱 설정을 제공
data "aws_cloudfront_cache_policy" "demo_cache_policy" {
  name = "Managed-CachingOptimized"
}
