#!/bin/bash

# ========================
# DEFAULT CONFIG
# ========================
HOST="192.168.1.101"
PORT="80"
SSH_USER="health_check"
SSH_KEY="$HOME/.ssh/health_check_key"
PING_TIMEOUT=2
DISK_THRESHOLD=80
LOG_FILE="health_check.log"

# ========================
# ERROR HANDLING FUNCTION
# ========================
error_exit() {
    echo "✖ ERROR: $1"
    exit 1
}

# ========================
# VALIDATION
# ========================

# Check required variables
[ -z "$HOST" ] && error_exit "HOST is not set"
[ -z "$PORT" ] && error_exit "PORT is not set"
[ -z "$SSH_USER" ] && error_exit "SSH_USER is not set"
[ -z "$SSH_KEY" ] && error_exit "SSH_KEY is not set"

# Check SSH key exists
[ ! -f "$SSH_KEY" ] && error_exit "SSH key not found at $SSH_KEY"

# Check numeric values
[[ ! "$PING_TIMEOUT" =~ ^[0-9]+$ ]] && error_exit "PING_TIMEOUT must be a number"
[[ ! "$DISK_THRESHOLD" =~ ^[0-9]+$ ]] && error_exit "DISK_THRESHOLD must be a number"

# ========================
# LOGGING SETUP
# ========================
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "       SERVER HEALTH CHECK REPORT       "
echo "========================================"
echo "Target Host : $HOST"
echo "Run Time    : $(date)"
echo ""

# ========================
# 1. PING CHECK
# ========================
echo "[1] Network Connectivity Check (Ping)"

if ping -c 2 -W $PING_TIMEOUT $HOST > /dev/null 2>&1; then
    echo "✔ SUCCESS: Server is reachable"
else
    echo "✖ FAIL: Server is unreachable (timeout ${PING_TIMEOUT}s)"
    exit 1
fi

echo ""

# ========================
# 2. WEB SERVICE CHECK
# ========================
echo "[2] Web Service Check (HTTP Port $PORT)"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://$HOST:$PORT)

if [[ "$HTTP_CODE" =~ ^2|3 ]]; then
    echo "✔ SUCCESS: Web service is UP (HTTP - $HTTP_CODE)"
elif [[ "$HTTP_CODE" =~ ^4|5 ]]; then
    echo "⚠ WARNING: Web service reachable but error (HTTP $HTTP_CODE)"
else
    echo "✖ FAIL: Web service is DOWN or not responding"
fi

echo ""

# ========================
# 3. DISK CHECK
# ========================
echo "[3] Disk Usage Check (/ partition)"

DISK_OUTPUT=$(ssh -i "$SSH_KEY" -o ConnectTimeout=3 -o BatchMode=yes -T $SSH_USER@$HOST "df -h /" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$DISK_OUTPUT" ]; then
    echo "✖ FAIL: Unable to retrieve disk usage via SSH"
else
    echo "$DISK_OUTPUT"

    USAGE=$(echo "$DISK_OUTPUT" | awk 'NR==2 {print $5}' | tr -d '%')

    if [[ ! "$USAGE" =~ ^[0-9]+$ ]]; then
        echo "⚠ WARNING: Unable to parse disk usage"
    elif [ "$USAGE" -ge "$DISK_THRESHOLD" ]; then
        echo "⚠ WARNING: Disk usage is high (${USAGE}%) - Threshold: ${DISK_THRESHOLD}%"
    else
        echo "✔ SUCCESS: Disk usage is healthy (${USAGE}%)"
    fi
fi

echo ""
echo "Results logged to $LOG_FILE"
echo "============= END OF REPORT ============="
echo ""