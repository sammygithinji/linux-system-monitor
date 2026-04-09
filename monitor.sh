check_state() {
    local name=$1
    local current_state=$2
    local state_file="$STATE_DIR/${name}.state"

    if [ -f "$state_file" ]; then
        previous_state=$(cat "$state_file")
    else
        previous_state="UNKNOWN"
    fi

    if [ "$current_state" != "$previous_state" ]; then
        echo "$current_state" > "$state_file"
        return 0
    else
        return 1
    fi
}

CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90
ALERT_EMAIL="youremail@example.com"
LOG_FILE="~/linux-security-monitor/monitor.log"
STATE_DIR="~/linux-security-monitor/state"
mkdir -p "$STATE_DIR"


#CPU USAGE
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_INT=${CPU_USAGE%.*}

if [ "$CPU_INT" -gt "$CPU_THRESHOLD" ]; then
    STATE="HIGH"
else
    STATE="NORMAL"
fi

if check_state "cpu" "$STATE"; then
    if [ "$STATE" = "HIGH" ]; then
        echo "CPU HIGH: $CPU_USAGE%" | mail -s "CPU ALERT" "$ALERT_EMAIL"
    else
        echo "CPU RECOVERED: $CPU_USAGE%" | mail -s "CPU RECOVERY" "$ALERT_EMAIL"
    fi

    echo "$(date) | CPU | $STATE | $CPU_USAGE%" >> "$LOG_FILE"
fi



#MEMORY USAGE
MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100}')
MEM_INT=${MEM_USAGE%.*}

if [ "$MEM_INT" -gt "$MEM_THRESHOLD" ]; then
    STATE="HIGH"
else
    STATE="NORMAL"
fi

if check_state "memory" "$STATE"; then
    if [ "$STATE" = "HIGH" ]; then
        echo "MEMORY HIGH: $MEM_USAGE%" | mail -s "MEMORY ALERT" "$ALERT_EMAIL"
    else
        echo "MEMORY RECOVERED: $MEM_USAGE%" | mail -s "MEMORY RECOVERY" "$ALERT_EMAIL"
    fi

    echo "$(date) | MEMORY | $STATE | $MEM_USAGE%" >> "$LOG_FILE"
fi



#DISK USAGE
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    STATE="HIGH"
else
    STATE="NORMAL"
fi

if check_state "disk" "$STATE"; then
    if [ "$STATE" = "HIGH" ]; then
        echo "DISK HIGH: $DISK_USAGE%" | mail -s "DISK ALERT" "$ALERT_EMAIL"
    else
        echo "DISK RECOVERED: $DISK_USAGE%" | mail -s "DISK RECOVERY" "$ALERT_EMAIL"
    fi

    echo "$(date) | DISK | $STATE | $DISK_USAGE%" >> "$LOG_FILE"
fi



#SSH ATTACK DETECTION
RECENT_FAILS=$(grep "Failed password" /var/log/auth.log | tail -n 20 | wc -l)

if [ "$RECENT_FAILS" -gt 10 ]; then
    STATE="ATTACK"
else
    STATE="NORMAL"
fi

if check_state "ssh" "$STATE"; then
    if [ "$STATE" = "ATTACK" ]; then
        echo "SSH ATTACK DETECTED ($RECENT_FAILS attempts)" | mail -s "SECURITY ALERT" "$ALERT_EMAIL"
    else
        echo "SSH back to normal" | mail -s "SECURITY RECOVERY" "$ALERT_EMAIL"
    fi

    echo "$(date) | SSH | $STATE | $RECENT_FAILS attempts" >> "$LOG_FILE"
fi
