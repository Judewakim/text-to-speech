# imports
import boto3
import os
import json
import io




def text_to_speech(text):
    polly = boto3.client('polly')
    
    response = polly.synthesize_speech(
        Text=text,
        OutputFormat='mp3',
        VoiceId='Joanna'
    )
    
    audio_stream = response['AudioStream'].read()
    
    return audio_stream
    
def upload_to_s3(bucket_name, key, data):
    s3 = boto3.client('s3')
    s3.put_object(
        Bucket=bucket_name,
        Key=key,
        Body=data
    )
    url = f"https://{bucket_name}.s3.amazonaws.com/{key}"
    
    return url

def lambda_handler(event, context):
    # Get the user input and selected voice from the event
    userText = event['body']
    # voice = event['voice']

    audio_stream = text_to_speech(userText)


    # Upload the audio file to S3

    bucket_name = 'audiostoragebucketforfirstaiprojecttf'
    key = 'audiofile.mp3'
    
    upload_to_s3(bucket_name, key, audio_stream)
    
    file_url = f"https://{bucket_name}.s3.amazonaws.com/{key}"


    # # Generate a pre-signed URL for the audio file
    # url = s3.generate_presigned_url(
    #     ClientMethod='get_object',
    #     Params={'Bucket': bucket_name, 'Key': key},
    #     ExpiresIn=3600  # URL expires in 1 hour
    # )

    return {
        'statusCode': 200,
        'body': file_url
    }

# import json
# import boto3
# from boto3 import Session


# bucket_name = "text-to-speech-nnigrveq890f"
# object_key = "text-to-speech/polly-audio-file.mp3"

# def generateAudioUsingText(plainText,filename):
    
#     #Generate audio using text
#     session = Session(region_name="us-east-1")
#     polly = session.client("polly")
#     response = polly.synthesize_speech( Text=plainText,
#                                         TextType = "text",
#                                         OutputFormat="mp3",
#                                         VoiceId="Joanna")
                                        
#     s3 = session.resource('s3')
#     # bucket_name = "text-to-speech-nnigrveq890f"
#     bucket = s3.Bucket(bucket_name)
#     filename = "text-to-speech/" + filename
#     stream = response["AudioStream"]
#     bucket.put_object(Key=filename, Body=stream.read())
    
    
# def generate_presigned_url(bucket_name, object_key, expiration=3600):
#     """
#     Generate a pre-signed URL for accessing an S3 object.
    
#     :param bucket_name: The name of the S3 bucket.
#     :param object_key: The key of the S3 object.
#     :param expiration: The expiration time for the URL in seconds (default: 1 hour).
#     :return: The pre-signed URL.
#     """
#     s3_client = boto3.client('s3')
#     url = s3_client.generate_presigned_url(
#         'get_object',
#         Params={'Bucket': bucket_name, 'Key': object_key},
#         ExpiresIn=expiration
#     )
#     return url
    
    
# def lambda_handler(event, context):
    
#     request_body = json.loads(event["body"])
#     userText = request_body.get("text", "")
    
#     #Generate audio using text
#     generateAudioUsingText(userText, 'polly-audio-file.mp3')
    
#     #Generate presigned URL
#     presigned_url = generate_presigned_url(bucket_name, object_key)
    
#     return {
#         'statusCode': 200,
#         'headers': {
#             "Access-Control-Allow-Origin": "*",
#             "Access-Control-Allow-Headers": "Content-Type",
#             "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
#             },
            
#         'body': json.dumps(userText)
#     }


