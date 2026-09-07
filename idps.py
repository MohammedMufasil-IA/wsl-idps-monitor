import subprocess
import time
from datetime import datetime

LOGFILE = "idps_python.log"

print("Starting Python IDPS Monitoring... Press [Ctrl+C] to stop.")

try:
    while True:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        header = f"=== Python IDPS Security Check: {timestamp} ==="

        # Run the ss -tuln command securely via subprocess
        result = subprocess.run(["ss", "-tuln"], capture_output=True, text=True)

        # Write results to the log file
        with open(LOGFILE, "a") as f:
            f.write(header + "\n")
            f.write("Checking active network connections...\n")
            f.write(result.stdout)
            f.write("-----------------------------------\n")

        # Print live output to terminal
        print(header)
        print(result.stdout)
        print("-----------------------------------")

        time.sleep(10)
except KeyboardInterrupt:
    print("\nIDPS monitoring stopped.")
