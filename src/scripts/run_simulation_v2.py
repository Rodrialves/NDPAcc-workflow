import os
import subprocess
import shutil
import yaml
import argparse


# Configuration
YAML_FILE = "config_run.yaml"  # Name of the YAML configuration file
IVERILOG_CMD = "iverilog"  # Icarus Verilog compiler
VERILATOR_CMD = "verilator"  # Verilator compiler
VVP_CMD = "vvp"            # Icarus Verilog runtime
GTKWAVE_CMD = "gtkwave"    # GTKWave viewer


def check_tools(compiler):
    """Check if required tools are installed based on the compiler choice."""
    if compiler == "iverilog":
        tools = [IVERILOG_CMD, VVP_CMD, GTKWAVE_CMD]
    else:  # verilator
        tools = [VERILATOR_CMD, GTKWAVE_CMD]
    
    for tool in tools:
        if shutil.which(tool) is None:
            print(f"Error: {tool} is not installed or not in PATH.")
            exit(1)


def load_yaml_config(yaml_file):
    """Load the YAML configuration file."""
    with open(yaml_file, 'r') as file:
        config = yaml.safe_load(file)
    return config


def compile_verilog(compiler, src_files, sim_out, sim_location, src_location, pdk_files=None):
    """Compile the Verilog files into an executable using the specified compiler."""
    if compiler == "iverilog":
        if pdk_files is not None:
            cmd = ["iverilog", "-I", sim_location, "-I", src_location, "-l", pdk_files, "-o", sim_out] + src_files.split()
        else:
            cmd = ["iverilog", "-g2012", "-gspecify", "-I", sim_location, "-I", src_location, "-I", "../verilog/" , "-o", sim_out] + src_files.split()
        print(f"Compiling with command: {' '.join(cmd)}")
        try:
            subprocess.run(cmd, check=True)
            print(f"Compilation successful. Generated: {sim_out}")
        except subprocess.CalledProcessError as e:
            print(f"Compilation failed: {e}")
            exit(1)
    else:  # verilator
        # Ensure -I options are formatted as a single string (e.g., -I../path)
        cmd = [
            "verilator", "--cc", "--timing", "--trace", "--exe", "--Wno-WIDTH",
            f"-I{sim_location}", f"-I{src_location}"
        ] + src_files.split() + ["-o", f"{sim_out}.v"]
        try:
            subprocess.run(cmd, check=True)
            print(f"Verilator compilation successful. Generated C++ files in obj_dir.")
            # Build the executable
            build_cmd = ["make", "-C", "obj_dir", "-f", f"V{sim_out}.mk", f"V{sim_out}"]
            print(f"Building with command: {' '.join(build_cmd)}")
            subprocess.run(build_cmd, check=True)
            print(f"Build successful. Generated executable: obj_dir/V{sim_out}")
        except subprocess.CalledProcessError as e:
            print(f"Verilator compilation or build failed: {e}")
            exit(1)


def run_simulation(compiler, sim_out, use_sdf=False, sdf_file=None):
    """Run the simulation using the specified compiler's runtime, optionally with SDF."""
    if compiler == "iverilog":
        cmd = [VVP_CMD, sim_out]
        if use_sdf and sdf_file:
            cmd += [f"+sdf_file={sdf_file}"]
        print(f"Running simulation with command: {' '.join(cmd)}")
        try:
            subprocess.run(cmd, check=True)
            print("Simulation completed.")
        except subprocess.CalledProcessError as e:
            print(f"Simulation failed: {e}")
            exit(1)
    else:  # verilator
        cmd = [f"./obj_dir/V{sim_out}"]
        if use_sdf and sdf_file:
            cmd += [f"+sdf_file={sdf_file}"]
        print(f"Running simulation with command: {' '.join(cmd)}")
        try:
            subprocess.run(cmd, check=True)
            print("Simulation completed.")
        except subprocess.CalledProcessError as e:
            print(f"Simulation failed: {e}")
            exit(1)


def open_gtkwave(wave_out):
    """Open GTKWave to view the waveform file."""
    waveform_file = f"{wave_out}.vcd"
    if os.path.exists(waveform_file):
        cmd = [GTKWAVE_CMD, waveform_file]
        try:
            subprocess.Popen(cmd)
            print(f"Opened GTKWave with {waveform_file}")
        except Exception as e:
            print(f"Failed to open GTKWave: {e}")
    else:
        print(f"Error: Waveform file {waveform_file} not found.")


def main():
    """Main function to orchestrate the simulation process."""
    parser = argparse.ArgumentParser(description="Run Verilog simulation with configurable source files.")
    parser.add_argument(
        "--source-set",
        nargs="+",
        choices=["fs_tb", "mem_tb", "loaded_mem_tb", "acc_tb", "ram_tb", "fifo_tb", "lsu_tb", "lsu_wrapper_tb", "acc_max_min_tb", "acc_property_tb"],
        default=["fs_tb"],
        help="Choose which simulation to run (default: fs_tb)."
    )
    parser.add_argument(
        "--compiler",
        choices=["iverilog", "verilator"],
        default="iverilog",
        help="Choose which Verilog compiler to use (default: iverilog)."
    )
    parser.add_argument(
        "--use-sdf",
        action="store_true",
        help="Enable SDF backannotation during simulation (SDF file must be specified in config.yaml)."
    )
    args = parser.parse_args()

    check_tools(args.compiler)
    config = load_yaml_config(YAML_FILE)
    sim_location = config['sim_location']
    src_location = config['src_location']

    # Variables to hold configuration for the selected testbench
    src_files = []
    wave_out = ""
    sim_out = ""
    sdf_file = None

    # Combine source files and fetch SDF file from the selected sets
    if "fs_tb" in args.source_set:
        print("\n------------------------\nRunning full system testbench.\n------------------------\n")
        src_files = config['tb_files_top_module'] + config['IoB_files'] + config['ram_files'] + config['acc_files'] + config['ctrl_files']
        wave_out = config['wave_out_top_module']
        sim_out = config['sim_out_top_module']
        sdf_file = config.get('sdf_file_top_module', None)
    elif "mem_tb" in args.source_set:
        print("\n------------------------\nRunning memory testbench.\n------------------------\n")
        src_files = config['tb_files_mem_module'] + config['IoB_files'] + config['ram_files'] + config['acc_files']
        wave_out = config['wave_out_mem_module']
        sim_out = config['sim_out_mem_module']
        sdf_file = config.get('sdf_file_mem_module', None)
    elif "loaded_mem_tb" in args.source_set:
        print("\n------------------------\nRunning loaded memory testbench.\n------------------------\n")
        src_files = config['tb_files_mem_loaded_module'] + config['ram_files'] + config['acc_files'] + config['IoB_files']
        wave_out = config['wave_out_mem_loaded_module']
        sim_out = config['sim_out_mem_loaded_module']
        sdf_file = config.get('sdf_file_mem_loaded_module', None)
    elif "acc_tb" in args.source_set:
        print("\n------------------------\nRunning accelerator testbench.\n------------------------\n")
        src_files = config['tb_files_acc_module'] + config['acc_files']
        wave_out = config['wave_out_acc_module']
        sim_out = config['sim_out_acc_module']
        sdf_file = config.get('sdf_file_acc_module', None)
    elif "ram_tb" in args.source_set:
        print("\n------------------------\nRunning RAM testbench.\n------------------------\n")
        src_files = config['tb_files_ram_module'] + config['ram_files']
        wave_out = config['wave_out_ram_module']
        sim_out = config['sim_out_ram_module']
        sdf_file = config.get('sdf_file_ram_module', None)
    elif "fifo_tb" in args.source_set:
        print("\n------------------------\nRunning FIFO testbench.\n------------------------\n")
        src_files = config['tb_files_fifo_module'] + config['fifo_files']
        wave_out = config['wave_out_fifo_module']
        sim_out = config['sim_out_fifo_module']
        sdf_file = config.get('sdf_file_fifo_module', None)
    elif "lsu_tb" in args.source_set:
        print("\n------------------------\nRunning LSU testbench.\n------------------------\n")
        src_files = config['tb_files_lsu_module'] + config['lsu_files'] + config['acc_files'] + config['fifo_files']
        wave_out = config['wave_out_lsu_module']
        sim_out = config['sim_out_lsu_module']
        sdf_file = config.get('sdf_file_lsu_module', None)
    elif "lsu_wrapper_tb" in args.source_set:
        print("\n------------------------\nRunning system wrapper testbench.\n------------------------\n")
        src_files = config['tb_files_lsu_wrapper_module'] + config['lsu_wrapper_files'] + config['lsu_files'] + config['acc_files'] + config['fifo_files']
        wave_out = config['wave_out_lsu_wrapper_module']
        sim_out = config['sim_out_lsu_wrapper_module']
        sdf_file = config.get('sdf_file_lsu_wrapper_module', None)
    elif "acc_max_min_tb" in args.source_set:
        print("\n------------------------\nRunning accelerator max/min testbench.\n------------------------\n")
        src_files = config['tb_files_acc_max_min_module'] + config['acc_max_min_files']
        wave_out = config['wave_out_acc_max_min_module']
        sim_out = config['sim_out_acc_max_min_module']
        sdf_file = config.get('sdf_file_acc_max_min_module', None)
    elif "acc_property_tb" in args.source_set:
        print("\n------------------------\nRunning accelerator property testbench.\n------------------------\n")
        src_files = config['tb_files_acc_property_module'] + config['acc_property_files']
        wave_out = config['wave_out_acc_property_module']
        sim_out = config['sim_out_acc_property_module']
        sdf_file = config.get('sdf_file_acc_property_module', None)

    # Validate SDF usage
    if args.use_sdf and not sdf_file:
        print(f"Error: --use-sdf is enabled, but no SDF file is specified for {args.source_set} in config.yaml.")
        exit(1)

    pdk_files = None
    if args.use_sdf and sdf_file:
        pdk_files = " ".join(f"-l {f}, " for f in config["pdk_files"])
        print(f"\nPDK files for SDF: {pdk_files}\n")  

    # Join all source files into a single string
    src_files_str = " ".join(src_files)

    # Compile and run simulation based on the chosen compiler
    compile_verilog(args.compiler, src_files_str, sim_out, sim_location, src_location, pdk_files)
    run_simulation(args.compiler, sim_out, use_sdf=args.use_sdf, sdf_file=sdf_file)
    open_gtkwave(wave_out)


if __name__ == "__main__":
    main()
