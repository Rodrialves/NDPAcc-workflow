import os
import re
import subprocess
import yaml
import json
import shutil

# Load configuration from YAML file
with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)

design_name = config['design_name']
runs_dir = config['runs_dir']
lib_files = config['lib_files']
netlist_rel_path = config['netlist_rel_path']
sdc_rel_path = config['sdc_rel_path']
area_report_rel_path = config['area_report_rel_path']
vcd_path = config.get('vcd_path')
run_tag = config.get('run_tag')

# Determine the run to analyze
if run_tag:
    selected_run = run_tag
else:
    run_dirs = [d for d in os.listdir(runs_dir) if d.startswith('RUN_') and os.path.isdir(os.path.join(runs_dir, d))]
    run_dirs.sort()
    if not run_dirs:
        print(f"No run directories found. \nPlease ensure that the runs directory '{runs_dir}' contains valid run directories.")
        exit(1)
    selected_run = run_dirs[-1]
    print(f"Selected run: {selected_run}")

run_dir = os.path.join(runs_dir, selected_run)
netlist_path = os.path.join(run_dir, netlist_rel_path)
sdc_path = os.path.join(run_dir, sdc_rel_path)

# Create reports directory
reports_dir = os.path.join(run_dir, "reports")
os.makedirs(reports_dir, exist_ok=True)

# Find and parse area report
area_report_path = None
for item in os.listdir(run_dir):
    item_path = os.path.join(run_dir, item)
    if os.path.isdir(item_path) and "rcx" in item:
        for file in os.listdir(item_path):
            if file.endswith(".json") and "metrics" in file:
                area_report_path = os.path.join(item_path, file)
                print(f"Found area report: {area_report_path}")
                break
        if area_report_path:
            break

if not area_report_path:
    print("No metrics JSON file found in rcx subdirectory.")
    exit(1)

area = {}
with open(area_report_path, 'r') as f:
    data = json.load(f)
    area['die'] = data.get('design__die__area')
    area['core'] = data.get('design__core__area')
    print(f"Design die area: {area['die']} um^2")
    print(f"Design core area: {area['core']} um^2")
    if area['die'] is None and area['core'] is None:
        print("Neither design__die__area nor design__core__area found in JSON.")
        exit(1)

# Results storage
results = []

for lib_file in lib_files:

    print(f"\nAnalyzing library file: {lib_file}")
    
    lib_report_dir = os.path.join(reports_dir, os.path.basename(lib_file))
    os.makedirs(lib_report_dir, exist_ok=True)
    power_report_path = os.path.join(lib_report_dir, "power_report.txt")
    frequency_path = os.path.join(lib_report_dir, "frequency.txt")

    # Generate TCL script for OpenSTA with debug prints
    tcl_script = f"""
    puts "Starting OpenSTA script for {lib_file}"
    set design_name "{design_name}"
    puts "Reading liberty file: {lib_file}"
    read_liberty {lib_file}
    puts "Reading Verilog netlist: {netlist_path}"
    read_verilog {netlist_path}
    puts "Linking design: {design_name}"
    link_design $design_name
    puts "Reading SDC file: {sdc_path}"
    read_sdc {sdc_path}
    """
    if vcd_path:
        vcd_basename = os.path.splitext(os.path.basename(vcd_path))[0]
        tcl_script += f"puts \"Reading VCD file: {vcd_path}\"\nread_vcd -scope {vcd_basename}/dut {vcd_path}\n"
    else:
        print("Warning: No VCD file provided. Power analysis may be inaccurate without activity factors.")
    tcl_script += """
    puts "Getting clock information"
    set clk [lindex [get_clocks] 0]
    set clk_name [get_name $clk]
    set clk_sources [get_ports $clk_name]
    puts "Clock name: $clk_name, Sources: $clk_sources"

    set min_period 0.0
    set max_period 1000.0
    set tolerance 0.01
    puts "Starting binary search for minimum period"

    while { [expr $max_period - $min_period] > $tolerance } {
        puts "Testing period: [expr ($min_period + $max_period) / 2.0] ns"
        set period [expr ($min_period + $max_period) / 2.0]
        create_clock -period $period -name $clk_name $clk_sources
        puts "Created clock with period $period ns"
        puts "Reporting worst slack"
        report_worst_slack -max > slack.txt
        set fp [open "slack.txt" r]
        set slack_line [read $fp]
        close $fp
        puts "Slack file content: $slack_line"
        if {[regexp {worst slack (-?\d+\.?\d*)} $slack_line -> slack]} {
            puts "Parsed slack: $slack ns"
        } else {
            puts "Failed to parse slack from: $slack_line, setting to 0"
            set slack 0
        }
        if { $slack >= 0 } {
            puts "Slack positive, reducing max_period to $period ns"
            set max_period $period
        } else {
            puts "Slack negative, increasing min_period to $period ns"
            set min_period $period
        }
    }

    set max_frequency [expr 1000.0 / $max_period]
    puts "Maximum frequency for {lib_file}: $max_frequency MHz"

    puts "Reporting power"
    report_power > power_report.txt
    puts "Power report generated"
    """

    # Write TCL script to file
    with open("script.tcl", "w") as f:
        f.write(tcl_script)

    # Run OpenSTA
    result = subprocess.run(["sta", "-exit", "script.tcl"], capture_output=True, text=True)
    output = result.stdout
    # print(f"OpenSTA failed for {lib_file} with return code {result.returncode}")
    print("OpenSTA output:", output)
    print("OpenSTA stderr:", result.stderr)

    # Parse maximum frequency
    max_freq = None
    for line in output.splitlines():
        if "Maximum frequency for" in line:
            match = re.search(r": (\d+\.\d+) MHz", line)
            if match:
                print(f"Found max frequency for {lib_file}: {match.group(1)} MHz")
                max_freq = float(match.group(1))
                break

    # Parse power report
    power = None
    # Read and parse the power report
    with open("power_report.txt", "r") as f:
        for line in f:
            # Look for the line starting with "Total"
            if line.startswith("Total"):
                # Split the line by whitespace and filter out empty strings
                parts = [p for p in line.split() if p]
                # Check if we have at least 5 parts (Group, Internal, Switching, Leakage, Total)
                if len(parts) >= 5:
                    try:
                        # Extract the total power (5th element, index 4) and convert to mW
                        total_power_watts = float(parts[4])
                        power = total_power_watts * 1000
                        print(f"Total Power: {power:.2f} mW")
                        break
                    except ValueError:
                        print(f"Error: Could not parse total power value from '{parts[4]}'")
                else:
                    print(f"Error: 'Total' line has insufficient columns: {line.strip()}")
                break
        else:
            print("Error: No 'Total' line found in power report.")

    # Store results
    results.append({
        "Library": os.path.basename(lib_file),
        "Max Frequency (MHz)": max_freq,
        "Power (mW)": power
    })

    # Move power report to library report directory
    shutil.move("power_report.txt", power_report_path)

    # Write frequency to file if calculated
    if max_freq is not None:
        with open(frequency_path, "w") as f:
            f.write(f"{max_freq:.3f} MHz")
    
    print("\n")

# Clean up temporary files
os.remove("script.tcl")
os.remove("slack.txt")

# Generate summary report
summary_lines = [
    f"Analysis Results for Run: {selected_run}",
    f"Design Name: {design_name}",
    "-" * 80,
    f"Design Die Area: {area['die']} um^2",
    f"Design Core Area: {area['core']} um^2",
    "-" * 80,
    f"{'Library':<40} {'Max Frequency (MHz)':<20} {'Power (mW)':<15}",
    "-" * 80,
]

for result in results:
    freq_str = f"{result['Max Frequency (MHz)']:.3f}" if result['Max Frequency (MHz)'] is not None else 'N/A'
    power_str = f"{result['Power (mW)']:.3f}" if result['Power (mW)'] is not None else 'N/A'
    summary_lines.append(f"{result['Library']:<40} {freq_str:<20} {power_str:<15}")

summary_lines.append("-" * 80)

print("\n\n")
print("Summary Report:")
print("\n")
# Print summary to terminal
for line in summary_lines:
    print(line)

# Save summary to file
summary_path = os.path.join(reports_dir, "summary_report.txt")
with open(summary_path, "w") as summary_file:
    for line in summary_lines:
        summary_file.write(line + '\n')