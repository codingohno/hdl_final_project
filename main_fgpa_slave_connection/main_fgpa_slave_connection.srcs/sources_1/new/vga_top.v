`timescale 1ns / 1ps

module VGA_top(clk, rst, keyboard, vgaRed, vgaBlue, vgaGreen, hsync, vsync);
	input clk, rst;
    input [4:0] keyboard; //for the keyboard input

    output reg [3:0] vgaRed, vgaGreen, vgaBlue;
    output hsync, vsync;
	
	wire clk_d2;//25MHz
    wire clk_d22;
	wire [11:0] data;

    wire [9:0] h_cnt, v_cnt;
	wire [9:0] A_v_count, B_v_count, C_v_count;
    
	//signals
    wire flag_1, flag_2, flag_3, flag_4, flag_5, flag_6;
    wire valid;
	
    always @(*) begin
    if(!valid)
        {vgaRed, vgaGreen, vgaBlue} =  12'hFFF; // JERRY
    else
        {vgaRed, vgaGreen, vgaBlue} = (flag_1|flag_2|flag_3|flag_4|flag_5|flag_6) ? 12'hFFF :  12'h00F;
    end
	//assign {vgaRed, vgaGreen, vgaBlue} = (flag_1|flag_2|flag_3|flag_4|flag_5|flag_6) ? 12'hFFF : 12'h0;

    localparam [4:0] row = 10;
    localparam [6:0] col = 29;
	
	//clock
	clk_div #(2) CD0(.clk(clk), .clk_d(clk_d2));
	clk_div #(19) CD1(.clk(clk), .clk_d(clk_d22));

    // LETTER GENERATOR
	//control
    pixel_gen letter1(
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt),
        .valid(valid),
        .row(row), // need to do this
        .col(col), // need to tdo this for the hangman display
        .val(keyboard),
        .flag(flag_1)
    );

    //control
    pixel_gen letter2(
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt),
        .valid(valid),
        .row(row), // need to do this
        .col(col+1), // need to tdo this for the hangman display
        .val(keyboard),
        .flag(flag_2)
    );

    //control
    pixel_gen letter3(
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt),
        .valid(valid),
        .row(row), // need to do this
        .col(col+2), // need to tdo this for the hangman display
        .val(keyboard),
        .flag(flag_3)
    );

    //control
    pixel_gen letter4(
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt),
        .valid(valid),
        .row(row), // need to do this
        .col(col+3), // need to tdo this for the hangman display
        .val(keyboard),
        .flag(flag_4)
    );

    //control
    pixel_gen letter5(
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt),
        .valid(valid),
        .row(row), // need to do this
        .col(col+4), // need to tdo this for the hangman display
        .val(keyboard),
        .flag(flag_5)
    );

    //control
    pixel_gen letter6(
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt),
        .valid(valid),
        .row(row), // need to do this
        .col(col+5), // need to tdo this for the hangman display
        .val(keyboard),
        .flag(flag_6)
    );

    vga_controller VC0(
        .pclk(clk_d2),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );
	
endmodule

// DO NOT MODIFY THE FOLLOWING MODULE
module vga_controller(pclk, reset, hsync, vsync, valid, h_cnt, v_cnt);
    input pclk, reset;
    output hsync, vsync;
	output valid;
    output [9:0]h_cnt, v_cnt;
    
    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;
	wire hsync_default, vsync_default;
    wire [9:0] HD, HF, HS, HB, HT, VD, VF, VS, VB, VT;
	
	//WHAT ARE THESE????
    assign HD = 640;
    assign HF = 16;
    assign HS = 96;
    assign HB = 48;
    assign HT = 800; 
    assign VD = 480;
    assign VF = 10;
    assign VS = 2;
    assign VB = 33;
    assign VT = 525;
    assign hsync_default = 1'b1;
    assign vsync_default = 1'b1;
     
    always@(posedge pclk)
        if(reset)
            pixel_cnt <= 0;
        else if(pixel_cnt < (HT - 1))
			pixel_cnt <= pixel_cnt + 1;
		else
			pixel_cnt <= 0;

    always@(posedge pclk)
        if(reset)
            hsync_i <= hsync_default;
        else if((pixel_cnt >= (HD + HF - 1))&&(pixel_cnt < (HD + HF + HS - 1)))
			hsync_i <= ~hsync_default;
		else
			hsync_i <= hsync_default; 
    
    always@(posedge pclk)
        if(reset)
            line_cnt <= 0;
        else if(pixel_cnt == (HT -1))
			if(line_cnt < (VT - 1))
				line_cnt <= line_cnt + 1;
			else
				line_cnt <= 0;
                  
				  
    always@(posedge pclk)
        if(reset)
            vsync_i <= vsync_default; 
        else if((line_cnt >= (VD + VF - 1))&&(line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default;
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));
	
    assign h_cnt = (pixel_cnt < HD)? pixel_cnt : 10'd0;//639
    assign v_cnt = (line_cnt < VD)? line_cnt : 10'd0;//479
	
endmodule


module clk_div #(parameter n = 2)(clk, clk_d);
	input clk;
	output clk_d;
	reg [n-1:0]count;
	wire[n-1:0]next_count;
	
	always@(posedge clk)begin
		count <= next_count;
	end
	
	assign next_count = count + 1;
	assign clk_d = count[n-1];
endmodule