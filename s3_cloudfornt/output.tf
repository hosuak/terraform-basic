# Optional: cloudfront에서 정상 호출 되는지 확인하기 위해 CloudFront 도메인 출력
output "cf_domain" {
  value = aws_cloudfront_distribution.demo_cf.domain_name
}