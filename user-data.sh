#!/bin/bash
# Assignment 9 - Web Application Deployment
set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "========================================="
echo "🚀 Starting deployment - $(date)"
echo "========================================="

# Get instance metadata using IMDSv2 (token-based)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s 2>/dev/null || echo "")

if [ -n "$TOKEN" ]; then
    # IMDSv2 - use token
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || hostname)
    REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
else
    # IMDSv1 fallback
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || hostname)
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
fi

echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"
echo ""

# Wait for cloud-init to complete
sleep 15

#######################################
# RETRIEVE DATABASE PASSWORD
#######################################

echo "🔐 Retrieving database password from Secrets Manager..."

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ${db_secret_name} \
  --region $REGION \
  --query SecretString \
  --output text 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$DB_PASSWORD" ]; then
    echo "✅ Retrieved password from Secrets Manager"
else
    echo "⚠️  Using fallback password"
    DB_PASSWORD="${db_password}"
fi

#######################################
# CREATE ENVIRONMENT FILE
#######################################

echo ""
echo "📝 Creating environment configuration..."

# ✅ CRITICAL FIX: Properly escape password for sed
# This handles ALL special characters: { } * $ | [ ] \ / . ^ and more
ESCAPED_PASSWORD=$(printf '%s\n' "$DB_PASSWORD" | sed -e 's/[]\/$*.^[]/\\&/g' -e 's/|/\\|/g')

# Create .env with placeholders using quoted HERE document
cat > /opt/webapp/.env << 'EOF'
DB_HOST=PLACEHOLDER_DB_HOST
DB_PORT=5432
DB_USER=PLACEHOLDER_DB_USER
DB_PASSWORD=PLACEHOLDER_DB_PASSWORD
DB_NAME=PLACEHOLDER_DB_NAME
DB_DIALECT=postgres
NODE_ENV=production
PORT=PLACEHOLDER_APP_PORT
AWS_REGION=PLACEHOLDER_REGION
S3_BUCKET_NAME=PLACEHOLDER_S3_BUCKET
SNS_TOPIC_ARN=PLACEHOLDER_SNS_TOPIC
LOG_LEVEL=info
INSTANCE_ID=PLACEHOLDER_INSTANCE_ID
EOF

# ✅ Now safely substitute each placeholder using sed with escaped password
sed -i "s|PLACEHOLDER_DB_HOST|${db_host}|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_DB_USER|${db_username}|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_DB_PASSWORD|$ESCAPED_PASSWORD|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_DB_NAME|${db_name}|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_APP_PORT|${app_port}|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_REGION|$REGION|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_S3_BUCKET|${s3_bucket}|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_SNS_TOPIC|${sns_topic_arn}|g" /opt/webapp/.env
sed -i "s|PLACEHOLDER_INSTANCE_ID|$INSTANCE_ID|g" /opt/webapp/.env

chown csye6225:csye6225 /opt/webapp/.env
chmod 600 /opt/webapp/.env

# Verify password was written (check for placeholder text - should be GONE)
if grep -q "PLACEHOLDER_DB_PASSWORD" /opt/webapp/.env; then
    echo "❌ PASSWORD SUBSTITUTION FAILED - placeholder still exists!"
else
    echo "✅ DB_PASSWORD substituted successfully"
fi

echo "✅ Environment file created at /opt/webapp/.env"

#######################################
# CREATE LOG DIRECTORY
#######################################

echo ""
echo "📁 Setting up logging..."

mkdir -p /var/log/webapp
chown csye6225:csye6225 /var/log/webapp
chmod 755 /var/log/webapp

echo "✅ Log directory ready"

#######################################
# TEST DATABASE CONNECTION
#######################################

echo ""
echo "🔌 Testing database connectivity..."

export PGPASSWORD="$DB_PASSWORD"
DB_READY=false

for attempt in {1..15}; do
    if pg_isready -h ${db_host} -p 5432 -U ${db_username} -d ${db_name} 2>/dev/null; then
        DB_READY=true
        echo "✅ Database connected (attempt $attempt/15)"
        break
    fi
    echo "   Waiting for database... ($attempt/15)"
    sleep 10
done

#######################################
# RUN DATABASE MIGRATIONS
#######################################

if [ "$DB_READY" = "true" ]; then
    echo ""
    echo "🔄 Running database migrations..."
    
    cd /opt/webapp
    
    if sudo -u csye6225 NODE_ENV=production npx sequelize-cli db:migrate 2>&1; then
        echo "✅ Migrations completed"
    else
        echo "⚠️  Migrations failed (continuing anyway)"
    fi
else
    echo "⚠️  Database not ready, skipping migrations"
fi

unset PGPASSWORD

#######################################
# CONFIGURE CLOUDWATCH AGENT
#######################################

echo ""
echo "📊 Configuring CloudWatch Agent..."

# Create CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/webapp/app.log",
            "log_group_name": "/csye6225/${environment}/webapp/application",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/csye6225/${environment}/webapp/deployment",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "statsd": {
        "service_address": ":8125",
        "metrics_collection_interval": 60
      }
    }
  }
}
CWCONFIG

chown cwagent:cwagent /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start CloudWatch Agent
systemctl enable amazon-cloudwatch-agent.service
systemctl start amazon-cloudwatch-agent.service
sleep 5

if systemctl is-active --quiet amazon-cloudwatch-agent.service; then
    echo "✅ CloudWatch Agent running"
else
    echo "⚠️  CloudWatch Agent failed"
fi

#######################################
# START WEB APPLICATION
#######################################

echo ""
echo "🌐 Starting web application..."

# Start the application service
systemctl enable webapp.service
systemctl start webapp.service
sleep 10

if systemctl is-active --quiet webapp.service; then
    echo "✅ Application service running"
else
    echo "❌ Application service failed"
    echo ""
    systemctl status webapp.service --no-pager || true
fi

#######################################
# HEALTH CHECK VERIFICATION
#######################################

echo ""
echo "🏥 Verifying health checks..."

HEALTH_OK=false

for attempt in {1..12}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://localhost:${app_port}/healthz 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        HEALTH_OK=true
        echo "✅ Health check passed (HTTP $HTTP_CODE) - attempt $attempt/12"
        break
    else
        echo "   Health check: HTTP $HTTP_CODE - waiting... ($attempt/12)"
        sleep 10
    fi
done

#######################################
# DEPLOYMENT SUMMARY
#######################################

echo ""
echo "========================================="
echo "📊 DEPLOYMENT SUMMARY"
echo "========================================="
echo ""
echo "Services:"
systemctl is-active --quiet webapp.service && echo "  ✅ Web App: Running" || echo "  ❌ Web App: Failed"
systemctl is-active --quiet amazon-cloudwatch-agent.service && echo "  ✅ CloudWatch: Running" || echo "  ❌ CloudWatch: Failed"
echo ""
echo "Configuration:"
echo "  - Database: ${db_host}"
echo "  - S3 Bucket: ${s3_bucket}"
echo "  - App Port: ${app_port}"
echo "  - Environment: ${environment}"
echo ""

if [ "$HEALTH_OK" = "true" ]; then
    echo "🎉 DEPLOYMENT SUCCESSFUL"
    echo "   Application: http://localhost:${app_port}/healthz"
else
    echo "⚠️  DEPLOYMENT ISSUES DETECTED"
    echo ""
    echo "Troubleshooting commands:"
    echo "  - journalctl -u webapp.service -n 50"
    echo "  - cat /opt/webapp/.env"
    echo "  - ss -tlnp | grep ${app_port}"
fi

echo ""
echo "========================================="
echo "✅ User-data completed - $(date)"
echo "========================================="