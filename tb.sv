/**
 * @author Qianfeng (Clark) Shen
 * @email qianfeng.shen@gmail.com
 * @create date 2023-08-22 11:02:11
 * @modify date 2023-08-22 11:02:11
 */

`timescale 1ps/1ps
`include "sim_sock.svh"
`define FREQ 200 //frequency = 200 MHz

module tb();
    logic clk, rst;
    logic [31:0] din0, din1;
    logic [31:0] dout;
    logic din_valid, dout_valid;

    initial begin
        rst = 1'b1;
        #100ns;
        @(posedge clk);
        rst = 1'b0;
        wait(dout_valid === 1'b1);
        #100ns;
        $finish;
    end

    socket_server_wrapper #(
        .DWIDTH_IN  (64),
        .DWIDTH_OUT (32)
    ) u_socket_server_wrapper(
        .*,
        .socket_dout       (dout       ),
        .socket_dout_valid (dout_valid ),
        .socket_din        ({din1,din0}),
        .socket_din_valid  (din_valid  )
    );

    simple_adder DUT(.*);

    initial begin
        clk = 1'b0;
        forever #(1us/`FREQ) clk = ~ clk;
    end
endmodule