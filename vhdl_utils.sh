#!/usr/bin/env bash

# Requires jq, gconftool-2 and vivado binaries to be in PATH

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

function get_project_other_files {
    local res=$(jq -r '.other_files[]' project.json)
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
        ghdl -e --std=08 --ieee=synopsys -O2 $1
    fi
}

# parameter: testbench entity to simulate
function simulate {
    if [ -z "$1" ]; then
        echo "usage: simulate <testbench enity> [--show]"
        return 1
    fi

    vhd_compile $1
    if [ $? -ne 0 ]; then
        echo "Simulation won't be run"
        return 1
    fi
    # run and dump vcd for visualization
    ghdl -r --std=08 --ieee=synopsys $1 --wave=$1.ghw

    if [ -n "$2" ] && [ "$2" = "--show" ]; then
        # do initial zoom automatically and disable initial splash screen
        if [ -z "$(pidof gtkwave)" ]; then
            nohup gtkwave $1.ghw --rcvar 'do_initial_zoom_fit yes' --rcvar 'splash_disable yes' > /dev/null 2>&1 &
        else
            gconftool-2 --type string --set /com.geda.gtkwave/0/reload 0
            echo "Reloading gtkwave"
        fi
    fi
}

function show_simulation {
    if [ -z "$1" ]; then
        if [ -n "$(pidof gtkwave)" ]; then
            gconftool-2 --type string --set /com.geda.gtkwave/0/reload 0
            echo "Reloading gtkwave"
        else
            echo "No instance of gtkwave running"
            echo "Usage: show_simulation [entity]"
        fi
    else
        nohup gtkwave $1.ghw --rcvar 'do_initial_zoom_fit yes' --rcvar 'splash_disable yes' > /dev/null 2>&1 &
    fi
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
    local other_files=$(get_project_other_files)
    rm -f vivado.log
    vivado -nojournal -log vivado.log -mode batch -source $SCRIPT_PATH/build_project.tcl -tclargs \
        -name $project_name -sources $sources -constraints $constraints -tests $tests -other_files $other_files
}

function open_vivado {
    check_project
    if [ $? -ne 0 ]; then
        return 1
    fi
    local name=$(get_project_name)
    nohup vivado -nolog -nojournal Vivado_$name/$name.xpr > /dev/null 2>&1 &
}

function program_device {
    check_project
    if [ $? -ne 0 ]; then
        return 1
    fi
    local name=$(get_project_name)
    vivado -nojournal -nolog -mode batch -source $SCRIPT_PATH/program_device.tcl -tclargs Vivado_$name/$name.xpr
}
