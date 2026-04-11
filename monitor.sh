#!/bin/bash
set -euo pipefail

#Load config
source "$(dirname $0)/config/monitor.conf"

#Directorie
mkdir -p "$STATE_DIR"
mkdir -p "$(dirname $LOG_FILE)"

#send_alert function
send_alert() {
  local subject="$1"
  local message="$2"

 #Email
  echo "$message" | mail -s "$subject" "$ALERT_EMAIL"

  
# Slack (only fires if SLACK_WEBHOOK is set in config)
  if [[ -n "$SLACK_WEBHOOK" ]]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
      -H 'Content-type: application/json' \
      -d "{\"text\":\"*${subject}*\n${message}\"}" > /dev/null
  fi

  echo "$(date) | ALERT SENT | $subject" >> "$LOG_FILE"
}


#auto_restart function
auto_restart() {
  local service="$1"
  if systemctl list-unit-files "${service}.service" 2>/dev/null | grep -q "$service"; then
    sudo systemctl start "$service"
    if systemctl is-active --quiet "$service"; then
      echo "$(date) | $service | RESTARTED SUCCESSFULLY" >> "$LOG_FILE"
      send_alert "${service} RESTARTED" "${service} was down and has been restarted successfully"
    else
      echo "$(date) | $service | RESTART FAILED" >> "$LOG_FILE"
      send_alert "${service} RESTART FAILED" "${service} is down and could not be restarted"
    fi
  fi
}


#check_state function
check_state() {
  local name="$1"
  local current_state="$2"
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


# ── status dashboard ────────────────────────────────────────
if [[ "${1:-}" == "--status" ]]; then
  echo "============================================"
  echo "  Linux System Monitor — Current Status"
  echo "============================================"
  echo "  CPU    : $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print int(usage)}')%"
  echo "  Memory : $(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')%"
  echo "  Disk   : $(df / | tail -1 | awk '{print $5}')"
  echo "  SSH    : $(cat $STATE_DIR/ssh.state 2>/dev/null || echo 'NORMAL')"
  echo "  NGINX  : $(if systemctl list-unit-files nginx.service 2>/dev/null | grep -q nginx; then systemctl is-active nginx; else echo 'not installed'; fi)"
  echo "  MySQL  : $(if systemctl list-unit-files mysql.service 2>/dev/null | grep -q mysql; then systemctl is-active mysql; else echo 'not installed'; fi)"
  echo "============================================"
  exit 0
fi


#CPU check
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}')
CPU_INT="$CPU_USAGE"

if [ "$CPU_INT" -gt "$CPU_THRESHOLD" ]; then
  STATE="HIGH"
else
  STATE="NORMAL"
fi

if check_state "cpu" "$STATE"; then
  if [ "$STATE" = "HIGH" ]; then
    send_alert "CPU ALERT" "CPU HIGH: ${CPU_USAGE}%"
  else
    send_alert "CPU RECOVERY" "CPU back to normal: ${CPU_USAGE}%"
  fi
  echo "$(date) | CPU | $STATE | ${CPU_USAGE}%" >> "$LOG_FILE"
fi


#Memory check
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')

if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
  STATE="HIGH"
else
  STATE="NORMAL"
fi

if check_state "memory" "$STATE"; then
  if [ "$STATE" = "HIGH" ]; then
    send_alert "MEMORY ALERT" "Memory HIGH: ${MEM_USAGE}%"
  else
    send_alert "MEMORY RECOVERY" "Memory back to normal: ${MEM_USAGE}%"
  fi
  echo "$(date) | MEMORY | $STATE | ${MEM_USAGE}%" >> "$LOG_FILE"
fi



#Disk check
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
  STATE="HIGH"
else
  STATE="NORMAL"
fi

if check_state "disk" "$STATE"; then
  if [ "$STATE" = "HIGH" ]; then
    send_alert "DISK ALERT" "Disk HIGH: ${DISK_USAGE}%"
  else
    send_alert "DISK RECOVERY" "Disk back to normal: ${DISK_USAGE}%"
  fi
  echo "$(date) | DISK | $STATE | ${DISK_USAGE}%" >> "$LOG_FILE"
fi



#SSH attack detection
RECENT_FAILS=$(journalctl -u ssh --since "5 minutes ago" 2>/dev/null | \
  grep "Failed password" | wc -l)

if [ "$RECENT_FAILS" -gt "$SSH_FAIL_THRESHOLD" ]; then
  STATE="ATTACK"
else
  STATE="NORMAL"
fi

if check_state "ssh" "$STATE"; then
  if [ "$STATE" = "ATTACK" ]; then
    send_alert "SECURITY ALERT" "SSH attack detected: ${RECENT_FAILS} failed attempts in 5 minutes"
  else
    send_alert "SECURITY RECOVERY" "SSH back to normal"
  fi
  echo "$(date) | SSH | $STATE | ${RECENT_FAILS} attempts" >> "$LOG_FILE"
fi


#NGINX check
if systemctl list-unit-files nginx.service 2>/dev/null | grep -q nginx; then
  if systemctl is-active --quiet nginx; then
    NGINX_STATE="UP"
  else
    NGINX_STATE="DOWN"
    auto_restart "nginx"
  fi

  if check_state "nginx" "$NGINX_STATE"; then
    if [ "$NGINX_STATE" = "DOWN" ]; then
      send_alert "NGINX DOWN" "NGINX service is down — attempting restart"
    else
      send_alert "NGINX RECOVERY" "NGINX is back up"
    fi
    echo "$(date) | NGINX | $NGINX_STATE" >> "$LOG_FILE"
  fi
fi

#MySQL check
if systemctl list-unit-files mysql.service 2>/dev/null | grep -q mysql; then
  if systemctl is-active --quiet mysql; then
    MYSQL_STATE="UP"
  else
    MYSQL_STATE="DOWN"
    auto_restart "mysql"
  fi

  if check_state "mysql" "$MYSQL_STATE"; then
    if [ "$MYSQL_STATE" = "DOWN" ]; then
      send_alert "MYSQL DOWN" "MySQL service is down — attempting restart"
    else
      send_alert "MYSQL RECOVERY" "MySQL is back up"
    fi
    echo "$(date) | MYSQL | $MYSQL_STATE" >> "$LOG_FILE"
  fi
fi
