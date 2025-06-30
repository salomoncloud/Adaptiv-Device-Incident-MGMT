#!/bin/bash
set -e

echo "Building Lambda packages from Terraform..."

# Navigate to project root (go up 3 levels: lambda -> modules -> terraform -> root)
cd "$(dirname "$0")/../../.."

echo "Current directory: $(pwd)"

# Build packages
echo "Building create_incident..."
cd backend/create_incident && zip -r ../create_incident.zip . && cd ../..

echo "Building get_recurring..."
cd backend/get_recurring && zip -r ../get_recurring.zip . && cd ../..

echo "Building get_all_incidents..."
cd backend/get_all_incidents && zip -r ../get_all_incidents.zip . && cd ../..

echo "Building export_csv..."
cd backend/export_csv && zip -r ../export_csv.zip . && cd ../..

echo "All Lambda packages built successfully!"
