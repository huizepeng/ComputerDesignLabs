set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $script_dir ..]]
set project_dir [file join $lab_dir vivado sort_demo]

file mkdir $project_dir

create_project sort_demo $project_dir -part xc7a100tcsg324-1 -force

set board_name "digilentinc.com:nexys4_ddr:part0:1.1"
if {[llength [get_board_parts -quiet $board_name]] > 0} {
    set_property board_part $board_name [current_project]
} else {
    puts "Board part $board_name is not installed; using device part xc7a100tcsg324-1 only."
}

set src_dir [file join $lab_dir src]
add_files [file join $src_dir ctrl_encode_def.v]
add_files [file join $src_dir alu.v]
add_files [file join $src_dir ctrl.v]
add_files [file join $src_dir dm.v]
add_files [file join $src_dir EXT.v]
add_files [file join $src_dir im.v]
add_files [file join $src_dir NPC.v]
add_files [file join $src_dir PC.v]
add_files [file join $src_dir sccomp.v]
add_files [file join $src_dir SCCPU.v]
add_files [file join $src_dir RF.v]
add_files [file join $src_dir debounce.v]
add_files [file join $src_dir hex_to_7seg.v]
add_files [file join $src_dir scan_7seg.v]
add_files [file join $src_dir board_number_demo.v]
add_files -fileset constrs_1 [file join $lab_dir constraints Nexys4DDR_SortDemo.xdc]
add_files -fileset sim_1 [file join $src_dir rv32_sid_sort_sim.dat]

set_property top board_number_demo [current_fileset]
update_compile_order -fileset sources_1

puts "Created Vivado project: $project_dir"
