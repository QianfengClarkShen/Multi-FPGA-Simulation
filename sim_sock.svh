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
    parameter int DWIDTH_IN = 32,
    parameter int DWIDTH_OUT = 32
) (
    input logic clk,
    input logic rst,
//control
    input logic socket_nb_condition,
    input logic socket_stop,
    input logic [31:0] socket_nb_timeout,
//data
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

    logic socket_block;
    logic [31:0] socket_block_cnt;

    initial begin
        //sim_init(ip_addr, port, type) type 0 = tcp server, type 1 = tcp client
        channel = sim_init(IP_ADDR,PORT,0);
        if (channel == null) begin
            $error("Error: socket init failed");
            $finish;
        end
        forever begin
            @(posedge clk);
            if (socket_stop === 1'b1)
                continue;
            if (rst)
                continue;
            if (sim_keep_alive(channel)) begin
                $error("Error: cannot keep the socket alive");
                $finish;
            end
            if (socket_din_ready) begin
                if (!socket_block)
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
            if (rdy_return > 0)
                in_return = sim_read(channel, in_buf, DIN_RDUP/8);
            else
                in_return = 0;
            if (in_return < 0 || out_return < 0) begin
                $error("Error: socket error detected");
                $finish;
            end
        end
    end
    final begin
        sim_close(channel);
    end

    always_ff @(posedge clk) begin
        if (rst)
            socket_block_cnt <= 32'b0;
        else if (socket_nb_condition)
            socket_block_cnt <= 32'b0;
        else if (socket_block_cnt != socket_nb_timeout)
            socket_block_cnt <= socket_block_cnt + 1'b1;
    end
    assign socket_block = socket_block_cnt == socket_nb_timeout && !socket_nb_condition;

    always_ff @(posedge clk) begin : input_block
        if (rst === 1'b1 || channel == null) begin
            din_int <= {DIN_RDUP{1'b0}};
            socket_din_valid <= 1'b0;
        end
        else begin
            if (in_return == DIN_RDUP/8)
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
    assign dout_int = socket_dout[DWIDTH_OUT-1:0];
endmodule