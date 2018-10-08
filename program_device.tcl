if { $argc < 1 } {
    puts "Parameters: <project file>"
    exit
}

open_project [lindex $argv 0]
set bitstream_file [lindex [glob -dir [get_property DIRECTORY [get_runs impl_1]] *.bit] 0]


open_hw
connect_hw_server
open_hw_target
set_property PROGRAM.FILE $bitstream_file [get_hw_devices]
current_hw_device [get_hw_devices]
program_hw_devices [get_hw_devices]
