#!/bin/bash
# Utilized ChatGPT and create this script for memleak monitoring on hummingbot container 

echo; clear
echo "Ralph: ♻️ Memleak app running, please dont close this terminal"

# Container name to monitor
CONTAINER_NAME="pmm_btcfdusd"

# Log directory
LOGDIR="/home/hummingbot/ralph/script-logs"
mkdir -p "$LOGDIR"

# Timestamp for filename
TIME_TAG=$(date '+%H%M')
LOGFILE="${LOGDIR}/memleak_check_${TIME_TAG}.log"

# Log header
START_TS=$(date '+%Y-%m-%d %H:%M:%S')
echo "🕒 Memleak logging started at: $START_TS" >> "$LOGFILE"
echo "🔍 Monitoring container: $CONTAINER_NAME" >> "$LOGFILE"
echo "------------------------------------------" >> "$LOGFILE"

# Trap Ctrl+C to print exit time
trap 'echo "❌ Logging manually stopped at: $(date "+%Y-%m-%d %H:%M:%S")" >> "$LOGFILE"; exit 0' SIGINT

# Loop every 5 minutes until manually stopped
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP]" >> "$LOGFILE"
    docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    sleep 300
done
