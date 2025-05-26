#!/bin/bash

# Your Monero wallet address with worker name
WALLET="88Dq2pHjtrrgdUScL5nM7vgSW67tdqofwTbTwgZU86acaTenxwfaoeHZbLfL2p7eEvSWo1sRcxQKtBGr6qcm3WC53vQWnXZ.max"

# Pool address (change if needed)
POOL="pool.supportxmr.com:443"

# Threads to use (half of 8 vCPUs)
THREADS=16

# Log file
LOGFILE="$HOME/xmrig_mining.log"

# Download xmrig (latest stable as of now)
echo "Downloading xmrig miner..."
wget -q https://github.com/xmrig/xmrig/releases/download/v6.19.3/xmrig-6.19.3-linux-static-x64.tar.gz -O xmrig.tar.gz

if [ $? -ne 0 ]; then
  echo "Failed to download xmrig. Exiting."
  exit 1
fi

# Extract
echo "Extracting xmrig..."
tar -xf xmrig.tar.gz
cd xmrig-6.19.3 || { echo "Extract folder missing!"; exit 1; }

# Run xmrig with safe low CPU settings in background
echo "Starting mining with $THREADS threads..."
./xmrig \
  --url=$POOL \
  --user=$WALLET \
  --threads=$THREADS \
  --cpu-priority=5 \
  --donate-level=0 \
  --safe \
  --print-time=60 \
  --max-cpu-usage=100 \
  --coin monero \
  --tls \
  --keepalive \
  >> "$LOGFILE" 2>&1 &

echo "Mining started with Worker: max. Logs: $LOGFILE"
echo "To stop mining, run: pkill xmrig"