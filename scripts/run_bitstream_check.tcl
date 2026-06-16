set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $script_dir ..]]
set out_dir [file join $lab_dir vivado bitstream_check]

file mkdir $out_dir

set src_dir [file join $lab_dir src]

read_verilog [file join $src_dir ctrl_encode_def.v]
read_verilog [file join $src_dir alu.v]
read_verilog [file join $src_dir ctrl.v]
read_verilog [file join $src_dir dm.v]
read_verilog [file join $src_dir EXT.v]
read_verilog [file join $src_dir im.v]
read_verilog [file join $src_dir NPC.v]
read_verilog [file join $src_dir PC.v]
read_verilog [file join $src_dir sccomp.v]
read_verilog [file join $src_dir SCCPU.v]
read_verilog [file join $src_dir RF.v]
read_verilog [file join $src_dir debounce.v]
read_verilog [file join $src_dir hex_to_7seg.v]
read_verilog [file join $src_dir scan_7seg.v]
read_verilog [file join $src_dir board_number_demo.v]
read_xdc [file join $lab_dir constraints Nexys4DDR_SortDemo.xdc]

synth_design -top board_number_demo -part xc7a100tcsg324-1
opt_design
place_design
route_design
write_bitstream -force [file join $out_dir board_number_demo.bit]

puts "Generated bitstream: [file join $out_dir board_number_demo.bit]"
exit 0
