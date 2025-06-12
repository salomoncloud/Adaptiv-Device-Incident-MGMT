import json
import boto3
import os
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key, Attr

# Get environment variables
dynamodb = boto3.resource('dynamodb')
incidents_table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    try:
        # Get serial number from query string
        serial_number = event.get("queryStringParameters", {}).get("serial_number")
        if not serial_number:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing serial_number"})
            }

        # Calculate 12 months ago
        one_year_ago = datetime.utcnow() - timedelta(days=365)

        # Scan for incidents related to this serial
        response = incidents_table.scan(
            FilterExpression=Attr("serial_number").eq(serial_number)
        )
        all_items = response.get("Items", [])

        # Filter in Python (you could use a sort key if you had a date column as key)
        filtered = [
            i for i in all_items
            if "detected_at" in i and
               parse_date(i["detected_at"]) >= one_year_ago
        ]

        return {
            "statusCode": 200,
            "body": json.dumps({
                "serial_number": serial_number,
                "incident_count": len(filtered),
                "recent_incidents": filtered
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

def parse_date(date_str):
    """Attempt to parse ISO 8601-style timestamp"""
    try:
        return datetime.fromisoformat(date_str)
    except ValueError:
        return datetime.min
