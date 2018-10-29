if { $argc < 2 } {
    puts "Parameters: -name <project_name> -sources <sources..> -constraints <constraints..> -tests <tests..> -other_files <other files..>"
    exit
}

set projectName ""
set sources {}
set tests {}
set constraints {}
set other_files {}

# 0: name, 1: sources, 2: constraints, 3: tests, 4: other files
set state -1
foreach arg $argv {
    if { $arg eq "-name" } then {
        set state 0
    } elseif { $arg eq "-sources" } then {
        set state 1
    } elseif { $arg eq "-constraints" } then {
        set state 2
    } elseif { $arg eq "-tests" } then {
        set state 3
    } elseif { $arg eq "-other_files" } then {
        set state 4
    } else {
        switch $state {
            0 {
                set projectName $arg
            }
            1 {
                lappend sources $arg
            }
            2 {
                lappend constraints $arg
            }
            3 {
                lappend tests $arg
            }
            4 {
                lappend other_files $arg
            }
        }
    }
}

set outputDir ./Vivado_${projectName}
file mkdir ${outputDir}
create_project ${projectName} ${outputDir} -part xc7a100tcsg324-1 -force

set_property TARGET_LANGUAGE "VHDL" [current_project]

add_files $sources
if { [llength $constraints] != 0 } then {
    add_files -fileset constrs_1 $constraints
}
if { [llength $tests] != 0 } then {
    add_files -fileset sim_1 $tests
}

set_property file_type {VHDL 2008} [get_files -of_objects [current_fileset]]
set_property file_type {VHDL 2008} [get_files -of_objects [get_filesets sim_1]]
if { [llength $other_files] != 0 } then {
    add_files -fileset [current_fileset] $other_files
}
import_files -force -norecurse

update_compile_order -fileset [current_fileset]
update_compile_order -fileset sim_1

launch_runs synth_1
wait_on_run synth_1

#set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
#set_property STEPS.OPT_DESIGN.TCL.PRE [pwd]/pre_opt_design.tcl [get_runs impl_1]
#set_property STEPS.OPT_DESIGN.TCL.POST [pwd]/post_opt_design.tcl [get_runs impl_1]
#set_property STEPS.PLACE_DESIGN.TCL.POST [pwd]/post_place_design.tcl [get_runs impl_1]
#set_property STEPS.PHYS_OPT_DESIGN.TCL.POST [pwd]/post_phys_opt_design.tcl [get_runs impl_1]
#set_property STEPS.ROUTE_DESIGN.TCL.POST [pwd]/post_route_design.tcl [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

