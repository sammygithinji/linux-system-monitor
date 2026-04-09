# Linux System Monitor — Linux Monitoring, Server Alerting & DevOps Health Checks
## Lightweight Linux Server Monitoring Tool for DevOps, System Health Tracking, and Intelligent Alerting

Never miss a critical system issue again.

This project is a Linux monitoring and alerting system built with Bash scripting that continuously tracks CPU usage, memory consumption, disk utilization, and SSH security events.

It implements state-based intelligent alerting, ensuring notifications are sent only when system state changes occur, eliminating alert fatigue and improving operational awareness.

Designed for DevOps engineers, Linux administrators, and cloud practitioners, this system demonstrates real-world concepts in monitoring, incident response, automation, and security awareness without relying on heavy external tools.

## System Overview
```
Server Metrics → monitor.sh → State Evaluation → State Changed?
                               │
                      YES ─────┴───── NO
                       │              │
               Send Alert        Silent Mode
                       │
                   Log Event
```
## User Instructions (Quick Setup)

### 1. Clone and Prepare

git clone https://github.com/your-username/linux-system-monitor.git

cd linux-system-monitor

chmod +x monitor.sh

### 2. Install Dependencies

sudo apt update

sudo apt install postfix mailutils -y

### 3. Configure Email Alerts (Gmail SMTP)

sudo nano /etc/postfix/sasl_passwd

Add:

[smtp.gmail.com]:587 your-email@gmail.com:your-app-password

Apply configuration:

sudo chmod 600 /etc/postfix/sasl_passwd

sudo postmap /etc/postfix/sasl_passwd

sudo systemctl restart postfix

### 4. Set Alert Email

nano monitor.sh

ALERT_EMAIL="your-email@example.com"

### 5. Test the System

./monitor.sh

Simulate load or failure (example):

sudo stress --cpu 4

### 6. Automate with Cron

crontab -e

Add:

*/5 * * * * /home/$USER/linux-system-monitor/monitor.sh

## Developer Notes

### Project Structure
```
linux-system-monitor/
├── monitor.sh        # Core monitoring engine
├── README.md         # Documentation
├── .gitignore        # Ignore logs, state files, secrets
└── state/            # Auto-generated state tracking files
```
### Core Implementation

Bash scripting → monitoring logic and automation

State tracking system → prevents alert spam

Postfix + Mailutils → email alert delivery

Cron jobs → scheduling and automation

Log files → system observability and audit

### Monitored Components
```
Component	        Function
CPU	           Detects high utilization
Memory	       Tracks RAM usage
Disk	         Monitors root disk usage
SSH	           Detects repeated failed login attempts
```
### Extending the System

Add webhook alerts:

curl -X POST https://your-api.com/webhook \

-d "{\"metric\":\"cpu\",\"status\":\"high\"}"

Monitor additional metrics or services by extending the script logic.

### Expected Behavior
```
Event	             Result
Normal operation	 No alert
Threshold breach	 Alert sent once
Issue persists	   No repeated alerts
Recovery	         Recovery alert sent
```
## Logs & State Management

### Logs:

~/monitor.log

### State Files (auto-generated):
```
state/
├── cpu.state
├── memory.state
├── disk.state
├── ssh.state
```

These files ensure alerts are triggered only on state transitions.

## Security & Best Practices

Prevents alert flooding using state-based logic

Avoids hardcoding sensitive credentials

Supports environment-based configuration

Provides basic SSH attack visibility

## Known Limitations

SSH detection is log-based (no time-window optimization yet)

No graphical dashboard (CLI-based monitoring only)

Email delivery depends on correct Postfix configuration

Single-node monitoring (no multi-server aggregation)

## Future Improvements

Config-driven monitoring (YAML/JSON)

Slack / Discord / Webhook integrations

Prometheus metrics export

Docker containerization

Multi-server monitoring support

## Contributing

### Contributions are welcome:

Fork the repository

Create a feature branch

Submit a pull request

## Support

If this project helped you build or understand monitoring systems, consider supporting its development.

Sharing, starring, or contributing helps improve practical open-source DevOps tools.

## License

MIT License — free to use, modify, and distribute.

## Author

### Samuel Githinji

DevOps & Cloud Engineering (In Progress)

Kenya
