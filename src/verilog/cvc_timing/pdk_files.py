import os
import glob
import shutil

# Define the source and destination directories
cells_dir = "./skywater-pdk-libs-sky130_fd_sc_hd/cells"
output_dir = "./pdk_cells"

# Create the output directory if it doesn't exist
if os.path.exists(output_dir):
    shutil.rmtree(output_dir)  # Remove existing directory to avoid conflicts
os.makedirs(output_dir)

# Patterns to exclude (behavioral, blackbox, etc.)
exclude_patterns = ["blackbox", "functional", "specify", "pp", "symbol", "tb"]

# Find all .v files in the cells directory, excluding unwanted variants
for root, dirs, files in os.walk(cells_dir):
    for file in files:
        # Check if the file ends with .v and matches the sky130_fd_sc_hd__*.v pattern
        if file.endswith(".v") and file.startswith("sky130_fd_sc_hd__"):
            # Skip files containing any of the exclude patterns
            if any(pattern in file for pattern in exclude_patterns):
                continue
            # Create the full path for the source file
            src_path = os.path.join(root, file)
            # Destination path in pdk_cells
            dst_path = os.path.join(output_dir, file)
            # Create a symbolic link
            os.symlink(os.path.abspath(src_path), dst_path)
            print(f"Linked: {src_path} -> {dst_path}")

print(f"Symbolic links created in {output_dir}. Total files linked: {len(os.listdir(output_dir))}")
