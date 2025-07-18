import psutil
import time
import csv

parent_pid = int(input("Enter the parent PID (main.py): "))
monitor_duration = 5 * 60 # 5 minutes

def get_process_and_children_usage(pid):
    try:
        parent = psutil.Process(pid)
        procs = [parent] + parent.children(recursive=True)
        total_cpu = sum(p.cpu_percent(interval=0.1) for p in procs)
        total_mem = sum(p.memory_info().rss for p in procs)
        return total_cpu, total_mem
    except psutil.NoSuchProcess:
        return 0.0, 0

with open('elixir_monitor.csv', mode='w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['cpu_percent', 'ram_bytes'])

    start_time = time.time()
    try:
        while True:
            if time.time() - start_time > monitor_duration:  # 5 minutes = 300 seconds
                print("5 minutes elapsed. Exiting process monitor.")
                break
            cpu, mem = get_process_and_children_usage(parent_pid)
            print(f"CPU {cpu:.2f}%, RAM {mem} bytes")
            writer.writerow([cpu, mem])
            csvfile.flush()
            time.sleep(1)
    except KeyboardInterrupt:
        print("Monitoring stopped by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        print("Exiting process monitor.")
