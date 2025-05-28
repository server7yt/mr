#!/bin/bash

# === CONFIGURATION ===
WALLET="88Dq2pHjtrrgdUScL5nM7vgSW67tdqofwTbTwgZU86acaTenxwfaoeHZbLfL2p7eEvSWo1sRcxQKtBGr6qcm3WC53vQWnXZ.Adreesh"
POOL="pool.supportxmr.com:443"
THREADS=$(nproc)
LOGFILE="$HOME/xmrig_mining.log"
TELEGRAM_BOT_TOKEN="6247828526:AAGjRl09dgBTe6nyv1OPT1XiedXkAFYOo1M"
TELEGRAM_ADMIN_ID="1908670857"
REPORT_INTERVAL=30 # In seconds

# === CLEANUP PREVIOUS INSTANCES ===
pkill xmrig > /dev/null 2>&1
rm -rf xmrig-*-linux-static-x64 xmrig.tar.gz

# === INSTALL DEPENDENCIES ===
apt update && apt install -y wget screen curl jq > /dev/null 2>&1

# === DOWNLOAD XMRIG ===
wget -q https://github.com/xmrig/xmrig/releases/latest/download/xmrig-6.21.0-linux-static-x64.tar.gz -O xmrig.tar.gz
tar -xf xmrig.tar.gz
cd xmrig-*-linux-static-x64 || { echo "XMRig folder not found!"; exit 1; }

# === START MINING IN SCREEN ===
screen -S xmrig_miner -dm ./xmrig \
  --url=$POOL \
  --user=$WALLET \
  --threads=$THREADS \
  --cpu-priority=5 \
  --donate-level=0 \
  --print-time=60 \
  --max-cpu-usage=100 \
  --coin monero \
  --tls \
  --keepalive \
  >> "$LOGFILE" 2>&1

# === FUNCTIONS ===
send_telegram_message() {
  local TEXT="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_ADMIN_ID" \
    -d text="$TEXT" \
    -d parse_mode="Markdown" > /dev/null
}

monitor_hashrate() {
  while true; do
    sleep $REPORT_INTERVAL

    HSH=$(grep -a "speed" "$LOGFILE" | tail -1 | grep -oP '\d+(\.\d+)?\s*H\/s' | tail -1)
    HSH=${HSH:-"No data"}
    NOW=$(date '+%Y-%m-%d %H:%M:%S')

    MSG="🪙 *Monero Miner Status*\n📅 $NOW\n👤 Worker: Adreesh\n⚙️ Threads: $THREADS\n⚡ Hashrate: $HSH\n🎯 Pool: $POOL"
    send_telegram_message "$MSG"
  done
}

listen_for_commands() {
  LAST_UPDATE_ID=0
  while true; do
    UPDATES=$(curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates?offset=$((LAST_UPDATE_ID + 1))")

    # Parse messages
    echo "$UPDATES" | jq -c '.result[]' | while read -r msg; do
      ID=$(echo "$msg" | jq '.update_id')
      USER_ID=$(echo "$msg" | jq -r '.message.from.id')
      TEXT=$(echo "$msg" | jq -r '.message.text')

      LAST_UPDATE_ID=$ID

      if [[ "$USER_ID" == "$TELEGRAM_ADMIN_ID" ]]; then
        case "$TEXT" in
          /stop)
            send_telegram_message "⛔ Stopping miner as requested..."
            pkill xmrig
            kill %1 2>/dev/null
            exit 0
            ;;
          /status)
            HSH=$(grep -a "speed" "$LOGFILE" | tail -1 | grep -oP '\d+(\.\d+)?\s*H\/s' | tail -1)
            MSG="📊 *Live Hashrate:* $HSH"
            send_telegram_message "$MSG"
            ;;
        esac
      fi
    done

    sleep 5
  done
}

# === START BACKGROUND MONITORING ===
monitor_hashrate &

# === START COMMAND LISTENER (MAIN PROCESS) ===
listen_for_commands
