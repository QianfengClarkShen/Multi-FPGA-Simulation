/**
 * @author Qianfeng (Clark) Shen
 * @email qianfeng.shen@gmail.com
 * @create date 2023-08-22 11:01:14
 * @modify date 2023-08-22 11:01:14
 */

`timescale 1ps/1ps

module simple_adder (
    input logic clk,
    input logic rst,
    input logic [31:0] din0,
    input logic [31:0] din1,
    input logic din_valid,
    output logic [31:0] dout,
    output logic dout_valid
);
    always_ff @(posedge clk) begin
        if (rst) begin
            dout <= 32'b0;
            dout_valid <= 1'b0;
        end
        else begin
            dout <= din0 + din1;
            dout_valid <= din_valid;
        end
    end

endmodule