import os
import re
import math

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
                    columns = line.split()
                    watts_str = columns[-1]
                    try:
                        return float(watts_str)
                    except ValueError:
                        raise ValueError(f"Invalid power value: {watts_str}")
        raise ValueError("Average row not found in file")
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")

def stddev(values):
    """Calculate standard deviation of a list of numbers."""
    n = len(values)
    if n < 2:
        return 0.0
    mean = sum(values) / n
    variance = sum((x - mean) ** 2 for x in values) / (n - 1)
    return math.sqrt(variance)

def calculate_averages(stats_dir, frequencies):
    """Calculate average and stddev for time and power for each frequency and write to average.rpt."""
    output_file = os.path.join(stats_dir, "average.rpt")
    with open(output_file, 'w') as f:
        for freq in frequencies:
            times = []
            powers = []
            for run_id in range(1, 4):
                time_file = os.path.join(stats_dir, f"time_report_run{run_id}_{int(freq)}MHz.txt")
                power_file = os.path.join(stats_dir, f"power_report_run{run_id}_{int(freq)}MHz.txt")
                try:
                    times.append(extract_time(time_file))
                    powers.append(extract_power(power_file))
                except (FileNotFoundError, ValueError) as e:
                    print(f"Warning: {e} for freq {freq}, run {run_id}")
                    continue

            if times and powers:
                avg_time = sum(times) / len(times)
                avg_power = sum(powers) / len(powers)
                std_time = stddev(times)
                std_power = stddev(powers)
                f.write(f"Frequency: {int(freq)} MHz\n")
                f.write(f"Average Time: {avg_time:.2f} seconds\n")
                f.write(f"Stddev Time: {std_time:.2f} seconds\n")
                f.write(f"Average Power: {avg_power:.2f} Watts\n")
                f.write(f"Stddev Power: {std_power:.2f} Watts\n")
                f.write("\n")
            else:
                f.write(f"Frequency: {int(freq)} MHz\n")
                f.write("Warning: Insufficient data to calculate averages\n\n")

def main():
    """Main function to calculate and write averages."""
    stats_dir = "../../design_runs/acc_property/run_stats"  # Modify as needed
    frequencies = [100,150,200,220,240,260,280,300,320,325,330]  # Modify as needed
    if not os.path.exists(stats_dir):
        print(f"Error: Directory {stats_dir} not found. Ensure runs have been completed.")
        return

    calculate_averages(stats_dir, frequencies)
    print(f"Averages written to {os.path.join(stats_dir, 'average.rpt')}")

if __name__ == "__main__":
    main()