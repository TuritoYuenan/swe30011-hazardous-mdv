import subprocess
import time
import sys

scripts = [
	("uvicorn", "edge-api.srv-api:app"),  # (command, module:app)
	(sys.executable, "edge-etl/srv-etl.py"),
	(sys.executable, "edge-mon/srv-mon.py"),
]

processes = []

try:
	for cmd, target in scripts:
		print(f"Starting {target} with {cmd}...")
		if cmd == "uvicorn":
			p = subprocess.Popen([cmd, target, "--reload"])
		else:
			p = subprocess.Popen([cmd, target])
		processes.append(p)
		time.sleep(1)

	print("All scripts started. Press Ctrl+C to terminate.")

	for p in processes:
		p.wait()

except KeyboardInterrupt:
	print("Terminating all scripts...")
	for p in processes:
		p.terminate()
	print("All scripts terminated.")
