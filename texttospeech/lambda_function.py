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
    # Get the bucket name and object key from the S3 event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']

    # Initialize S3 client
    s3 = boto3.client('s3')
    
    # Retrieve the uploaded object
    response = s3.get_object(Bucket=bucket_name, Key=object_key)
    text_content = response['Body'].read().decode('utf-8')  # Read and decode the text

    # Use the text content for text-to-speech
    audio_stream = text_to_speech(text_content)

    # Upload the audio file to S3
    audio_bucket_name = 'audiostoragebucketforfirstaiprojecttf'
    audio_key = f'audio_text_files/{object_key.split("/")[-1].replace(".txt", ".mp3")}'  # Match to the index.html JavaScript AudioFileKey

    upload_to_s3(audio_bucket_name, audio_key, audio_stream)
    
    file_url = f"https://{audio_bucket_name}.s3.amazonaws.com/{audio_key}"

    # # Generate a pre-signed URL for the audio file
    # url = s3.generate_presigned_url(
    #     ClientMethod='get_object',
    #     Params={'Bucket': bucket_name, 'Key': key},
    #     ExpiresIn=3600  # URL expires in 1 hour
    # )


    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Audio file created successfully', 'url': file_url})
    }
    