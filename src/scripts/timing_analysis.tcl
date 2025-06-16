read_liberty /home/rodrialves/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog /home/rodrialves/MSc/design_runs/lsu_acc/runs/RUN_2025-06-09_14-42-04/final/nl/lsu_wrapper.nl.v
link_design lsu_wrapper
read_sdc /home/rodrialves/MSc/design_runs/lsu_acc/runs/RUN_2025-06-09_14-42-04/final/sdc/lsu_wrapper.sdc
read_vcd -scope lsu_wrapper_tb/dut /home/rodrialves/MSc/vcs/lsu_wrapper_tb.vcd
report_tns > timing_tns_report.txt
report_wns > timing_wns_report.txt
report_checks > timing_checks_report.txt
report_power > power_report.txt
report_annotated_check
