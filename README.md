## description:
This project provides a simple TCP socket interface in SystemVerilog to exchange data with external softwares during simulation. This is useful in system-level functional simulation, especially when the system uses multiple FPGAs. Each FPGA can be simulated by a seperate process on the same (or a different) machine.

## directory structure:

 ┣ Makefile     - main make file

 ┣ README.txt   - this file

 ┣ client.py    - a python script use to feed data into the hardware in simulation

 ┣ dut.sv       - design under test, a simple 32-bit adder

 ┣ tb.sv        - testbench

 ┣ sim_sock.svh - SystemVerilog tcp socket wrapper

 ┣ sim_sock.cpp - c++ library file that provides the tcp socket APIs

 ┗ sim.tcl      - Vivado tcl script for simulation

## prerequisites:
1. GNU make
2. Vivado System Suite >= 2017.2
3. Python >= 3.6

## how to run the demo project:
**with GUI****: run `make sim_gui`, then `python3 client.py`

**without GUI**: run `make sim`, then `python3 client.py`