`timescale 1ns / 1ps

module pixel_gen(
  input [9:0] h_cnt, // FROM VGA CONTROLLER
  input [9:0] v_cnt,  // FROM VGA CONTROLLER
  input valid, // FROM VGA CONTROLLER
  input [4:0] row, // from the 
  input [6:0] col,
  input [4:0] val, //this is the keyboard bits maybe need to make 5?
  output reg flag
);
// (col)h640(x) x (row)v480(y) -> 80 x 30 (8x16) [size of letters]
wire [5:0] cell_row = v_cnt[9:4]; //character cell
wire [6:0] cell_col = h_cnt[9:3];
wire [3:0] pixel_row = v_cnt[3:0]; 
wire [2:0] pixel_col = h_cnt[2:0];
wire [6:0] ascii;

wire [0:7] char_data;

assign ascii = val + 7'd64; //ADDED

wire show = cell_row == row && cell_col == col;

ascii_rom rom(.addr({ascii, pixel_row}), .data(char_data));

always @(*) begin
  if(!valid)
    //{vgaRed, vgaGreen, vgaBlue} = 12'h0;
    flag = 0;
  else
    //{vgaRed, vgaGreen, vgaBlue} = (show && char_data[pixel_col]) ? 12'hFFF : 12'h0;
    flag = (show && char_data[pixel_col]);
end

endmodule