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
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
  }
}

#WILL MANUALLY CONFIGURE BUCKET POLICY

#s3 bucket website config
resource "aws_s3_bucket_website_configuration" "firstbucketwebconfig" {
  bucket = aws_s3_bucket.firstbucket.id

  index_document {
    suffix = "index.html"
  }
}

#WILL MANUALLY ADD HTML FILE INTO BUCKET

# #s3 put file into first bucket
# resource "aws_s3_object" "uploadfiletofirstbucket" {
#     bucket = aws_s3_bucket.firstbucket.id
#     key = "index.html" /*MIGHT HAVE TO MANUALLY ENTER KEY VALUE*/
#     source = "C/Users/wjude/aws-projects/calculator/index.html"

#     etag = filemd5("C//Users//wjude//aws-projects//calculator//index.html")/*ENTER PATH TO INDEX.HTML FILE BETWEEN THE PARANTHESIS*/

#     tags = {
#       "name" = "texttospeechproject"
#     }
# }


#Lamda & IAM policy-- straight for lamda_function registry.terraform.io
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

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "C:/Users/wjude/aws-projects/text-to-speech-tf/lambda_function_payload.zip"
  function_name = "firstaiprojectfunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"

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

#lambda permission with API Gateway REST API -- straight from registry.terraform.io
# resource "aws_api_gateway_rest_api" "firstaiprojectapitf" {
#   name = "texttospeechapi"
# }

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

#WILL MANUALLY CONFIGURE BUCKET POLICY

#presigned url for audio file bucket
