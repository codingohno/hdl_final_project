`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NTHU
// Engineer: Bob Cheng
//
// Create Date: 2019/08/25 12:47:53
// Module Name: top
// Project Name: Chip2Chip
// Additional Comments: top module for master, pass signals and perform debounce onepulse
//
//////////////////////////////////////////////////////////////////////////////////

module connection_master(clk, rst, data_inputs, request, notice_master, data_to_slave_o, valid, request2s, ack);
    input clk;
    input rst;
    input [5-1:0] data_inputs;//inputs from keyboard
    input request;//button for sending
    input ack;
    output [5-1:0] data_to_slave_o;
    output notice_master;
    output valid;
    output request2s;

    wire [3-1:0] data_to_slave;
    wire rst_n;
    wire [8-1:0]slave_data_dec;
    wire db_rst_n, op_rst_n;
	wire [8-1:0]data_to_slave_dec;
    assign rst_n = ~rst;

    master_control ms_ctrl_0(.clk(clk), .rst_n(rst_n), .request(request), .ack(ack), .data_in(data_inputs), .notice(notice_master), .data(data_to_slave_o), .valid(valid), .request2s(request2s));
endmodule

