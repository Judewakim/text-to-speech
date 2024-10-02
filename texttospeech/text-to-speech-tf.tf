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
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
  }
}

#Makes S3 bucket public
resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket = aws_s3_bucket.firstbucket.id

  block_public_acls   = false
  ignore_public_acls  = false
  block_public_policy = false
  restrict_public_buckets = false
}

#s3 bucket website config
resource "aws_s3_bucket_website_configuration" "firstbucketwebconfig" {
  bucket = aws_s3_bucket.firstbucket.id

  index_document {
    suffix = "index.html"
  }
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
          "s3:GetObject"
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

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "firstaiprojectfunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
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

output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/resource"
}


#presigned url for audio file bucket
