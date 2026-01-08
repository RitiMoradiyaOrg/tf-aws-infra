#!/bin/bash

#######################################
# Lambda Function Packaging Script
# Packages serverless-fork code for Lambda deployment
#######################################

set -e  # Exit on error

echo "🚀 Starting Lambda function packaging..."

# Define paths
LAMBDA_DIR="lambda"
TEMP_DIR="lambda-temp"
ZIP_FILE="lambda/email-verification.zip"
SERVERLESS_DIR="../serverless-fork"

# Check if serverless-fork exists
if [ ! -d "$SERVERLESS_DIR" ]; then
    echo "❌ Error: serverless-fork directory not found at $SERVERLESS_DIR"
    exit 1
fi

# Clean up previous builds
echo "🧹 Cleaning up previous builds..."
rm -rf "$TEMP_DIR"
rm -f "$ZIP_FILE"

# Create temp directory
echo "📁 Creating temporary build directory..."
mkdir -p "$TEMP_DIR"

# Copy source code
echo "📋 Copying Lambda function code..."
cp "$SERVERLESS_DIR/src/index.js" "$TEMP_DIR/"
cp "$SERVERLESS_DIR/package.json" "$TEMP_DIR/"

# Install production dependencies
echo "📦 Installing production dependencies..."
cd "$TEMP_DIR"
npm install --production --no-optional

# Create ZIP file
echo "🗜️  Creating deployment package..."
zip -r ../email-verification.zip . -x "*.git*" "*.DS_Store"

# Move to lambda directory
cd ..
mv email-verification.zip "$LAMBDA_DIR/"

# Clean up temp directory
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo "✅ Lambda package created successfully: $ZIP_FILE"
echo "📦 Package size:"
ls -lh "$ZIP_FILE"