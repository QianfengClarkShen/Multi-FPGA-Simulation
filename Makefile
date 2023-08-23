# @author Qianfeng (Clark) Shen \
  @email qianfeng.shen@gmail.com \
  @create date 2023-08-22 11:01:21 \
  @modify date 2023-08-22 11:01:21

all: sim_gui

dpi.so: xsim.dir/work/xsc/dpi.so
compile: xsim.dir/work/work.rlx
elaborate: xsim.dir/work.tb/xsimk
sim: dpi.so compile
	xelab work.tb -sv_lib dpi --debug all -R
sim_gui: dpi.so compile elaborate sim.tcl
	xsim work.tb -gui -tclbatch sim.tcl

xsim.dir/work/xsc/dpi.so: sim_sock.cpp
	xsc --cppversion 14 sim_sock.cpp
xsim.dir/work/work.rlx: tb.sv dut.sv sim_sock.svh
	xvlog --nolog --sv tb.sv dut.sv
xsim.dir/work.tb/xsimk: dpi.so compile
	xelab work.tb -sv_lib dpi --debug all

clean:
	@git clean -dfX