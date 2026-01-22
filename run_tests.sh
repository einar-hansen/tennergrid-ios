#!/bin/bash

# Script to build and test the TennerGrid project
# This script runs tests for the iOS app

set -e  # Exit on error

echo "Building TennerGrid project..."
xcodebuild -scheme TennerGrid \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    build-for-testing

echo ""
echo "Running tests..."
xcodebuild -scheme TennerGrid \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    test

echo ""
echo "Tests completed successfully!"
