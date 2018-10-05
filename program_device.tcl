if { $argc < 1 } {
    puts "Parameters: <project file>"
    exit
}

open_project [lindex $argv 0]

set project_name [get_property NAME [current_project]]
set bitstream_file [get_property DIRECTORY [get_runs impl_1]]/$project_name.bit

open_hw
connect_hw_server
open_hw_target
set_property PROGRAM.FILE $bitstream_file [get_hw_devices]
current_hw_device [get_hw_devices]
program_hw_devices [get_hw_devices]
