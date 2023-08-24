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
    int cnt;

    initial begin
        rst = 1'b1;
        #100ns;
        @(posedge clk);
        rst = 1'b0;
        wait(cnt == 3);
        #100ns;
        $finish;
    end

    always_ff @( posedge clk) begin
        if (rst)
            cnt <= 0;
        else if (dout_valid)
            cnt <= cnt + 1'b1;
    end

    socket_server_wrapper #(
        .DWIDTH_IN  (64),
        .DWIDTH_OUT (32)
    ) u_socket_server_wrapper(
        .*,
        .socket_dout       (dout       ),
        .socket_dout_valid (dout_valid ),
        .socket_din        ({din1,din0}),
        .socket_din_valid  (din_valid  ),
        .socket_din_ready  (1'b1       )
    );

    simple_adder DUT(.*);

    initial begin
        clk = 1'b0;
        forever #(1us/`FREQ) clk = ~ clk;
    end
endmodule
