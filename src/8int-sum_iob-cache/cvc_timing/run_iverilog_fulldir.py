import os
import subprocess
import sys

# Define the base PDK directory
PDK_DIR = "./skywater-pdk-libs-sky130_fd_sc_hd"

# Check if the PDK directory exists
if not os.path.isdir(PDK_DIR):
    print(f"Error: PDK directory {PDK_DIR} not found!", file=sys.stderr)
    sys.exit(1)

# Get a list of all subdirectories in the PDK (recursively)
ALL_DIRS = []
for root, dirs, files in os.walk(PDK_DIR):
    for d in dirs:
        ALL_DIRS.append(os.path.abspath(os.path.join(root, d)))

# Check if directories were found
if not ALL_DIRS:
    print(f"Error: No subdirectories found in {PDK_DIR}!", file=sys.stderr)
    sys.exit(1)

# Construct the -y options for each subdirectory (library directories)
Y_OPTIONS = " ".join([f"-y {d}" for d in ALL_DIRS])

# Construct the -I options for each subdirectory (include directories)
I_OPTIONS = " ".join([f"-I {d}" for d in ALL_DIRS])

# Define the design and testbench files
DESIGN_FILE = "accelerator.nl.v"
TESTBENCH_FILE = "4num-sum_tb.v"
OUTPUT_FILE = "sim_output.vvp"

# Check if design and testbench files exist
if not os.path.isfile(DESIGN_FILE):
    print(f"Error: Design file {DESIGN_FILE} not found!", file=sys.stderr)
    sys.exit(1)
if not os.path.isfile(TESTBENCH_FILE):
    print(f"Error: Testbench file {TESTBENCH_FILE} not found!", file=sys.stderr)
    sys.exit(1)

# Construct the full iverilog command
IVERILOG_CMD = f"iverilog {Y_OPTIONS} {I_OPTIONS} -o {OUTPUT_FILE} {DESIGN_FILE} {TESTBENCH_FILE}"

# Print the command for debugging
print("Running command:")
print(IVERILOG_CMD)

# Execute the compilation command and capture output
try:
    with open("iverilog_compile.log", "w") as log_file:
        process = subprocess.run(IVERILOG_CMD, shell=True, stdout=log_file, stderr=subprocess.STDOUT, text=True)
    if process.returncode == 0:
        print("Compilation successful. Output file: sim_output.vvp")
    else:
        print(f"Compilation failed with return code {process.returncode}. Check iverilog_compile.log for details.")
        sys.exit(1)

    # Run the simulation with vvp
    VVP_CMD = f"vvp {OUTPUT_FILE}"
    print("Running simulation:")
    print(VVP_CMD)
    with open("vvp_output.log", "w") as sim_log:
        process = subprocess.run(VVP_CMD, shell=True, stdout=sim_log, stderr=subprocess.STDOUT, text=True)
    if process.returncode == 0:
        print("Simulation completed successfully. Output logged to vvp_output.log")
    else:
        print(f"Simulation failed with return code {process.returncode}. Check vvp_output.log for details.")

except subprocess.CalledProcessError as e:
    print(f"Error executing command: {e}", file=sys.stderr)
    with open("iverilog_compile.log", "w") as log_file:
        log_file.write(f"Error: {e}\n")
except Exception as e:
    print(f"Unexpected error: {e}", file=sys.stderr)
    sys.exit(1)