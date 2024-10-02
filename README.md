# AWS Text to Speech tool 
This text to speech tool takes a text file and turns it into an audio file using AWS services including S3, Amazon Polly, Lambda, and many more. This project will be continously released in multiple versions. The end result will (hopefully) be a fully functional, publicly accessible tool found on my website (which is not available right now because it cost money I do not want to spend but would/will be available at wakim-works.com).
______________________________
-The first version requires, once terraform is applied, the uploads script to be run which requests the file that will be turned to speech. Once that file is successfully uploaded, the second bucket (audiostoragebucketforfirstaiprojecttf) will contain the audio file.
<br>
<br>
-The second version will do this all through the index.html file
<br>
<br>
-The third version will secure things down more using a presigned url instead of having the s3 bucket publicly accessible
<br>
<br>
-The fourth version will use Cognito to create an account before getting access to the webpage
<br>
<br>
-The fifth version will have a paywall and will connect a form of payment to the Cognito account (idk the payment structure yet and idk how that really works yet)
<br>
<br>
-The sixth version will have a nice URL and will use HTTPS, finalizing the project
<br>
<br>
The next build of this project will translate the text to into another language. Then the next build after that will translate the text into another language then create an audio file of the translated text
<br>
<br>
