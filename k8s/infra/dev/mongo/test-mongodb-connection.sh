#!/bin/bash
# MongoDB Connection Test Script
# This script tests the MongoDB connection and basic operations

set -e

NAMESPACE="smartcity"
MONGODB_HOST="mongodb.${NAMESPACE}.svc.cluster.local"
MONGODB_PORT="27017"
MONGODB_USER="smartcity"
MONGODB_PASSWORD="smartcity123"
MONGODB_DATABASE="smartcity"
MONGODB_AUTH_DB="admin"

echo "🔍 Testing MongoDB Connection..."
echo "================================="

# Test 1: DNS Resolution
echo "1. Testing DNS resolution..."
kubectl run test-dns --image=busybox --rm -i --restart=Never --namespace=${NAMESPACE} \
  -- nslookup ${MONGODB_HOST} || {
    echo "❌ DNS resolution failed"
    exit 1
  }
echo "✅ DNS resolution successful"

# Test 2: Service Connectivity
echo ""
echo "2. Testing service connectivity..."
kubectl run test-connect --image=mongo:6.0 --rm -i --restart=Never --namespace=${NAMESPACE} \
  -- mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} --eval "db.adminCommand('ping')" || {
    echo "❌ Service connectivity failed"
    exit 1
  }
echo "✅ Service connectivity successful"

# Test 3: Authentication
echo ""
echo "3. Testing authentication..."
kubectl run test-auth --image=mongo:6.0 --rm -i --restart=Never --namespace=${NAMESPACE} \
  -- mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} \
  --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} \
  --authenticationDatabase ${MONGODB_AUTH_DB} \
  --eval "db.runCommand('ismaster')" || {
    echo "❌ Authentication failed"
    exit 1
  }
echo "✅ Authentication successful"

# Test 4: Database Access
echo ""
echo "4. Testing database access..."
kubectl run test-db --image=mongo:6.0 --rm -i --restart=Never --namespace=${NAMESPACE} \
  -- mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} \
  --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} \
  --authenticationDatabase ${MONGODB_AUTH_DB} \
  --eval "use ${MONGODB_DATABASE}; db.test_collection.insertOne({test: 'connection_test', timestamp: new Date()}); db.test_collection.findOne({test: 'connection_test'})" || {
    echo "❌ Database access failed"
    exit 1
  }
echo "✅ Database access successful"

# Test 5: Replica Set Status
echo ""
echo "5. Testing replica set status..."
kubectl run test-rs --image=mongo:6.0 --rm -i --restart=Never --namespace=${NAMESPACE} \
  -- mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} \
  --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} \
  --authenticationDatabase ${MONGODB_AUTH_DB} \
  --eval "rs.status()" || {
    echo "❌ Replica set status check failed"
    exit 1
  }
echo "✅ Replica set status check successful"

# Test 6: User Permissions
echo ""
echo "6. Testing user permissions..."
kubectl run test-permissions --image=mongo:6.0 --rm -i --restart=Never --namespace=${NAMESPACE} \
  -- mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} \
  --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} \
  --authenticationDatabase ${MONGODB_AUTH_DB} \
  --eval "use ${MONGODB_DATABASE}; db.createCollection('test_permissions'); db.test_permissions.drop()" || {
    echo "❌ User permissions test failed"
    exit 1
  }
echo "✅ User permissions test successful"

echo ""
echo "🎉 All MongoDB tests passed successfully!"
echo "========================================"
echo "MongoDB is ready for application connections."
echo ""
echo "Connection String:"
echo "mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DATABASE}?authSource=${MONGODB_AUTH_DB}"
echo ""
echo "Environment Variables for Applications:"
echo "MONGODB_URI=mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DATABASE}?authSource=${MONGODB_AUTH_DB}"
echo "MONGODB_DATABASE=${MONGODB_DATABASE}"
echo "MONGODB_USERNAME=${MONGODB_USER}"
echo "MONGODB_PASSWORD=${MONGODB_PASSWORD}"
