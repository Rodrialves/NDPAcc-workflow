#! /usr/bin/vvp
:ivl_version "11.0 (stable)";
:ivl_delay_selection "TYPICAL";
:vpi_time_precision - 12;
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_textio.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/v2005_math.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/va_math.vpi";
S_0x5c09d85573b0 .scope module, "sync_fifo_tb" "sync_fifo_tb" 2 3;
 .timescale -9 -12;
P_0x5c09d8513ea0 .param/l "DATA_WIDTH" 0 2 4, +C4<00000000000000000000000000100000>;
v0x5c09d8579380_0 .var "clk", 0 0;
v0x5c09d8579440_0 .var "data_in", 31 0;
v0x5c09d85794e0_0 .net "data_out", 31 0, v0x5c09d85789a0_0;  1 drivers
v0x5c09d85795e0_0 .net "empty", 0 0, L_0x5c09d857a0f0;  1 drivers
v0x5c09d85796b0_0 .net "full", 0 0, L_0x5c09d8542490;  1 drivers
v0x5c09d8579750_0 .var "r_en", 0 0;
v0x5c09d8579820_0 .var/i "rd_ptr", 31 0;
v0x5c09d85798c0_0 .var "rst_n", 0 0;
v0x5c09d8579990_0 .var "w_en", 0 0;
v0x5c09d8579a60 .array "wdata_array", 1023 0, 31 0;
v0x5c09d8579b00_0 .var/i "wr_ptr", 31 0;
E_0x5c09d855d9e0 .event edge, v0x5c09d8578f40_0;
S_0x5c09d8557590 .scope begin, "$ivl_for_loop0" "$ivl_for_loop0" 2 51, 2 51 0, S_0x5c09d85573b0;
 .timescale -9 -12;
v0x5c09d8540540_0 .var/i "i", 31 0;
E_0x5c09d8557ca0 .event negedge, v0x5c09d85787b0_0;
E_0x5c09d8557ed0 .event posedge, v0x5c09d85787b0_0;
S_0x5c09d85780f0 .scope begin, "$ivl_for_loop1" "$ivl_for_loop1" 2 74, 2 74 0, S_0x5c09d85573b0;
 .timescale -9 -12;
v0x5c09d8542670_0 .var/i "i", 31 0;
S_0x5c09d8578330 .scope module, "s_fifo" "fifo" 2 18, 3 3 0, S_0x5c09d85573b0;
 .timescale -9 -12;
    .port_info 0 /INPUT 1 "clk";
    .port_info 1 /INPUT 1 "rst_n";
    .port_info 2 /INPUT 1 "w_en";
    .port_info 3 /INPUT 1 "r_en";
    .port_info 4 /INPUT 32 "data_in";
    .port_info 5 /OUTPUT 32 "data_out";
    .port_info 6 /OUTPUT 1 "full";
    .port_info 7 /OUTPUT 1 "empty";
P_0x5c09d8578510 .param/l "PTR_WIDTH" 0 3 11, +C4<00000000000000000000000000000100>;
L_0x5c09d85403a0 .functor XOR 1, v0x5c09d8579990_0, v0x5c09d8579750_0, C4<0>, C4<0>;
L_0x5c09d8542490 .functor AND 1, L_0x5c09d8579e20, L_0x5c09d85403a0, C4<1>, C4<1>;
L_0x754a3f2d0018 .functor BUFT 1, C4<0001>, C4<0>, C4<0>, C4<0>;
v0x5c09d853e950_0 .net/2u *"_ivl_0", 3 0, L_0x754a3f2d0018;  1 drivers
v0x5c09d853f0e0_0 .net *"_ivl_10", 0 0, L_0x5c09d85403a0;  1 drivers
L_0x754a3f2d0060 .functor BUFT 1, C4<0001>, C4<0>, C4<0>, C4<0>;
v0x5c09d8542b00_0 .net/2u *"_ivl_4", 3 0, L_0x754a3f2d0060;  1 drivers
v0x5c09d8544380_0 .net *"_ivl_8", 0 0, L_0x5c09d8579e20;  1 drivers
v0x5c09d85787b0_0 .net "clk", 0 0, v0x5c09d8579380_0;  1 drivers
v0x5c09d85788c0_0 .net "data_in", 31 0, v0x5c09d8579440_0;  1 drivers
v0x5c09d85789a0_0 .var "data_out", 31 0;
v0x5c09d8578a80_0 .net "empty", 0 0, L_0x5c09d857a0f0;  alias, 1 drivers
v0x5c09d8578b40 .array "fifo", 15 0, 31 0;
v0x5c09d8578c00_0 .net "full", 0 0, L_0x5c09d8542490;  alias, 1 drivers
v0x5c09d8578cc0_0 .net "r_en", 0 0, v0x5c09d8579750_0;  1 drivers
v0x5c09d8578d80_0 .var "r_ptr", 3 0;
v0x5c09d8578e60_0 .net "r_ptr_next", 3 0, L_0x5c09d8579cd0;  1 drivers
v0x5c09d8578f40_0 .net "rst_n", 0 0, v0x5c09d85798c0_0;  1 drivers
v0x5c09d8579000_0 .net "w_en", 0 0, v0x5c09d8579990_0;  1 drivers
v0x5c09d85790c0_0 .var "w_ptr", 3 0;
v0x5c09d85791a0_0 .net "w_ptr_next", 3 0, L_0x5c09d8579bd0;  1 drivers
E_0x5c09d85596b0/0 .event negedge, v0x5c09d8578f40_0;
E_0x5c09d85596b0/1 .event posedge, v0x5c09d85787b0_0;
E_0x5c09d85596b0 .event/or E_0x5c09d85596b0/0, E_0x5c09d85596b0/1;
L_0x5c09d8579bd0 .arith/sum 4, v0x5c09d85790c0_0, L_0x754a3f2d0018;
L_0x5c09d8579cd0 .arith/sum 4, v0x5c09d8578d80_0, L_0x754a3f2d0060;
L_0x5c09d8579e20 .cmp/eq 4, L_0x5c09d8579bd0, v0x5c09d8578d80_0;
L_0x5c09d857a0f0 .cmp/eq 4, v0x5c09d85790c0_0, v0x5c09d8578d80_0;
    .scope S_0x5c09d8578330;
T_0 ;
    %wait E_0x5c09d85596b0;
    %load/vec4 v0x5c09d8578f40_0;
    %nor/r;
    %flag_set/vec4 8;
    %jmp/0xz  T_0.0, 8;
    %pushi/vec4 0, 0, 4;
    %assign/vec4 v0x5c09d85790c0_0, 0;
    %pushi/vec4 0, 0, 4;
    %assign/vec4 v0x5c09d8578d80_0, 0;
    %pushi/vec4 0, 0, 32;
    %assign/vec4 v0x5c09d85789a0_0, 0;
T_0.0 ;
    %jmp T_0;
    .thread T_0;
    .scope S_0x5c09d8578330;
T_1 ;
    %wait E_0x5c09d8557ed0;
    %load/vec4 v0x5c09d8579000_0;
    %load/vec4 v0x5c09d8578c00_0;
    %nor/r;
    %and;
    %flag_set/vec4 8;
    %jmp/0xz  T_1.0, 8;
    %load/vec4 v0x5c09d85788c0_0;
    %load/vec4 v0x5c09d85790c0_0;
    %pad/u 6;
    %ix/vec4 3;
    %ix/load 4, 0, 0; Constant delay
    %assign/vec4/a/d v0x5c09d8578b40, 0, 4;
    %load/vec4 v0x5c09d85790c0_0;
    %addi 1, 0, 4;
    %assign/vec4 v0x5c09d85790c0_0, 0;
T_1.0 ;
    %jmp T_1;
    .thread T_1;
    .scope S_0x5c09d8578330;
T_2 ;
    %wait E_0x5c09d8557ed0;
    %load/vec4 v0x5c09d8578cc0_0;
    %load/vec4 v0x5c09d8578a80_0;
    %nor/r;
    %and;
    %flag_set/vec4 8;
    %jmp/0xz  T_2.0, 8;
    %load/vec4 v0x5c09d8578d80_0;
    %pad/u 6;
    %ix/vec4 4;
    %load/vec4a v0x5c09d8578b40, 4;
    %assign/vec4 v0x5c09d85789a0_0, 0;
    %load/vec4 v0x5c09d8578d80_0;
    %addi 1, 0, 4;
    %assign/vec4 v0x5c09d8578d80_0, 0;
T_2.0 ;
    %jmp T_2;
    .thread T_2;
    .scope S_0x5c09d85573b0;
T_3 ;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v0x5c09d8579380_0, 0, 1;
T_3.0 ;
    %delay 5000, 0;
    %load/vec4 v0x5c09d8579380_0;
    %inv;
    %store/vec4 v0x5c09d8579380_0, 0, 1;
    %jmp T_3.0;
    %end;
    .thread T_3;
    .scope S_0x5c09d85573b0;
T_4 ;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v0x5c09d85798c0_0, 0, 1;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v0x5c09d8579990_0, 0, 1;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v0x5c09d8579750_0, 0, 1;
    %pushi/vec4 0, 0, 32;
    %store/vec4 v0x5c09d8579440_0, 0, 32;
    %pushi/vec4 0, 0, 32;
    %store/vec4 v0x5c09d8579b00_0, 0, 32;
    %pushi/vec4 0, 0, 32;
    %store/vec4 v0x5c09d8579820_0, 0, 32;
    %delay 100000, 0;
    %pushi/vec4 1, 0, 1;
    %store/vec4 v0x5c09d85798c0_0, 0, 1;
    %end;
    .thread T_4;
    .scope S_0x5c09d85573b0;
T_5 ;
T_5.0 ;
    %load/vec4 v0x5c09d85798c0_0;
    %pad/u 32;
    %pushi/vec4 1, 0, 32;
    %cmp/e;
    %flag_get/vec4 4;
    %cmpi/ne 1, 0, 1;
    %jmp/0xz T_5.1, 6;
    %wait E_0x5c09d855d9e0;
    %jmp T_5.0;
T_5.1 ;
    %pushi/vec4 2, 0, 32;
T_5.2 %dup/vec4;
    %pushi/vec4 0, 0, 32;
    %cmp/s;
    %jmp/1xz T_5.3, 5;
    %jmp/1 T_5.3, 4;
    %pushi/vec4 1, 0, 32;
    %sub;
    %fork t_1, S_0x5c09d8557590;
    %jmp t_0;
    .scope S_0x5c09d8557590;
t_1 ;
    %pushi/vec4 0, 0, 32;
    %store/vec4 v0x5c09d8540540_0, 0, 32;
T_5.4 ;
    %load/vec4 v0x5c09d8540540_0;
    %cmpi/s 30, 0, 32;
    %jmp/0xz T_5.5, 5;
    %wait E_0x5c09d8557ed0;
    %load/vec4 v0x5c09d8540540_0;
    %pushi/vec4 2, 0, 32;
    %mod/s;
    %cmpi/e 0, 0, 32;
    %jmp/0xz  T_5.6, 4;
    %load/vec4 v0x5c09d85796b0_0;
    %nor/r;
    %flag_set/vec4 8;
    %jmp/0xz  T_5.8, 8;
    %vpi_func 2 55 "$random" 32 {0 0 0};
    %store/vec4 v0x5c09d8579440_0, 0, 32;
    %load/vec4 v0x5c09d8579440_0;
    %ix/getv/s 4, v0x5c09d8579b00_0;
    %store/vec4a v0x5c09d8579a60, 4, 0;
    %load/vec4 v0x5c09d8579b00_0;
    %addi 1, 0, 32;
    %store/vec4 v0x5c09d8579b00_0, 0, 32;
    %pushi/vec4 1, 0, 1;
    %store/vec4 v0x5c09d8579990_0, 0, 1;
    %delay 5000, 0;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v0x5c09d8579990_0, 0, 1;
T_5.8 ;
T_5.6 ;
    %wait E_0x5c09d8557ca0;
    ; show_stmt_assign_vector: Get l-value for compressed += operand
    %load/vec4 v0x5c09d8540540_0;
    %pushi/vec4 1, 0, 32;
    %add;
    %store/vec4 v0x5c09d8540540_0, 0, 32;
    %jmp T_5.4;
T_5.5 ;
    %end;
    .scope S_0x5c09d85573b0;
t_0 %join;
    %delay 50000, 0;
    %jmp T_5.2;
T_5.3 ;
    %pop/vec4 1;
    %end;
    .thread T_5;
    .scope S_0x5c09d85573b0;
T_6 ;
T_6.0 ;
    %load/vec4 v0x5c09d85798c0_0;
    %pad/u 32;
    %pushi/vec4 1, 0, 32;
    %cmp/e;
    %flag_get/vec4 4;
    %cmpi/ne 1, 0, 1;
    %jmp/0xz T_6.1, 6;
    %wait E_0x5c09d855d9e0;
    %jmp T_6.0;
T_6.1 ;
    %pushi/vec4 10, 0, 32;
T_6.2 %dup/vec4;
    %pushi/vec4 0, 0, 32;
    %cmp/s;
    %jmp/1xz T_6.3, 5;
    %jmp/1 T_6.3, 4;
    %pushi/vec4 1, 0, 32;
    %sub;
    %wait E_0x5c09d8557ed0;
    %jmp T_6.2;
T_6.3 ;
    %pop/vec4 1;
    %pushi/vec4 2, 0, 32;
T_6.4 %dup/vec4;
    %pushi/vec4 0, 0, 32;
    %cmp/s;
    %jmp/1xz T_6.5, 5;
    %jmp/1 T_6.5, 4;
    %pushi/vec4 1, 0, 32;
    %sub;
    %fork t_3, S_0x5c09d85780f0;
    %jmp t_2;
    .scope S_0x5c09d85780f0;
t_3 ;
    %pushi/vec4 0, 0, 32;
    %store/vec4 v0x5c09d8542670_0, 0, 32;
T_6.6 ;
    %load/vec4 v0x5c09d8542670_0;
    %cmpi/s 30, 0, 32;
    %jmp/0xz T_6.7, 5;
    %wait E_0x5c09d8557ed0;
    %load/vec4 v0x5c09d8542670_0;
    %pushi/vec4 2, 0, 32;
    %mod/s;
    %cmpi/e 0, 0, 32;
    %jmp/0xz  T_6.8, 4;
    %load/vec4 v0x5c09d85795e0_0;
    %nor/r;
    %flag_set/vec4 8;
    %jmp/0xz  T_6.10, 8;
    %pushi/vec4 1, 0, 1;
    %store/vec4 v0x5c09d8579750_0, 0, 1;
    %delay 5000, 0;
    %pushi/vec4 0, 0, 1;
    %store/vec4 v0x5c09d8579750_0, 0, 1;
    %delay 1000, 0;
    %load/vec4 v0x5c09d85794e0_0;
    %ix/getv/s 4, v0x5c09d8579820_0;
    %load/vec4a v0x5c09d8579a60, 4;
    %cmp/ne;
    %jmp/0xz  T_6.12, 6;
    %vpi_call 2 83 "$display", "Time = %0t: Comparison Failed: expected %h, got %h", $time, &A<v0x5c09d8579a60, v0x5c09d8579820_0 >, v0x5c09d85794e0_0 {0 0 0};
    %jmp T_6.13;
T_6.12 ;
    %vpi_call 2 85 "$display", "Time = %0t: Comparison Passed: expected %h, got %h", $time, &A<v0x5c09d8579a60, v0x5c09d8579820_0 >, v0x5c09d85794e0_0 {0 0 0};
T_6.13 ;
    %load/vec4 v0x5c09d8579820_0;
    %addi 1, 0, 32;
    %store/vec4 v0x5c09d8579820_0, 0, 32;
T_6.10 ;
T_6.8 ;
    %wait E_0x5c09d8557ca0;
    ; show_stmt_assign_vector: Get l-value for compressed += operand
    %load/vec4 v0x5c09d8542670_0;
    %pushi/vec4 1, 0, 32;
    %add;
    %store/vec4 v0x5c09d8542670_0, 0, 32;
    %jmp T_6.6;
T_6.7 ;
    %end;
    .scope S_0x5c09d85573b0;
t_2 %join;
    %delay 50000, 0;
    %jmp T_6.4;
T_6.5 ;
    %pop/vec4 1;
    %vpi_call 2 94 "$finish" {0 0 0};
    %end;
    .thread T_6;
    .scope S_0x5c09d85573b0;
T_7 ;
    %vpi_call 2 99 "$dumpfile", "wave_fifo.vcd" {0 0 0};
    %vpi_call 2 100 "$dumpvars" {0 0 0};
    %end;
    .thread T_7;
# The file index is used to find the file name in the following table.
:file_names 4;
    "N/A";
    "<interactive>";
    "fifo_tb.v";
    "fifo.v";
