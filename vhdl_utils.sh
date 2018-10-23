#!/usr/bin/env bash

# Requires jq and vivado binaries to be in PATH

# optional parameter: entity to be elaborated with ghdl
# Save script path, because we need build_project.tcl that is inside the same directory
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function check_project {
    if [ ! -e 'project.json' ]; then
        echo "No project file detected."
        return 1
    fi
}

function get_project_name {
    local name=$(jq -r '.name' project.json)
    echo $name
}

function get_project_sources {
    local res=$(jq -r '.sources[]' project.json)
    echo $res
}

function get_project_tests {
    local res=$(jq -r '.tests[]' project.json)
    echo $res
}

function get_project_constraints {
    local res=$(jq -r '.constraints[]' project.json)
    echo $res
}

function vhd_compile {
    check_project
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    for file in $(get_project_sources) $(get_project_tests); do
        ghdl -a --std=08 --ieee=synopsys $file
    done
    if [ $? -ne 0 ]; then
        echo "Compilation failed"
        return 1
    fi
    if [ -n "$1" ]; then
        ghdl -e --std=08 --ieee=synopsys $1
    fi
}

# parameter: testbench entity to simulate
function simulate {
    if [ -z "$1" ]; then
        echo "usage: simulate <testbench enity>"
        return 1
    fi
    vhd_compile $1
    if [ $? -ne 0 ]; then
        echo "Simulation won't be run"
        return 1
    fi
    # run and dump vcd for visualization
    ghdl -r --std=08 --ieee=synopsys $1 --vcd=$1.vcd
    # do initial zoom automatically and disable initial splash screen
    nohup gtkwave $1.vcd --rcvar 'enable_vcd_autosave yes' --rcvar 'do_initial_zoom_fit yes' --rcvar 'splash_disable yes' > /dev/null 2>&1 &
}

function create_vivado_project {
    check_project
    if [ $? -ne 0 ]; then
        return 1
    fi
    local project_name=$(get_project_name)
    if [ -z "$project_name" ]; then
        echo "No project found in current folder: create a project.json file"
        return 1
    fi
    local sources=$(get_project_sources)
    local constraints=$(get_project_constraints)
    local tests=$(get_project_tests)
    rm -f vivado.log
    vivado -nojournal -log vivado.log -mode batch -source $SCRIPT_PATH/build_project.tcl -tclargs -name $project_name -sources $sources -constraints $constraints -tests $tests
}

function open_vivado {
    check_project
    if [ $? -ne 0 ]; then
        return 1
    fi
    local name=$(get_project_name)
    vivado -nolog -nojournal Vivado_$name/$name.xpr
}

function program_device {
    check_project
    if [ $? -ne 0 ]; then
        return 1
    fi
    local name=$(get_project_name)
    vivado -nojournal -nolog -mode batch -source $SCRIPT_PATH/program_device.tcl -tclargs Vivado_$name/$name.xpr
}
