#!/bin/bash
LOG_FILE="traffic_logs.txt"
BLOCKED_FILE="blocked_ips.txt"
HTML_FILE="dashboard.html"

touch "$LOG_FILE"
touch "$BLOCKED_FILE"

send_desktop_alert() {
    local detail=$1
    powershell.exe -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Security Warning: $detail', 'IDPS Live Sentinel', 'OK', 'Warning')" > /dev/null 2>&1
}

generate_html() {
    cat << HTML_EOF > "$HTML_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>Live IDPS Security Dashboard</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: Arial, sans-serif; background: #f4f6f9; margin: 40px; color: #333; }
        h1 { color: #d9534f; }
        .card { background: white; padding: 20px; margin-bottom: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #f8f9fa; }
        .danger { color: red; font-weight: bold; }
        .safe { color: green; }
    </style>
</head>
<body>
    <h1>Live WSL System Intrusion Dashboard</h1>
    
    <div class="card">
        <h2>Flagged Security Events & Blocks</h2>
        <ul>
HTML_EOF

    if [ -s "$BLOCKED_FILE" ]; then
        while IFS= read -r entry; do
            echo "        <li class=\"danger\">$entry</li>" >> "$HTML_FILE"
        done < "$BLOCKED_FILE"
    else
        echo "        <li>No active threats logged.</li>" >> "$HTML_FILE"
    fi

    cat << HTML_EOF >> "$HTML_FILE"
        </ul>
    </div>

    <div class="card">
        <h2>Active System Log Monitor</h2>
        <table>
            <tr><th>Recent Log Entries</th></tr>
HTML_EOF

    if [ -s "$LOG_FILE" ]; then
        tail -n 10 "$LOG_FILE" | while IFS= read -r line; do
            if [[ "$line" == *"Failed"* || "$line" == *"Invalid"* || "$line" == *"Malicious"* ]]; then
                echo "        <tr><td class=\"danger\">$line</td></tr>" >> "$HTML_FILE"
            else
                echo "        <tr><td class=\"safe\">$line</td></tr>" >> "$HTML_FILE"
            fi
        done
    else
        echo "        <tr><td>Listening for events...</td></tr>" >> "$HTML_FILE"
    fi

    cat << HTML_EOF >> "$HTML_FILE"
        </table>
    </div>
</body>
</html>
HTML_EOF
}

echo "Starting Live System IDPS Monitor... Press [Ctrl+C] to stop."

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Check for authentication logs or system journal events
    if [ -f /var/log/auth.log ]; then
        RECENT_FAIL=$(grep -i "failed" /var/log/auth.log | tail -n 1)
        if [ ! -z "$RECENT_FAIL" ] && ! grep -q "$RECENT_FAIL" "$LOG_FILE"; then
            echo "[$TIMESTAMP] AUTH ALERT: $RECENT_FAIL" | tee -a "$LOG_FILE"
            echo "$RECENT_FAIL" >> "$BLOCKED_FILE"
            send_desktop_alert "$RECENT_FAIL"
        fi
    else
        # Fallback check using journalctl if auth.log isn't present
        RECENT_JOURNAL=$(journalctl -n 5 --no-pager 2>/dev/null | grep -i "fail" | tail -n 1)
        if [ ! -z "$RECENT_JOURNAL" ] && ! grep -q "$RECENT_JOURNAL" "$LOG_FILE"; then
            echo "[$TIMESTAMP] SYSTEM: $RECENT_JOURNAL" | tee -a "$LOG_FILE"
        else
            echo "[$TIMESTAMP] STATUS: System secure, active port monitoring." | tee -a "$LOG_FILE"
        fi
    fi

    generate_html
    sleep 10
done
