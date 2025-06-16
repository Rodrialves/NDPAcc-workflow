import os
import subprocess
import sys
import yaml

# Path to the YAML configuration file
CONFIG_FILE = "cvc.yaml"

# Output log file
OUTPUT_LOG = "cvc_output.log"

# Base directory for relative paths
BASE_DIR = "./skywater-pdk-libs-sky130_fd_sc_hd/cells"

# Check if the base directory exists
if not os.path.isdir(BASE_DIR):
    print(f"Error: Base directory {BASE_DIR} not found!", file=sys.stderr)
    sys.exit(1)

# Check if the YAML file exists
if not os.path.isfile(CONFIG_FILE):
    print(f"Error: Configuration file {CONFIG_FILE} not found!", file=sys.stderr)
    sys.exit(1)

# Read the YAML configuration
try:
    with open(CONFIG_FILE, "r") as f:
        config = yaml.safe_load(f)
except Exception as e:
    print(f"Error reading {CONFIG_FILE}: {e}", file=sys.stderr)
    sys.exit(1)

# Validate required fields in the YAML
if not config or "incdir" not in config or "files" not in config:
    print("Error: YAML file must contain 'incdir' and 'files' fields!", file=sys.stderr)
    sys.exit(1)

# Extract directories and files
incdirs = config["incdir"]
files = config["files"]

# Construct full paths for directories (assuming they are under cells/)
lib_dirs = [os.path.abspath(os.path.join(BASE_DIR, d)) for d in incdirs]
inc_dirs = lib_dirs  # Use the same directories for both -y and +incdir+ as specified

# Validate library/include directories
for dir in lib_dirs:
    if not os.path.isdir(dir):
        print(f"Warning: Directory {dir} not found, skipping...", file=sys.stderr)

# Search for each file in all subdirectories of cells/
file_paths = []
for file in files:
    found = False
    for root, dirs, subfiles in os.walk(BASE_DIR):
        if file in subfiles:
            file_path = os.path.abspath(os.path.join(root, file))
            file_paths.append(file_path)
            found = True
            print(f"Found {file} in {root}")
            break
    if not found:
        print(f"Error: File {file} not found in any subdirectory of {BASE_DIR}!", file=sys.stderr)
        sys.exit(1)

# Construct the +incdir+ options for include directories
INCDIR_OPTIONS = " ".join([f"+incdir+{d}" for d in inc_dirs if os.path.isdir(d)])
INCDIR_OPTIONS += "+incdir+../"  # Add the parent directory as specified in the original command

# Construct the list of files to compile
FILES = " ".join(file_paths)

# Construct the full CVC command (including your original +sdf_annotate option)
CVC_CMD = f"cvc64 {INCDIR_OPTIONS} +verbose +sdf_annotate acc.sdf {FILES} 4num-sum_tb.v accelerator.nl.v"

# Print the command for debugging
print("Running command:")
print(CVC_CMD)

# Execute the command and capture output
try:
    with open(OUTPUT_LOG, "w") as log_file:
        process = subprocess.run(CVC_CMD, shell=True, stdout=log_file, stderr=subprocess.STDOUT, text=True)
    if process.returncode == 0:
        print("CVC command executed successfully. Output logged to cvc_output.log")
    else:
        print(f"CVC command failed with return code {process.returncode}. Check {OUTPUT_LOG} for details.")
except subprocess.CalledProcessError as e:
    print(f"Error executing CVC command: {e}", file=sys.stderr)
    with open(OUTPUT_LOG, "w") as log_file:
        log_file.write(f"Error: {e}\n")
except Exception as e:
    print(f"Unexpected error: {e}", file=sys.stderr)
    sys.exit(1)