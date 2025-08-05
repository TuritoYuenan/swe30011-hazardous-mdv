import psutil
import time
import csv

parent_pid = int(input("Enter the parent PID (main.py): "))
monitor_duration = 10 * 60 # 10 minutes

def get_process_and_children_usage(pid):
    try:
        parent = psutil.Process(pid)
        procs = [parent] + parent.children(recursive=True)
        total_cpu = sum(p.cpu_percent(interval=0.1) for p in procs)
        total_mem = sum(p.memory_info().rss for p in procs)
        total_io_read = sum(p.io_counters().read_bytes for p in procs)
        total_io_write = sum(p.io_counters().write_bytes for p in procs)
        return total_cpu, total_mem, total_io_read, total_io_write
    except psutil.NoSuchProcess:
        return 0.0, 0, 0, 0

with open('elixir_monitor.csv', mode='w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['cpu_percent', 'ram_bytes', 'io_read_bytes', 'io_write_bytes'])

    start_time = time.time()
    try:
        while True:
            if time.time() - start_time > monitor_duration:
                print("10 minutes elapsed. Exiting process monitor.")
                break
            cpu, mem, io_read, io_write = get_process_and_children_usage(parent_pid)
            print(f"CPU {cpu:.2f}%, RAM {mem} bytes, IO Read {io_read} bytes, IO Write {io_write} bytes")
            writer.writerow([cpu, mem, io_read, io_write])
            csvfile.flush()
            time.sleep(1)
    except KeyboardInterrupt:
        print("Monitoring stopped by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        print("Exiting process monitor.")
