import json
import boto3
import os
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key, Attr

# Get environment variables
dynamodb = boto3.resource('dynamodb')
incidents_table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    # CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Content-Type': 'application/json'
    }
    
    # Handle preflight OPTIONS request
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }
    
    try:
        # Get serial number from query string
        query_params = event.get("queryStringParameters") or {}
        serial_number = query_params.get("serial_number")
        
        if not serial_number:
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "Missing serial_number parameter"})
            }

        # Calculate 12 months ago
        one_year_ago = datetime.utcnow() - timedelta(days=365)

        # Scan for incidents related to this serial
        response = incidents_table.scan(
            FilterExpression=Attr("serial_number").eq(serial_number)
        )
        all_items = response.get("Items", [])

        # Filter incidents from the past year
        filtered = [
            i for i in all_items
            if "detected_at" in i and i["detected_at"] and
               parse_date(i["detected_at"]) >= one_year_ago
        ]

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "serial_number": serial_number,
                "incident_count": len(filtered),
                "recent_incidents": filtered
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)})
        }

def parse_date(date_str):
    """Attempt to parse datetime-local format and ISO formats"""
    if not date_str:
        return datetime.min
        
    try:
        # Handle datetime-local format (YYYY-MM-DDTHH:MM)
        if 'T' in date_str and len(date_str) == 16:
            return datetime.strptime(date_str, '%Y-%m-%dT%H:%M')
        # Handle ISO format
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
        return datetime.min
