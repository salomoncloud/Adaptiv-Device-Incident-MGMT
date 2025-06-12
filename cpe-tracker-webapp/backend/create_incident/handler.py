import json
import boto3
import uuid
import os

dynamodb = boto3.resource('dynamodb')
incidents_table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    body = json.loads(event['body'])

    # Extract serial number from network_id field
    raw_network = body.get('network_id', '')
    network_parts = raw_network.split("|")
    network_id = network_parts[0].strip() if len(network_parts) > 0 else "unknown"
    serial_number = network_parts[1].strip() if len(network_parts) > 1 else "unknown"

    incident_id = str(uuid.uuid4())
    item = {
        "incident_id": incident_id,
        "serial_number": serial_number,
        "network_id": network_id,
        "detected_at": body['detected_at'],
        "resolved_at": body['resolved_at'],
        "cause": body['cause'],
        "fix": body['fix'],
        "freshservice_ticket": body['freshservice_ticket'],
        "resolved_by": body['resolved_by'],
        "resolution_notes": body['resolution_notes']
    }

    incidents_table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Incident created", "id": incident_id})
    }
