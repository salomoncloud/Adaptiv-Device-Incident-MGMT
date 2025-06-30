import csv
import boto3
import os
import io

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    # CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    }
    
    # Handle preflight OPTIONS request
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }
    
    try:
        response = table.scan()
        items = response.get("Items", [])

        if not items:
            return {
                "statusCode": 200,
                "headers": {
                    **headers,
                    "Content-Type": "text/csv",
                    "Content-Disposition": "attachment; filename=incidents.csv"
                },
                "body": "No incidents found"
            }

        # Define column order for CSV
        fieldnames = [
            'incident_id', 'serial_number', 'network_id', 'cpe_type',
            'site_name', 'partner_name', 'customer_name', 'detected_at',
            'resolved_at', 'cause', 'fix', 'freshservice_ticket',
            'resolved_by', 'resolution_notes', 'created_timestamp'
        ]
        
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(items)

        return {
            "statusCode": 200,
            "headers": {
                **headers,
                "Content-Type": "text/csv",
                "Content-Disposition": "attachment; filename=incidents.csv"
            },
            "body": output.getvalue()
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {**headers, "Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
