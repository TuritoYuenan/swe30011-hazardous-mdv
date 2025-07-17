import psutil
import time
import csv

parent_pid = int(input("Enter the parent PID (main.py): "))
parent = psutil.Process(parent_pid)

monitor_duration = 5 * 60  # 5 minutes
start_time = time.time()

with open('process_monitor.csv', mode='w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['cpu_percent', 'ram_mb'])

    try:
        while True:
            if time.time() - start_time > monitor_duration:
                print("Monitoring finished: time limit reached.")
                break
            children = parent.children(recursive=True)
            cpu = sum(p.cpu_percent(interval=0.1) for p in children)
            mem = sum(p.memory_info().rss for p in children) / (1024 * 1024)
            writer.writerow([cpu, mem])
            csvfile.flush()
            time.sleep(1)
    except KeyboardInterrupt:
        print("Monitoring stopped by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        print("Exiting process monitor.")
