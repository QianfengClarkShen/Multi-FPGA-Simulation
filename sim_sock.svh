/**
 * @author Qianfeng (Clark) Shen
 * @email qianfeng.shen@gmail.com
 * @create date 2023-08-22 10:56:15
 * @modify date 2023-08-22 10:56:15
 * @desc
 * This systemverilog header provides APIs for software programs and systemverilog testbenches
 * to exchange data using TCP socket in simulation.
 */

`define MAX_BUF_DEPTH 1024
/*
* C functions
*/
import "DPI-C" function chandle sim_init(int ip_addr, int port, int t);

import "DPI-C" function void sim_close(chandle h);

import "DPI-C" function int sim_keep_alive(chandle h);

import "DPI-C" function int sim_write(input chandle h, input byte ptr[`MAX_BUF_DEPTH-1:0], input int bytes);

import "DPI-C" function int sim_data_ready(chandle h);

import "DPI-C" function int sim_read(input chandle h, output byte ptr[`MAX_BUF_DEPTH-1:0], input int bytes);

import "DPI-C" function void sim_sleep(int seconds);

import "DPI-C" function void sim_usleep(int useconds);

/*
* main wrapper function
*/

module socket_server_wrapper # (
    parameter int IP_ADDR = 32'h0100007f,
    parameter int PORT = 15000,
    parameter int PAUSE_TIMEOUT_CYCLE = 1000,
    parameter int DWIDTH_IN = 32,
    parameter int DWIDTH_OUT = 32
) (
    input logic clk,
    input logic rst,
    input logic [DWIDTH_OUT-1:0] socket_dout,
    input logic socket_dout_valid,
    output logic [DWIDTH_IN-1:0] socket_din,
    output logic socket_din_valid,
    input logic socket_din_ready
);
    localparam int DOUT_RDUP = (DWIDTH_OUT-1)/8*8+8;
    localparam int DIN_RDUP = (DWIDTH_IN-1)/8*8+8;

    chandle channel;

    int rdy_return = 0, in_return = 0, out_return = 0;
    byte in_buf[1023:0];
    byte out_buf[1023:0];

    logic [DIN_RDUP-1:0] din_int;
    logic [DOUT_RDUP-1:0] dout_int;

    logic pause;
    int timeout_cnt;

    initial begin
        //sim_init(ip_addr, port, type) type 0 = tcp server, type 1 = tcp client
        channel = sim_init(IP_ADDR,PORT,0);
        if (channel == null) begin
            $error("Error: socket init failed");
            $finish;
        end
        timeout_cnt = 0;
        forever begin
            @(posedge clk);
            if (rst) begin
                timeout_cnt = 0;
                continue;
            end
            if (sim_keep_alive(channel)) begin
                $error("Error: cannot keep the socket alive");
                $finish;
            end
            if (socket_din_ready) begin
                if (!pause)
                    rdy_return = sim_data_ready(channel);
                else begin
                    for (;;) begin
                        rdy_return = sim_data_ready(channel);
                        if (rdy_return > 0)
                            break;
                        sim_usleep(1000);
                    end
                end
            end
            else
                rdy_return = 0;
            if (rdy_return > 0) begin
                timeout_cnt = 0;
                in_return = sim_read(channel, in_buf, DIN_RDUP/8);
            end
            else begin
                if (timeout_cnt != PAUSE_TIMEOUT_CYCLE)
                    timeout_cnt = timeout_cnt + 1;
                in_return = 0;
            end
            if (in_return < 0 || out_return < 0) begin
                $error("Error: socket error detected");
                $finish;
            end
        end
    end
    final begin
        sim_close(channel);
    end

    always_ff @(posedge clk) begin : input_block
        if (rst === 1'b1 || channel == null) begin
            din_int <= {DIN_RDUP{1'b0}};
            socket_din_valid <= 1'b0;
        end
        else begin
            din_int <= {>>{in_buf[DIN_RDUP/8-1:0]}};
            socket_din_valid <= in_return == DIN_RDUP/8;
        end
    end
    assign socket_din = din_int[DWIDTH_IN-1:0];

    always_ff @(posedge clk) begin : output_block
        if (rst !== 1'b1 && channel != null) begin
            if (socket_dout_valid === 1'b1) begin
                out_buf[DOUT_RDUP/8-1:0] = {>>{dout_int}};
                out_return = sim_write(channel, out_buf, DOUT_RDUP/8);
            end
        end
    end

    assign pause = timeout_cnt == PAUSE_TIMEOUT_CYCLE;
    assign dout_int = socket_dout[DWIDTH_OUT-1:0];
endmodule