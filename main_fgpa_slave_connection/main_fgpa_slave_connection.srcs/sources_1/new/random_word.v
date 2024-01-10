`timescale 1ns / 1ps

module random_word(
    input clk,
    input seed,
    output [5-1:0] chosen_letter_5,
    output [5-1:0] chosen_letter_4,
    output [5-1:0] chosen_letter_3,
    output [5-1:0] chosen_letter_2,
    output [5-1:0] chosen_letter_1,
    output [5-1:0] chosen_letter_0
    );

    reg [5-1:0] words [10:0][6-1:0];

    integer unsigned index;
    
    initial begin 
        index = $urandom_range(1, 0);
        words[0][5] = "D"; words[0][4] = "E"; words[0][3] = "S"; words[0][2] = "I"; words[0][1] = "G"; words[0][0] = "N";
        words[1][5] = "M"; words[1][4] = "A"; words[1][3] = "T"; words[1][2] = "U"; words[1][1] = "R"; words[1][0] = "E";
        /*words[2][5:0] = "EXTERN";
        words[3][5:0] = "REFINE";
        words[4][5:0] = "APPLES";
        words[5][5:0] = "BANANA";
        words[6][5:0] = "IMPURE";*/
    end

    assign chosen_letter_5 = words[index][5];
    assign chosen_letter_4 = words[index][4];
    assign chosen_letter_3 = words[index][3];
    assign chosen_letter_2 = words[index][2];
    assign chosen_letter_1 = words[index][1];
    assign chosen_letter_0 = words[index][0];


    
endmodule
