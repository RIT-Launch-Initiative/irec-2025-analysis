import serial
import csv
import threading
import time

# Configure the serial port (update 'COM3' or '/dev/ttyACM0' as needed)
ser = serial.Serial('COM9', 9600, timeout=1)
time.sleep(2)  # Give Arduino time to reset

filename = 'log_data.csv'
stop_event = threading.Event()
start_time = None  # Track when logging starts

def read_serial():
    """Reads serial data and writes CSV lines to a file."""
    global start_time
    with open(filename, mode='w', newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow(['Timestamp (ms)', 'AOA'])  # Write header
        print("Logging started. Waiting for data...")
        while not stop_event.is_set():
            line = ser.readline().decode('utf-8').strip()
            if line:
                print("Received:", line)
                # Handle start command confirmation
                if line.startswith("Test"):
                    start_time = time.time() * 1000  # Convert to milliseconds
                    continue
                # Stop logging if Arduino sends the STOP marker
                if line == "STOP":
                    stop_event.set()
                    continue
                # Skip other non-data lines
                if line.startswith("Zero") or line.startswith("Ready"):
                    continue
                
                # Process data lines
                try:
                    parts = line.split(',')
                    if start_time is not None and len(parts) > 0:
                        current_time = time.time() * 1000
                        timestamp = int(current_time - start_time)
                        aoa_value = float(parts[0])  # Assuming AOA is the first value
                        csv_writer.writerow([timestamp, aoa_value])
                except (ValueError, IndexError) as e:
                    print(f"Error processing line: {line}, Error: {e}")
        print("Logging ended. Data saved to", filename)

def send_commands():
    """Reads user input and sends commands to the Arduino."""
    print("Enter commands (z: zero, s: start, e: end):")
    while not stop_event.is_set():
        cmd = input()
        if cmd:
            ser.write(cmd.strip().encode())
            if cmd.lower() == 'e':  # Optionally, trigger stopping here too
                print("Stop command sent.")
                # We don't set the event here because the Arduino will send "STOP" to confirm

# Start both threads
read_thread = threading.Thread(target=read_serial)
cmd_thread = threading.Thread(target=send_commands)

read_thread.start()
cmd_thread.start()

read_thread.join()
cmd_thread.join()
ser.close()
