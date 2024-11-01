#join the user running this script to the TextToSpeech IAM group (gives full access to APIGateway, S3, Lambda, IAM, Polly)
#adding index.html and bucket policy are done in uploads script

provider "aws" {
  region = "us-east-1"
}

#s3 bucket to hold website
resource "aws_s3_bucket" "firstbucket" {
  bucket = "bucketforfirstaiprojecttf"

  tags = {
    name = "texttospeechproject"
  }
}

#cors config for website bucket
resource "aws_s3_bucket_cors_configuration" "firstbucketcors" {
  bucket = aws_s3_bucket.firstbucket.id

  cors_rule {
    allowed_origins = ["*"]
    allowed_headers = [ "*" ]
    allowed_methods = ["GET", "PUT", "POST"]
  }
}

#Makes S3 bucket public
resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket = aws_s3_bucket.firstbucket.id

  block_public_acls   = true
  ignore_public_acls  = true
  block_public_policy = true
  restrict_public_buckets = true
}

#s3 bucket website config
resource "aws_s3_bucket_website_configuration" "firstbucketwebconfig" {
  bucket = aws_s3_bucket.firstbucket.id

  index_document {
    suffix = "index.html"
  }
}

#s3 bucket policy
resource "aws_s3_bucket_policy" "firstbucketpolicy" {
  bucket = aws_s3_bucket.firstbucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "${aws_cloudfront_origin_access_identity.oai.iam_arn}" //or just put back to Principal = {"*"}
        }
        Action    = [
          "s3:GetObject", 
          "s3:PutObject"
        ]
        Resource  = "${aws_s3_bucket.firstbucket.arn}/*"
      }
    ]
  })
}

#s3 bucket notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.firstbucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events = [ "s3:ObjectCreated:*" ]
    filter_suffix = ".txt"
  }

  depends_on = [ aws_lambda_permission.allow_bucket ]
}

# cloudfront distro
resource "aws_cloudfront_distribution" "distro" {
  origin {
    domain_name = "${aws_s3_bucket.firstbucket.bucket_regional_domain_name}"
    origin_id   = "S3-bucketforfirstaiprojecttf"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled      = true
  default_root_object  = "index.html"

  default_cache_behavior {
    target_origin_id       = "S3-bucketforfirstaiprojecttf"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# CloudFront distribution to serve index.html
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for accessing the S3 bucket"
}

#Lamda & IAM policy-- straight from lamda_function registry.terraform.io
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

# Define the IAM policy for the Lambda role
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda to access S3, logs, and Amazon Polly"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::bucketforfirstaiprojecttf/*",
          "arn:aws:s3:::audiostoragebucketforfirstaiprojecttf/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "logs:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "polly:*"
        Resource = "*"
      }
    ]
  })
}


# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "/workspace/text-to-speech/texttospeech/lambda_function_payload.zip"
  function_name = "firstaiprojectfunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"

  timeout = 10

  environment {
    variables = {
      foo = "bar"
    }
  }
}


#api gateway integration -- straight from registry.terraform.io 
resource "aws_api_gateway_rest_api" "api" {
  name = "texttospeechapi"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

#lambda permission with API Gateway REST API -- straight from registry.terraform.io
# resource "aws_api_gateway_rest_api" "firstaiprojectapitf" {
#   name = "texttospeechapi"
# }

module "api-gateway-enable-cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"
  
  api_id = aws_api_gateway_rest_api.api.id
  api_resource_id = aws_api_gateway_resource.resource.id

  allow_origin = "*"
  allow_methods = ["OPTIONS", "HEAD", "GET", "POST", "PUT"]
  allow_headers = ["*"]
}

#lambda trigger from web
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "firstaiprojectfunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

#lambda trigger from s3
resource "aws_lambda_permission" "allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.arn
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.firstbucket.arn
}

#get an api gateway stage to generate the url endpoint immediately

#another s3 bucket to store audio files 
resource "aws_s3_bucket" "audio_storage_bucket" {
  bucket = "audiostoragebucketforfirstaiprojecttf"

  tags = {
    name = "texttospeechproject"
  }
}

#cors config for audio file bucket
resource "aws_s3_bucket_cors_configuration" "audiostoragebucketcors" {
  bucket = aws_s3_bucket.audio_storage_bucket.id

  cors_rule {
    allowed_origins = ["*"]
    allowed_headers = [ "*" ]
    allowed_methods = ["GET", "PUT", "POST"]
  }
}

#Makes S3 bucket public
resource "aws_s3_bucket_public_access_block" "s3_audio_public_access" {
  bucket = aws_s3_bucket.audio_storage_bucket.id

  block_public_acls   = false
  ignore_public_acls  = false
  block_public_policy = false
  restrict_public_buckets = false
}

#S3 bucket policy for audio bucket
resource "aws_s3_bucket_policy" "audiostoragebucketpolicy" {
  bucket = aws_s3_bucket.audio_storage_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::audiostoragebucketforfirstaiprojecttf/*"
        }
    ]
}
)
}

output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/resource"
}
