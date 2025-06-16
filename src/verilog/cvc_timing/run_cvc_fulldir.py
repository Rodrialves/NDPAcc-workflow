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

# Construct the -y and +incdir+ options for each subdirectory
Y_OPTIONS = " ".join([f"-y {d}" for d in ALL_DIRS])
INCDIR_OPTIONS = " ".join([f"+incdir+{d}" for d in ALL_DIRS])

# Construct the full CVC command
CVC_CMD = f"cvc64 {Y_OPTIONS} {INCDIR_OPTIONS} +incdir+../ +sdf_annotate acc.sdf accelerator.nl.v 4num-sum_tb.v"

# Print the command for debugging
print("Running command:")
print(CVC_CMD)

# Execute the command and capture output
try:
    with open("cvc_output.log", "w") as log_file:
        process = subprocess.run(CVC_CMD, shell=True, stdout=log_file, stderr=subprocess.STDOUT, text=True)
    if process.returncode == 0:
        print("CVC command executed successfully. Output logged to cvc_output.log")
    else:
        print(f"CVC command failed with return code {process.returncode}. Check cvc_output.log for details.")
except subprocess.CalledProcessError as e:
    print(f"Error executing CVC command: {e}", file=sys.stderr)
    with open("cvc_output.log", "w") as log_file:
        log_file.write(f"Error: {e}\n")
except Exception as e:
    print(f"Unexpected error: {e}", file=sys.stderr)
    sys.exit(1)