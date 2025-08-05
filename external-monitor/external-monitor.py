import psutil
import time
import csv

parent_pid = int(input("Enter the parent PID (main.py): "))
max_records = 300  # Collect 300 records

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
    writer.writerow(['timestamp', 'cpu_percent', 'ram_bytes', 'io_read_bytes', 'io_write_bytes'])

    record_count = 0
    last_io_read = last_io_write = None
    try:
        while record_count < max_records:
            cpu, mem, io_read, io_write = get_process_and_children_usage(parent_pid)

            read_bps = write_bps = 0
            if last_io_read is not None and last_io_write is not None:
                read_bps = io_read - last_io_read
                write_bps = io_write - last_io_write

            last_io_read, last_io_write = io_read, io_write
            now = time.strftime("%H:%M:%S")

            print(f"[{now}] CPU {cpu:.2f}%, RAM {mem} bytes, IO Read {read_bps} bytes/s, IO Write {write_bps} bytes/s")
            writer.writerow([now, cpu, mem, read_bps, write_bps])
            csvfile.flush()
            record_count += 1
            time.sleep(1)
        print("Collected 300 records. Exiting process monitor.")
    except KeyboardInterrupt:
        print("Monitoring stopped by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        print("Exiting process monitor.")
