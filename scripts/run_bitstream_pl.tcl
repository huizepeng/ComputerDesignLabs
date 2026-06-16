set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $script_dir ..]]
set out_dir [file join $lab_dir vivado bitstream_check_pl]

file mkdir $out_dir

set src_dir [file join $lab_dir src]
set pl_dir [file join $lab_dir pl-src]

read_verilog [file join $pl_dir ctrl_encode_def.v]
read_verilog [file join $pl_dir alu.v]
read_verilog [file join $pl_dir ctrl.v]
read_verilog [file join $pl_dir dm_sort.v]
read_verilog [file join $pl_dir EXT.v]
read_verilog [file join $pl_dir im_sort.v]
read_verilog [file join $pl_dir NPC.v]
read_verilog [file join $pl_dir PC.v]
read_verilog [file join $pl_dir pl_reg.v]
read_verilog [file join $pl_dir PLCPU.v]
read_verilog [file join $pl_dir RF.v]
read_verilog [file join $pl_dir plcomp_sort.v]
read_verilog [file join $src_dir debounce.v]
read_verilog [file join $src_dir hex_to_7seg.v]
read_verilog [file join $src_dir scan_7seg.v]
read_verilog [file join $src_dir board_number_demo_pl.v]
read_xdc [file join $lab_dir constraints Nexys4DDR_SortDemo.xdc]

synth_design -top board_number_demo_pl -part xc7a100tcsg324-1
opt_design
place_design
route_design
write_bitstream -force [file join $out_dir board_number_demo_pl.bit]

puts "Generated bitstream: [file join $out_dir board_number_demo_pl.bit]"
exit 0
