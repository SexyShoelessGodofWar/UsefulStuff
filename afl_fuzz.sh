#!/bin/bash
set -e

# === Usage Checking ===
if [ "$#" -lt 3 ]; then
    cat <<EOF
Usage: $0 <input_dir> <output_dir> "<fuzz_target_command>"

Example:
  $0 /path/to/input /path/to/output "./fuzz_target -arg1 -arg2"
EOF
    exit 1
fi

# === Parameters ===
INPUT_DIR="$1"
OUTPUT_DIR="$2"
shift 2
TARGET_CMD="$@"

# === Check prerequisites ===
if ! command -v afl-fuzz >/dev/null 2>&1; then
    echo "Error: afl-fuzz is not installed or not in your PATH."
    exit 1
fi

# === Determine CPU Count and Compute Number of Instances ===
CPU_COUNT=$(nproc)
# Compute 95% (rounded down); if that is less than 1, set it to 1.
INSTANCES=$(awk "BEGIN {print int($CPU_COUNT * 0.95)}")
if [ "$INSTANCES" -lt 1 ]; then
    INSTANCES=1
fi

MASTER_NAME="master"
SLAVE_COUNT=$(( INSTANCES - 1 ))
echo "Detected $CPU_COUNT CPU(s)."
echo "Launching $INSTANCES instances: 1 master and $SLAVE_COUNT slave(s)."

# Ensure the output directory exists.
mkdir -p "$OUTPUT_DIR"

# === Launch the Master Instance ===
if command -v tmux >/dev/null 2>&1; then
    echo "tmux detected. Launching the master instance in a new tmux session named 'afl_master'."
    tmux new-session -d -s afl_master "afl-fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -M $MASTER_NAME -- $TARGET_CMD"
    echo "Master instance running in tmux session 'afl_master'."
    echo "To view the session later, use: tmux attach -t afl_master"
else
    echo "tmux not found. Launching the master instance with nohup (output will be logged to 'afl_master.log')."
    nohup afl-fuzz -i "$INPUT_DIR" -o "$OUTPUT_DIR" -M $MASTER_NAME -- $TARGET_CMD > afl_master.log 2>&1 &
    echo "Master instance launched."
    echo "To view its output, use: tail -f afl_master.log"
fi

# === Launch Slave Instances ===
for (( i=1; i<=SLAVE_COUNT; i++ )); do
    SLAVE_NAME="slave$i"
    nohup afl-fuzz -i "$INPUT_DIR" -o "$OUTPUT_DIR" -S $SLAVE_NAME -- $TARGET_CMD > afl_${SLAVE_NAME}.log 2>&1 &
    echo "Launched slave instance: $SLAVE_NAME (log file: afl_${SLAVE_NAME}.log)"
done

echo "All AFL-fuzz instances have been launched."
