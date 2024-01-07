`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NTHU
// Engineer: Bob Cheng
//
// Create Date: 2019/08/25 12:47:53
// Module Name: top
// Project Name: Chip2Chip
// Additional Comments: top module for master, pass signals and perform debounce onepulse
//////////////////////////////////////////////////////////////////////////////////



module onepulse_slave (pb_debounced, clock, pb_one_pulse);
	input pb_debounced;
	input clock;
	output reg pb_one_pulse;
	reg pb_debounced_delay;
	always @(posedge clock) begin
		pb_one_pulse <= pb_debounced & (! pb_debounced_delay);
		pb_debounced_delay <= pb_debounced;
	end
endmodule

module connection_slave(clk, rst_n, request, valid, notice_slave, data_in, ack,slave_data_o,new_incoming_data);
    input clk;
    input rst_n;
    input [5-1:0] data_in;//get the inputs from the second fgpa
    input request;
    input valid;
    output notice_slave;
    output ack;
    output [5-1:0]slave_data_o;
    output new_incoming_data;



    //implement new incoming data signal
    wire inv_valid;
    assign inv_valid=~valid;
    onepulse_slave op1 (inv_valid,clk,new_incoming_data);

    slave_control sl_ctrl_0(.clk(clk), .rst_n(rst_n), .request(request), .ack(ack), .data_in(data_in), .notice(notice_slave), .valid(valid), .data(slave_data_o));
endmodule




