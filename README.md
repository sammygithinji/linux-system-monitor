# Linux System Monitor

A lightweight Linux observability system built with Bash that monitors
server health, detects security threats, and delivers intelligent
state-based alerts — without relying on heavy external tools.

Built by [Samuel Kanyi](https://github.com/sammygithinji)

---

## What it does

- Monitors CPU, memory, disk, and SSH attack attempts in real time
- Sends alerts only when system state changes — no spam, no noise
- Detects recovery and notifies when systems return to normal
- Auto-restarts failed services (NGINX, MySQL)
- Delivers alerts via Slack and email simultaneously
- Logs every event with timestamps for audit and review
- Runs automatically every 5 minutes via cron

---
```
## System architecture
Server Metrics ──► monitor.sh ──► check_state()
│
State changed?
YES │        │ NO
▼        ▼
send_alert()  Silent
Slack + Email
│
log event ──► monitor.log
```
---

## Quick start

### 1. Clone the repo

```bash
git clone https://github.com/sammygithinji/linux-system-monitor.git
cd linux-system-monitor
chmod +x monitor.sh
```

### 2. Install dependencies

```bash
sudo apt update
sudo apt install postfix mailutils curl -y
```

### 3. Configure your settings

```bash
cp config/monitor.conf.example config/monitor.conf
nano config/monitor.conf
```

Set your values:

```bash
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90
SSH_FAIL_THRESHOLD=5
ALERT_EMAIL="you@gmail.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### 4. Run a status check

```bash
./monitor.sh --status
```
```
Expected output:
============================================
Linux System Monitor — Current Status
CPU    : 11%
Memory : 47%
Disk   : 14%
SSH    : NORMAL
NGINX  : active
```
### 5. Run the monitor manually

```bash
./monitor.sh
```

### 6. Automate with cron

```bash
crontab -e
```

Add this line:

```bash
*/5 * * * * /home/$USER/linux-system-monitor/monitor.sh
```

---
```
## Project structure
linux-system-monitor/
├── monitor.sh              # Core monitoring engine
├── config/
│   └── monitor.conf        # All thresholds and credentials
├── state/                  # Auto-generated state tracking files
│   ├── cpu.state
│   ├── memory.state
│   ├── disk.state
│   └── ssh.state
├── monitor.log             # Event log with timestamps
└── README.md
```
```

## Alert behaviour

| Event              | Result                        |
|--------------------|-------------------------------|
| Normal operation   | No alert sent                 |
| Threshold breached | Alert sent once via Slack + email |
| Issue persists     | No repeated alerts            |
| Recovery detected  | Recovery alert sent           |
| Service goes down  | Auto-restart attempted        |



## Monitored components

| Component | Method                        | Threshold |
|-----------|-------------------------------|-----------|
| CPU       | top -bn1                      | 80%       |
| Memory    | free                          | 80%       |
| Disk      | df /                          | 90%       |
| SSH       | journalctl (5-minute window)  | 5 failures|
| NGINX     | systemctl is-active           | Any down  |
| MySQL     | systemctl is-active           | Any down  | Optional |
```

## How state-based alerting works

Most monitoring scripts send an alert every time they run.

This system only alerts when state changes — from NORMAL to HIGH,
or from HIGH back to NORMAL.

State is persisted between runs using files in the `state/` directory.

This means zero alert spam, even if a problem lasts for hours.

This is the same pattern used by enterprise tools like
Datadog, PagerDuty, and Prometheus.

---

## Extending the system

Add a new metric by following this pattern:

```bash
# 1. Capture the value
MY_VALUE=$(your command here)

# 2. Evaluate state
if [ "$MY_VALUE" -gt "$MY_THRESHOLD" ]; then
  STATE="HIGH"
else
  STATE="NORMAL"
fi

# 3. Alert on change
if check_state "my_metric" "$STATE"; then
  if [ "$STATE" = "HIGH" ]; then
    send_alert "MY METRIC ALERT" "Value: ${MY_VALUE}"
  else
    send_alert "MY METRIC RECOVERY" "Value: ${MY_VALUE}"
  fi
  echo "$(date) | MY_METRIC | $STATE | ${MY_VALUE}" >> "$LOG_FILE"
fi
```



## Planned improvements

- Slack rich message formatting with severity colours

- Prometheus metrics export endpoint

- Docker containerisation

- Multi-server monitoring via SSH

- Config-driven thresholds via YAML

- Web dashboard for log visualisation

---

## Author

**Samuel Kanyi**

DevOps and Cloud Engineering

GitHub: [sammygithinji](https://github.com/sammygithinji)

---

## License

MIT License — free to use, modify, and distribute.
