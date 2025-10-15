#!/bin/bash

# URI Matcher Test Script
# Tests all routes defined in URIMatcherTest.ino

SERVER_IP="${1:-192.168.4.1}"
SERVER_PORT="80"
BASE_URL="http://${SERVER_IP}:${SERVER_PORT}"

echo "Testing URI Matcher at $BASE_URL"
echo "=================================="

# Function to test a route
test_route() {
    local path="$1"
    local expected_status="$2"
    local description="$3"

    echo -n "Testing $path ... "

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL$path" 2>/dev/null)
    status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)

    if [ "$status_code" = "$expected_status" ]; then
        echo "✅ PASS ($status_code)"
    else
        echo "❌ FAIL (expected $expected_status, got $status_code)"
        return 1
    fi
    return 0
}

# Test counter
PASS=0
FAIL=0

# Test all routes that should return 200 OK
echo "Testing routes that should work (200 OK):"

if test_route "/status" "200" "Status endpoint"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/exact" "200" "Exact path"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/exact/" "200" "Exact path ending with /"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/exact/sub" "200" "Exact path with subpath /"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/api/users" "200" "Exact API path"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/api/data" "200" "API prefix match"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/api/v1/posts" "200" "API prefix deep"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/files/document.pdf" "200" "Files prefix"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/files/images/photo.jpg" "200" "Files prefix deep"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/config.json" "200" "JSON extension"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/data/settings.json" "200" "JSON extension in subfolder"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/style.css" "200" "CSS extension"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/assets/main.css" "200" "CSS extension in subfolder"; then ((PASS++)); else ((FAIL++)); fi

# Check if regex is enabled by testing the server
echo ""
echo "Checking for regex support..."
regex_test=$(curl -s "$BASE_URL/user/123" 2>/dev/null)
if curl -s -w "%{http_code}" "$BASE_URL/user/123" 2>/dev/null | grep -q "200"; then
    echo "Regex support detected - testing regex routes:"
    if test_route "/user/123" "200" "Regex user ID"; then ((PASS++)); else ((FAIL++)); fi
    if test_route "/user/456" "200" "Regex user ID 2"; then ((PASS++)); else ((FAIL++)); fi
    if test_route "/blog/2023/10/15" "200" "Regex blog date"; then ((PASS++)); else ((FAIL++)); fi
    if test_route "/blog/2024/12/25" "200" "Regex blog date 2"; then ((PASS++)); else ((FAIL++)); fi
else
    echo "Regex support not detected (compile with ASYNCWEBSERVER_REGEX to enable)"
fi

echo ""
echo "Testing routes that should fail (404 Not Found):"

if test_route "/nonexistent" "404" "Non-existent route"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/exact-sub" "404" "Exact path with extra characters"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/user/abc" "404" "Invalid regex (letters instead of numbers)"; then ((PASS++)); else ((FAIL++)); fi
if test_route "/blog/23/10/15" "404" "Invalid regex (2-digit year)"; then ((PASS++)); else ((FAIL++)); fi

echo ""
echo "=================================="
echo "Test Results:"
echo "✅ Passed: $PASS"
echo "❌ Failed: $FAIL"
echo "Total: $((PASS + FAIL))"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed! URI matching is working correctly."
    exit 0
else
    echo ""
    echo "❌ Some tests failed. Check the server and routes."
    exit 1
fi
