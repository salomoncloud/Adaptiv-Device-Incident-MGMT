import csv
import boto3
import os
import io

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    try:
        response = table.scan()
        items = response.get("Items", [])

        if not items:
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "text/csv"},
                "body": ""
            }

        headers = list(items[0].keys())
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=headers)
        writer.writeheader()
        writer.writerows(items)

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/csv",
                "Content-Disposition": "attachment; filename=incidents.csv"
            },
            "body": output.getvalue()
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": str(e)
        }
