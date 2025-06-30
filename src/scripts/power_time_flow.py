import subprocess
import os
import json
import time

def update_config_clock(top_dir, frequency):
    """Update CLOCK_PERIOD in config.json for the given frequency."""
    config_file = os.path.join(top_dir, "config.json")
    if not os.path.exists(config_file):
        raise FileNotFoundError(f"Config file not found: {config_file}")
    
    period = 1000 / frequency  # Convert MHz to ns
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    config["CLOCK_PERIOD"] = period
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)

def start_powerstat(run_id, frequency, stats_dir):
    """Start powerstat to measure system power consumption."""
    power_file = os.path.join(stats_dir, f"power_report_run{run_id}_{int(frequency)}MHz.txt")
    power_err = os.path.join(stats_dir, f"power_report_run{run_id}_{int(frequency)}MHz.err")
    return subprocess.Popen(
        ["sudo", "powerstat","-R", "-c", "-z", "-d", "2", "1", "1000000"],
        stdout=open(power_file, "w"),
        stderr=open(power_err, "w")
    )

def run_openlane(top_dir, run_id, frequency, stats_dir):
    """Run OpenLane 2 with time, capturing output for terminal and logs."""
    time_file = os.path.join(stats_dir, f"time_report_run{run_id}_{int(frequency)}MHz.txt")
    output_file = os.path.join(stats_dir, f"output_run{run_id}_{int(frequency)}MHz.log")
    cmd = ["/usr/bin/time", "-v", "openlane", os.path.join(top_dir, "config.json")]
    with open(output_file, 'a') as f:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=open(time_file, "w"),
            text=True
        )
        for line in process.stdout:
            print(line, end='')
            f.write(line)
        process.wait()
    return process.returncode

def parse_time(time_str):
    """Parse time string to seconds."""
    if ':' in time_str:
        parts = time_str.split(':')
        if len(parts) == 2:  # m:ss
            minutes = int(parts[0])
            seconds = float(parts[1])
            return minutes * 60 + seconds
        elif len(parts) == 3:  # h:mm:ss
            hours = int(parts[0])
            minutes = int(parts[1])
            seconds = float(parts[2])
            return hours * 3600 + minutes * 60 + seconds
    else:
        return float(time_str)

def extract_time(file_path):
    """Extract wall clock time from time report file."""
    try:
        with open(file_path, 'r') as f:
            for line in f:
                if "Elapsed (wall clock) time (h:mm:ss or m:ss)" in line:
                    time_str = line.split(": ", 1)[1].strip()
                    return parse_time(time_str)
        raise ValueError("Time not found in file")
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")

def extract_power(file_path):
    """Extract average power consumption from power report file."""
    try:
        with open(file_path, 'r') as f:
            for line in f:
                if "Average" in line:  # Match "Average" without colon
                    # Split the line into columns (assuming space-separated values)
                    columns = line.split()
                    watts_str = columns[-1]  # Watts is the last column
                    try:
                        return float(watts_str)  # Convert to float
                    except ValueError:
                        raise ValueError(f"Invalid power value: {watts_str}")
        raise ValueError("Average row not found in file")
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")

def compute_averages(frequencies, stats_dir, output_file):
    """Compute and save average time and power for each frequency."""
    with open(output_file, 'w') as f:
        for freq in frequencies:
            times = []
            powers = []
            for run in range(1, 4):
                time_file = os.path.join(stats_dir, f"time_report_run{run}_{int(freq)}MHz.txt")
                power_file = os.path.join(stats_dir, f"power_report_run{run}_{int(freq)}MHz.txt")
                times.append(extract_time(time_file))
                powers.append(extract_power(power_file))
            avg_time = sum(times) / len(times)
            avg_power = sum(powers) / len(powers)
            f.write(f"Frequency: {freq} MHz\n")
            f.write(f"Average Time: {avg_time:.2f} seconds\n")
            f.write(f"Average Power: {avg_power:.2f} W\n")
            f.write("\n")

def main():
    """Main function to run OpenLane 2 for different clock frequencies."""
    # User-defined clock frequencies (MHz)
    frequencies = [100,150,180,200,220,240]  # Modify as needed
    top_dir = "../../design_runs/acc_property"  # Top-level directory with config.json and design files

    stats_dir = os.path.join(top_dir, "run_stats")
    os.makedirs(stats_dir, exist_ok=True)

    # Process each clock frequency
    for freq in frequencies:
        print(f"\nProcessing clock frequency: {freq} MHz")
        update_config_clock(top_dir, freq)
        
        # Run OpenLane 2 three times
        for i in range(1, 4):
            print(f"Starting run {i} for {freq} MHz")
            powerstat_proc = start_powerstat(i, freq, stats_dir)
            run_openlane(top_dir, i, freq, stats_dir)
            powerstat_proc.terminate()
            time.sleep(1)  # Ensure powerstat terminates
            powerstat_proc.kill()  # Ensure powerstat is killed
            print(f"Completed run {i} for {freq} MHz")

    print(f"\nAll runs completed. Statistics files are in {stats_dir}")

    output_file = os.path.join(stats_dir, "average_report.txt")
    compute_averages(frequencies, stats_dir, output_file)
    print(f"\nAll runs completed. Averages saved to {output_file}")

if __name__ == "__main__":
    main()