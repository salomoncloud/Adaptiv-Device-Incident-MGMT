import json
import boto3
import uuid
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
incidents_table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    # CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
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
        body = json.loads(event['body'])

        # Extract serial number from network_id field
        raw_network = body.get('network_id', '')
        network_parts = raw_network.split("|")
        network_id = network_parts[0].strip() if len(network_parts) > 0 else "unknown"
        serial_number = network_parts[1].strip() if len(network_parts) > 1 else "unknown"

        incident_id = str(uuid.uuid4())
        
        # Include all form fields
        item = {
            "incident_id": incident_id,
            "serial_number": serial_number,
            "network_id": network_id,
            "cpe_type": body.get('cpe_type', ''),
            "site_name": body.get('site_name', ''),
            "partner_name": body.get('partner_name', ''),
            "customer_name": body.get('customer_name', ''),
            "detected_at": body.get('detected_at', ''),
            "resolved_at": body.get('resolved_at', ''),
            "cause": body.get('cause', ''),
            "fix": body.get('fix', ''),
            "freshservice_ticket": body.get('freshservice_ticket', ''),
            "resolved_by": body.get('resolved_by', ''),
            "resolution_notes": body.get('resolution_notes', ''),
            "created_timestamp": datetime.utcnow().isoformat()
        }

        incidents_table.put_item(Item=item)

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"message": "Incident created successfully", "id": incident_id})
        }
        
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "headers": headers,
            "body": json.dumps({"error": "Invalid JSON in request body"})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)})
        }
