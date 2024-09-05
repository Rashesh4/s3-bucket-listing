import os
from flask import Flask, jsonify
import boto3
from botocore.exceptions import ClientError
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

app = Flask(__name__)
s3 = boto3.client('s3')
BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')

def get_s3_contents(path):
    """Retrieve contents of S3 bucket at given path."""
    try:
        # Ensure the path ends with a '/' if it's not empty
        if path and not path.endswith('/'):
            path += '/'

        response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=path, Delimiter='/')
        
        # Check if the path exists
        if 'Contents' not in response and 'CommonPrefixes' not in response:
            if path == '':  # Root path
                return []
            return None  # Path doesn't exist

        # Get files (excluding the directory object itself)
        files = [obj['Key'][len(path):] for obj in response.get('Contents', [])
                 if obj['Key'] != path]

        # Get subdirectories
        directories = [prefix['Prefix'][len(path):].rstrip('/')
                       for prefix in response.get('CommonPrefixes', [])]

        return directories + files

    except ClientError as e:
        app.logger.error(f"Error accessing S3: {e}")
        raise

@app.route('/list-bucket-content', defaults={'path': ''})
@app.route('/list-bucket-content/<path:path>')
def list_bucket_content(path):
    try:
        content = get_s3_contents(path)
        if content is None:
            return jsonify({'error': 'Path not found'}), 404
        return jsonify({'content': content})
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchBucket':
            return jsonify({'error': 'Bucket not found'}), 404
        return jsonify({'error': 'S3 error occurred'}), 500
    except Exception as e:
        app.logger.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': 'An unexpected error occurred'}), 500

if __name__ == '__main__':
    app.run(debug=True)
