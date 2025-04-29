# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work


# Compile design files
vlog -sv design.sv

# Compile all testbench files at once to resolve dependencies
vlog -sv include_files.sv testbench.sv

echo "Compilation completed"