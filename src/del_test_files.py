import os
import glob
import sys

def delete_vcd_and_out_files(folder_path):
    """
    Deletes all .vcd and .out files from the specified folder.
    
    Args:
        folder_path (str): Path to the folder to search for .vcd and .out files.
    """
    # Check if the folder exists
    if not os.path.isdir(folder_path):
        print(f"Error: The folder '{folder_path}' does not exist.")
        return

    # Define the file extensions to delete
    extensions = ['*.vcd', '*.out']
    
    # Counter for deleted files
    deleted_count = 0

    # Iterate through each extension
    for ext in extensions:
        # Find all files matching the extension in the folder
        files = glob.glob(os.path.join(folder_path, ext))
        
        # Delete each file
        for file in files:
            try:
                os.remove(file)
                print(f"Deleted: {file}")
                deleted_count += 1
            except Exception as e:
                print(f"Error deleting {file}: {e}")

    # Summary
    if deleted_count == 0:
        print("No .vcd or .out files found in the folder.")
    else:
        print(f"Total files deleted: {deleted_count}")

if __name__ == "__main__":
    # Check if a folder path is provided as a command-line argument
    if len(sys.argv) != 2:
        print("Usage: python3 del_files.py <folder_path>")
        sys.exit(1)
    
    # Get the folder path from the command-line argument
    folder_path = sys.argv[1]
    
    # Resolve relative paths (e.g., "." to absolute path)
    folder_path = os.path.abspath(folder_path)
    
    print(f"Cleaning folder: {folder_path}")
    delete_vcd_and_out_files(folder_path)