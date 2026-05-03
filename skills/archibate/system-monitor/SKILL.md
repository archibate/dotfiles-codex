---
name: system-monitor
description: Check system health (CPU, memory, disk, network, top processes) and report alarms on high usage
allowed-tools:
  - Bash(top:*)
  - Bash(free:*)
  - Bash(df:*)
  - Bash(ps:*)
  - Bash(cat /proc/net/dev:*)
  - Bash(ip:*)
when_to_use: >
  Use when the user asks to check system status, system health,
  or resource usage. Trigger phrases: "check system", "system status",
  "syscheck", "check CPU", "check memory", "check disk",
  "is the system OK?", "system health".
---

# System Monitor

Check current system health and report alarms when any resource exceeds safe thresholds.

## Goal

Present a single summary table of CPU, memory, disk, and network status with OK / Watch / ALARM indicators. List top resource-consuming processes. Flag any metric that exceeds its threshold.

## Thresholds

| Resource | Watch   | ALARM  |
|----------|---------|--------|
| CPU      | > 60%   | > 80%  |
| Memory   | > 60%   | > 80%  |
| Disk     | > 70%   | > 85%  |

## Steps

### 1. Gather system metrics

Run the following commands and parse their output:

- **CPU**: `top -bn1 | head -5` — extract user%, system%, idle%, and load averages
- **Memory**: `free -h` — extract total, used, available
- **Disk**: `df -h --total -x tmpfs -x devtmpfs -x efivarfs` — extract total, used, available, use%
- **Network**: `cat /proc/net/dev` — extract RX/TX bytes for non-loopback interfaces
- **Top processes**: `ps aux --sort=-%cpu | head -6` for CPU hogs, `ps aux --sort=-%mem | head -6` for memory hogs

### 2. Evaluate thresholds

Compare each metric against the threshold table above. Assign status:
- **OK**: below Watch threshold
- **Watch**: between Watch and ALARM thresholds
- **ALARM**: at or above ALARM threshold

### 3. Report

Present results as:

1. A **summary table** with columns: Resource, Status, Details
2. A **Top Processes** section showing the top 5 by CPU and top 5 by memory (deduplicate if overlapping)
3. A **Network** section showing per-interface RX/TX rates
4. If any metric is ALARM, lead with a bold warning line

**Success criteria**: User sees a clear, scannable health report and any alarms are immediately obvious.
