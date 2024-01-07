`timescale 1ns / 1ps
//pending
// inputs from fpga:clk,rst,_5,_10,_50,cancel
//debounce the inputs probably one pulsing
//reset might be wrong
//reset not yet debounced


//the initiator of the connection
module second_fpga_and_keyboard(
    output wire [6:0] display,
    output wire [3:0] digit,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire unde_rst,
    input wire clk,

    //added
    output notice_master,
    output [5-1:0] data_to_slave_o,
    output valid,
    output request2s,
    input ack
    );

    //creating rst and rst_n signal
    wire unone_rst,rst;
    debounce db0(unone_rst,unde_rst,clk);
    OnePulse op0(rst,unone_rst,clk);
    wire rst_n;
    assign rst_n=~rst;

    //the protocol of each keys to the enums 
    //26 of them 
      parameter KEY_CODES_Q = 9'h15;
      parameter KEY_CODES_W = 9'h1D;
      parameter KEY_CODES_E = 9'h24;
      parameter KEY_CODES_R = 9'h2D;
      parameter KEY_CODES_T = 9'h2C;
      parameter KEY_CODES_Y = 9'h35;
      parameter KEY_CODES_U = 9'h3C;
      parameter KEY_CODES_I = 9'h43;
      parameter KEY_CODES_O = 9'h44;
      parameter KEY_CODES_P = 9'h4D;
      parameter KEY_CODES_A = 9'h1C;
      parameter KEY_CODES_S = 9'h1B; 
      parameter KEY_CODES_D = 9'h23; 
      parameter KEY_CODES_F = 9'h2B;
      parameter KEY_CODES_G = 9'h34;
      parameter KEY_CODES_H = 9'h33;
      parameter KEY_CODES_J = 9'h3B;
      parameter KEY_CODES_K = 9'h42;
      parameter KEY_CODES_L = 9'h4B;
      parameter KEY_CODES_Z = 9'h1A;
      parameter KEY_CODES_X = 9'h22;
      parameter KEY_CODES_C = 9'h21;
      parameter KEY_CODES_V = 9'h2A;
      parameter KEY_CODES_B = 9'h32;
      parameter KEY_CODES_N = 9'h31;
      parameter KEY_CODES_M = 9'h3A;

    //character codes for inter fgpa transfer
      parameter CHAR_CODES_Q=5'd0;
      parameter CHAR_CODES_W=5'd1;
      parameter CHAR_CODES_E=5'd2;
      parameter CHAR_CODES_R=5'd3;
      parameter CHAR_CODES_T=5'd4;
      parameter CHAR_CODES_Y=5'd5;
      parameter CHAR_CODES_U=5'd6;
      parameter CHAR_CODES_I=5'd7;
      parameter CHAR_CODES_O=5'd8;
      parameter CHAR_CODES_P=5'd9;
      parameter CHAR_CODES_A=5'd10;
      parameter CHAR_CODES_S=5'd11;
      parameter CHAR_CODES_D=5'd12;
      parameter CHAR_CODES_F=5'd13;
      parameter CHAR_CODES_G=5'd14;
      parameter CHAR_CODES_H=5'd15;
      parameter CHAR_CODES_J=5'd16;
      parameter CHAR_CODES_K=5'd17;
      parameter CHAR_CODES_L=5'd18;
      parameter CHAR_CODES_Z=5'd19;
      parameter CHAR_CODES_X=5'd20;
      parameter CHAR_CODES_C=5'd21;
      parameter CHAR_CODES_V=5'd22;
      parameter CHAR_CODES_B=5'd23;
      parameter CHAR_CODES_N=5'd24;
      parameter CHAR_CODES_M=5'd25;

    //the char_code sending data
    reg [5-1:0] char_code;
    reg [5-1:0] next_send_char;
    reg [5-1:0] char_to_send;
    
    //from keyboard decorder
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;

    //the button for sending the data to the slave
    reg trigger_send,next_trigger_send;
    
    
    //needs to modified
    reg[16-1:0] nums;
    SevenSegment seven_seg (
        .display(display),
        .digit(digit),
        .nums(nums),
        .rst(rst),
        .clk(clk)
    );
      
    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );



    //////////////////////////////////////////////////////////////////////////////////keyboard interface//////////////////////////////////////////////////////////////////////////////////
      //test block for showing the char_to_send in decimal
      reg temp1;
      always@(*)begin
          //first two digits is always 0
          nums[15:8]=8'd0;

          //the tenths
          nums[7:4]=(char_to_send>=5'd30)?4'd3:(char_to_send>=5'd20)?4'd2:(char_to_send>=5'd10)?4'd1:4'd0;

          //the ones
          {temp1,nums[3:0]}=(char_to_send>=5'd30)?char_to_send-5'd30:
                            (char_to_send>=5'd20)?char_to_send-5'd20:
                            (char_to_send>=5'd10)?char_to_send-5'd10:
                            char_to_send;
      end



      //send_char & trigger_send sequential update
      //description:
      // the next_send_char is determined first because at posedge it changes to the next data
      // but the trigger only take effect on the next posedge of the clk
      always@(posedge clk)begin
          if(rst)begin
              char_to_send<=5'd0;
              trigger_send<=1'b0;
          end
          else begin
              char_to_send<=next_send_char;
              trigger_send<=next_trigger_send;
          end
      end

      //we need a state to record finite state machine for the keyboard
      //slave next_send generator
      always @ (*) begin
        next_send_char=char_to_send;
          if ((been_ready && key_down[last_change]) == 1'b1) begin/*a keydown detected*/
              next_send_char=char_code;
          end
          else begin
              next_send_char=char_to_send;
          end
      end
      
      //last state-->char codes
      //translate the last change to my alphabert encoding(a state-like variable)
      //if we need to detect event we need to combine it with the been ready
      //note that all the unspecified keys will become the default
      always @ (*) begin
          case (last_change)
              KEY_CODES_Q:char_code = CHAR_CODES_Q;
              KEY_CODES_E:char_code = CHAR_CODES_E;
              KEY_CODES_R:char_code = CHAR_CODES_R;
              KEY_CODES_W:char_code = CHAR_CODES_W;
              KEY_CODES_T:char_code = CHAR_CODES_T;
              KEY_CODES_Y:char_code = CHAR_CODES_Y;
              KEY_CODES_U:char_code = CHAR_CODES_U;
              KEY_CODES_I:char_code = CHAR_CODES_I;
              KEY_CODES_O:char_code = CHAR_CODES_O;
              KEY_CODES_P:char_code = CHAR_CODES_P;

              KEY_CODES_A:char_code = CHAR_CODES_A;
              KEY_CODES_S:char_code = CHAR_CODES_S;
              KEY_CODES_D:char_code = CHAR_CODES_D;
              KEY_CODES_F:char_code = CHAR_CODES_F;
              KEY_CODES_G:char_code = CHAR_CODES_G;
              KEY_CODES_H:char_code = CHAR_CODES_H;
              KEY_CODES_J:char_code = CHAR_CODES_J;
              KEY_CODES_K:char_code = CHAR_CODES_K;
              KEY_CODES_L:char_code = CHAR_CODES_L;

              KEY_CODES_Z:char_code = CHAR_CODES_Z;
              KEY_CODES_X:char_code = CHAR_CODES_X;
              KEY_CODES_C:char_code = CHAR_CODES_C;
              KEY_CODES_V:char_code = CHAR_CODES_V;
              KEY_CODES_B:char_code = CHAR_CODES_B;
              KEY_CODES_N:char_code = CHAR_CODES_N;
              KEY_CODES_M:char_code = CHAR_CODES_M;
              default: char_code = 5'd31;//ANY OTHER KEY BECOMES THIS ERROR CHAR CODE
          endcase
      end


    //////////////////////////////////////////////////////////////////////////////////connection interface//////////////////////////////////////////////////////////////////////////////////
    //we need a trigger for sending the data

    //finding that we are not holding the key
    wire new_press_signal;
    new_press new_press_detector(new_press_signal,clk,key_down,last_change,been_ready,rst);
    always @ (*) begin
     next_trigger_send=trigger_send;
        //not sure which is better
        //if ((been_ready && (key_down[last_change]==1'b1) && (new_press_signal== 1'b1)) == 1'b1) begin
        if ((been_ready && (key_down[last_change]==1'b1) && (new_press_signal== 1'b1)) == 1'b1) begin/*a keydown detected and send once only*/
            next_trigger_send=1'b1;
        end
        else begin
            next_trigger_send=1'b0;
        end
    end

    connection_master  master_connection_interface(.clk(clk), .rst(rst), .data_inputs(char_to_send), .request(trigger_send), .notice_master(notice_master), .data_to_slave_o(data_to_slave_o), .valid(valid), .request2s(request2s), .ack(ack));
endmodule

module new_press(new_press_signal,clk,key_down,last_change,been_ready,rst);
  output new_press_signal;
  input [8:0] last_change;
  input [511:0] key_down;
  input clk;
  input rst;
  input been_ready;

  wire been_ready_op;
  OnePulse op0(been_ready_op,been_ready,clk);

  //no buffer
  reg [511:0] prev_key_down;

  always@(posedge clk)begin
      if(been_ready_op)begin
          prev_key_down<=key_down;
      end
  end

  assign new_press_signal=((prev_key_down[last_change]==1'b0)&&(key_down[last_change]==1'b1));
endmodule

module SevenSegment(
    output reg [6:0] display,//the led signal corresponding to AN
    output reg [3:0] digit,//the AN
    input wire [15:0] nums,//concate all the numbers to do numbers to show in each digital display
    input wire rst,
    input wire clk
    );

    
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            clk_divider <= 16'b0;
        end else begin
            clk_divider <= clk_divider + 16'b1;
        end
    end
    
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            display_num <= 4'b0000;
            digit <= 4'b1111;
        end else if (clk_divider == {16{1'b1}}) begin
            case (digit)
                4'b1110 : begin
                    display_num <= nums[7:4];
                    digit <= 4'b1101;
                end
                4'b1101 : begin
                    display_num <= nums[11:8];
                    digit <= 4'b1011;
                end
                4'b1011 : begin
                    display_num <= nums[15:12];
                    digit <= 4'b0111;
                end
                4'b0111 : begin
                    display_num <= nums[3:0];
                    digit <= 4'b1110;
                end
                default : begin
                    display_num <= nums[3:0];
                    digit <= 4'b1110;
                end				
            endcase
        end else begin
            display_num <= display_num;
            digit <= digit;
        end
    end
    
    always @ (*) begin
        case (display_num)
            //g......a
            0 : display = 7'b1000000;	//0000
            1 : display = 7'b1111001;   //0001                                                
            2 : display = 7'b0100100;   //0010                                                
            3 : display = 7'b0110000;   //0011                                             
            4 : display = 7'b0011001;   //0100                                               
            5 : display = 7'b0010010;   //0101                                               
            6 : display = 7'b0000010;   //0110
            7 : display = 7'b1111000;   //0111
            8 : display = 7'b0000000;   //1000
            9 : display = 7'b0010000;	//1001
            default : display = 7'b1111111;
        endcase
    end
endmodule


module clk_divider(count_for_100_megahz, clk, div_clk,rst_n);
    input[27-1:0] count_for_100_megahz;
    input clk;
    input rst_n;
    output reg div_clk;

    reg[27-1:0] count=27'b0;
    always@(posedge clk)begin
        if(rst_n===1'b0)begin
            count<=27'b0;
            div_clk<=1'b0;
        end
        else begin
            if(count>=count_for_100_megahz)begin
                count<=27'b0;
                div_clk<=1'b1;
            end
            else begin
                count<=count+27'b1;
                div_clk<=1'b0;
            end
        end
    end
endmodule


module Ps2Interface#(
    parameter SYSCLK_FREQUENCY_HZ = 100000000
  )(
  ps2_clk,
  ps2_data,

  clk,
  rst,

  tx_data,
  tx_valid,

  rx_data,
  rx_valid,

  busy,
  err
);
  inout ps2_clk, ps2_data;
  input clk, rst;
  input [7:0] tx_data;
  input tx_valid;
  output reg [7:0] rx_data;
  output reg rx_valid;
  output busy;
  output reg err;
  
  parameter CLOCK_CNT_100US = (100*1000) / (1000000000/SYSCLK_FREQUENCY_HZ);
  parameter CLOCK_CNT_20US = (20*1000) / (1000000000/SYSCLK_FREQUENCY_HZ);
  parameter DEBOUNCE_DELAY = 15;
  parameter BITS_NUM = 11;
  
  parameter [0:255] parity_table = {    //(odd) parity bit table, used instead of logic because this way speed is far greater
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,
    1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1
  };
  
  parameter IDLE                        = 4'd0;
  parameter RX_NEG_EDGE                 = 4'd1;
  parameter RX_CLK_LOW                  = 4'd2;
  parameter RX_CLK_HIGH                 = 4'd3;
  parameter TX_FORCE_CLK_LOW            = 4'd4;
  parameter TX_BRING_DATA_LOW           = 4'd5;
  parameter TX_RELEASE_CLK              = 4'd6;
  parameter TX_WAIT_FIRTS_NEG_EDGE      = 4'd7;
  parameter TX_CLK_LOW                  = 4'd8;
  parameter TX_WAIT_POS_EDGE            = 4'd9;
  parameter TX_CLK_HIGH                 = 4'd10;
  parameter TX_WAIT_POS_EDGE_BEFORE_ACK = 4'd11;
  parameter TX_WAIT_ACK                 = 4'd12;
  parameter TX_RECEIVED_ACK             = 4'd13;
  parameter TX_ERROR_NO_ACK             = 4'd14;
  
  
  reg [10:0] frame;
  wire rx_parity;
  
  wire ps2_clk_in, ps2_data_in;
  reg clk_inter, ps2_clk_s, data_inter, ps2_data_s;
  reg [3:0] clk_count, data_count;
  
  reg ps2_clk_en, ps2_clk_en_next, ps2_data_en, ps2_data_en_next;
  reg ps2_clk_out, ps2_clk_out_next, ps2_data_out, ps2_data_out_next;
  reg err_next;
  reg [3:0] state, state_next;
  reg rx_finish;
  
  reg [3:0] bits_count;
  
  reg [13:0] counter, counter_next;
  
  IOBUF IOBUF_inst_0(
    .O(ps2_clk_in),
    .IO(ps2_clk),
    .I(ps2_clk_out),
    .T(~ps2_clk_en)
  );
    
  IOBUF IOBUF_inst_1(
    .O(ps2_data_in),
    .IO(ps2_data),
    .I(ps2_data_out),
    .T(~ps2_data_en)
  );
  //assign ps2_clk = (ps2_clk_en)?ps2_clk_out:1'bz;
  //assign ps2_data = (ps2_data_en)?ps2_data_out:1'bz;
  assign busy = (state==IDLE)?1'b0:1'b1;
  
  always @ (posedge clk, posedge rst)begin
    if(rst)begin
      rx_data <= 0;
      rx_valid <= 1'b0;
    end else if(rx_finish==1'b1)begin                       // set read signal for the client to know
      rx_data <= frame[8:1];                                // a new byte was received and is available on rx_data
      rx_valid <= 1'b1;
    end else begin
      rx_data <= rx_data;
      rx_valid <= 1'b0;
    end
  end
  
  assign rx_parity = parity_table[frame[8:1]];
  assign tx_parity = parity_table[tx_data];
  
  always @ (posedge clk, posedge rst)begin
    if(rst)
      frame <= 0;
    else if(tx_valid==1'b1 && state==IDLE) begin
      frame[0] <= 1'b0;              //start bit
      frame[8:1] <= tx_data;         //data
      frame[9] <= tx_parity;         //parity bit
      frame[10] <= 1'b1;             //stop bit
    end else if(state==RX_NEG_EDGE || state==TX_CLK_LOW)
      frame <= {ps2_data_s, frame[10:1]};
    else
      frame <= frame;
  end
    
  // Debouncer
  always @ (posedge clk, posedge rst) begin
    if(rst)begin
      ps2_clk_s <= 1'b1;
      clk_inter <= 1'b1;
      clk_count <= 0;
    end else if(ps2_clk_in != clk_inter)begin
      ps2_clk_s <= ps2_clk_s;
      clk_inter <= ps2_clk_in;
      clk_count <= 0;
    end else if(clk_count == DEBOUNCE_DELAY) begin
      ps2_clk_s <= clk_inter;
      clk_inter <= clk_inter;
      clk_count <= clk_count;
    end else begin
      ps2_clk_s <= ps2_clk_s;
      clk_inter <= clk_inter;
      clk_count <= clk_count + 1'b1;
    end
  end
  
  always @ (posedge clk, posedge rst) begin
    if(rst)begin
      ps2_data_s <= 1'b1;
      data_inter <= 1'b1;
      data_count <= 0;
    end else if(ps2_data_in != data_inter)begin
      ps2_data_s <= ps2_data_s;
      data_inter <= ps2_data_in;
      data_count <= 0;
    end else if(data_count == DEBOUNCE_DELAY) begin
      ps2_data_s <= data_inter;
      data_inter <= data_inter;
      data_count <= data_count;
    end else begin
      ps2_data_s <= ps2_data_s;
      data_inter <= data_inter;
      data_count <= data_count + 1'b1;
    end
  end
  
  // FSM
  always @ (posedge clk, posedge rst)begin
    if(rst)begin
      state <= IDLE;
      ps2_clk_en <= 1'b0;
      ps2_clk_out <= 1'b0;
      ps2_data_en <= 1'b0;
      ps2_data_out <= 1'b0;
      err <= 1'b0;
      counter <= 0;
    end else begin
      state <= state_next;
      ps2_clk_en <= ps2_clk_en_next;
      ps2_clk_out <= ps2_clk_out_next;
      ps2_data_en <= ps2_data_en_next;
      ps2_data_out <= ps2_data_out_next;
      err <= err_next;
      counter <= counter_next;
    end
  end
  
  always @ * begin
    state_next = IDLE;                                     // default values for these signals
    ps2_clk_en_next = 1'b0;                                // ensures signals are reset to default value
    ps2_clk_out_next = 1'b1;                               // when conditions for their activation are no
    ps2_data_en_next = 1'b0;                               // longer applied (transition to other state,
    ps2_data_out_next = 1'b1;                              // where signal should not be active)
    err_next = 1'b0;                                       // Idle value for ps2_clk and ps2_data is 'Z'
    rx_finish = 1'b0;
    counter_next = 0;
    case(state)
      IDLE:begin                                           // wait for the device to begin a transmission
          if(tx_valid == 1'b1)begin                        // by pulling the clock line low and go to state
            state_next = TX_FORCE_CLK_LOW;                 // RX_NEG_EDGE or, if write is high, the
          end else if(ps2_clk_s == 1'b0)begin              // client of this interface wants to send a byte
            state_next = RX_NEG_EDGE;                      // to the device and a transition is made to state
          end else begin                                   // TX_FORCE_CLK_LOW
            state_next = IDLE;
          end
        end
        
      RX_NEG_EDGE:begin                                    // data must be read into frame in this state
          state_next = RX_CLK_LOW;                         // the ps2_clk just transitioned from high to low
        end
        
      RX_CLK_LOW:begin                                     // ps2_clk line is low, wait for it to go high
          if(ps2_clk_s == 1'b1)begin
            state_next = RX_CLK_HIGH;
          end else begin
            state_next = RX_CLK_LOW;
          end
        end
        
      RX_CLK_HIGH:begin                                    // ps2_clk is high, check if all the bits have been read
          if(bits_count == BITS_NUM)begin                  // if, last bit read, check parity, and if parity ok
            if(rx_parity != frame[9])begin                 // load received data into rx_data.
              err_next = 1'b1;                             // else if more bits left, then wait for the ps2_clk to
              state_next = IDLE;                           // go low
            end else begin
              rx_finish = 1'b1;
              state_next = IDLE;
            end
          end else if(ps2_clk_s == 1'b0)begin
            state_next = RX_NEG_EDGE;
          end else begin
            state_next = RX_CLK_HIGH;
          end		  
        end
        
      TX_FORCE_CLK_LOW:begin                               // the client wishes to transmit a byte to the device
          ps2_clk_en_next = 1'b1;                          // this is done by holding ps2_clk down for at least 100us
          ps2_clk_out_next = 1'b0;                         // bringing down ps2_data, wait 20us and then releasing
          if(counter == CLOCK_CNT_100US)begin              // the ps2_clk.
            state_next = TX_BRING_DATA_LOW;                // This constitutes a request to send command.
            counter_next = 0;                              // In this state, the ps2_clk line is held down and
          end else begin                                   // the counter for waiting 100us is enabled.
            state_next = TX_FORCE_CLK_LOW;                 // when the counter reached upper limit, transition
            counter_next = counter + 1'b1;                 // to TX_BRING_DATA_LOW
          end                                              
        end                              

      TX_BRING_DATA_LOW:begin                              // with the ps2_clk line low bring ps2_data low
          ps2_clk_en_next = 1'b1;                          // wait for 20us and then go to TX_RELEASE_CLK
          ps2_clk_out_next = 1'b0;

          // set data line low
          // when clock is released in the next state
          // the device will read bit 0 on data line
          // and this bit represents the start bit.
          ps2_data_en_next = 1'b1;
          ps2_data_out_next = 1'b0;
          if(counter == CLOCK_CNT_20US)begin
            state_next = TX_RELEASE_CLK;
            counter_next = 0;
          end else begin
            state_next = TX_BRING_DATA_LOW;
            counter_next = counter + 1'b1;
          end
        end
        
      TX_RELEASE_CLK:begin                                 // release the ps2_clk line
          ps2_clk_en_next = 1'b0;                          // keep holding data line low 
          ps2_data_en_next = 1'b1;
          ps2_data_out_next = 1'b0;
          state_next = TX_WAIT_FIRTS_NEG_EDGE;
        end
        
      TX_WAIT_FIRTS_NEG_EDGE:begin                         // state is necessary because the clock signal
          ps2_data_en_next = 1'b1;                         // is not released instantaneously and, because of debounce, 
          ps2_data_out_next = 1'b0;                        // delay is even greater. 
          if(counter == 14'd63)begin                       // Wait 63 clock periods for the clock line to release 
            if(ps2_clk_s == 1'b0)begin                     // then if clock is low then go to tx_clk_l 
              state_next = TX_CLK_LOW;                     // else wait until ps2_clk goes low. 
              counter_next = 0;                            
            end else begin
              state_next = TX_WAIT_FIRTS_NEG_EDGE;
              counter_next = counter;
            end
          end else begin
            state_next = TX_WAIT_FIRTS_NEG_EDGE;
            counter_next = counter + 1'b1;
          end
        end
      
      TX_CLK_LOW:begin                                     // place the least significant bit from frame 
          ps2_data_en_next = 1'b1;                         // on the data line
          ps2_data_out_next = frame[0];                    // During this state the frame is shifted one
          state_next = TX_WAIT_POS_EDGE;                   // bit to the right
        end
      
      TX_WAIT_POS_EDGE:begin                               // wait for the clock to go high
          ps2_data_en_next = 1'b1;                         // this is the edge on which the device reads the data
          ps2_data_out_next = frame[0];                    // on ps2_data.
          if(bits_count == BITS_NUM-1)begin                // keep holding ps2_data on frame(0) because else
            ps2_data_en_next = 1'b0;                       // will be released by default value.
            state_next = TX_WAIT_POS_EDGE_BEFORE_ACK;      // Check if sent the last bit and if so, release data line
          end else if(ps2_clk_s == 1'b1)begin              // and go to state that wait for acknowledge
            state_next = TX_CLK_HIGH;
          end else begin
            state_next = TX_WAIT_POS_EDGE;
          end
        end
    
      TX_CLK_HIGH:begin                                    // ps2_clk is released, wait for down edge
          ps2_data_en_next = 1'b1;                         // and go to tx_clk_l when arrived
          ps2_data_out_next = frame[0];
          if(ps2_clk_s == 1'b0)begin
            state_next = TX_CLK_LOW;
          end else begin
            state_next = TX_CLK_HIGH;
          end
        end
      
      TX_WAIT_POS_EDGE_BEFORE_ACK:begin                    // release ps2_data and wait for rising edge of ps2_clk
          if(ps2_clk_s == 1'b1)begin                       // once this occurs, transition to tx_wait_ack
            state_next = TX_WAIT_ACK;
          end else begin
            state_next = TX_WAIT_POS_EDGE_BEFORE_ACK;
          end
        end
        
      TX_WAIT_ACK:begin                                    // wait for the falling edge of the clock line
          if(ps2_clk_s == 1'b0)begin                       // if data line is low when this occurs, the
            if(ps2_data_s == 1'b0) begin                   // ack is received
              state_next = TX_RECEIVED_ACK;                // else if data line is high, the device did not
            end else begin                                 // acknowledge the transimission
              state_next = TX_ERROR_NO_ACK;
            end
          end else begin
            state_next = TX_WAIT_ACK;
          end
        end
      
      TX_RECEIVED_ACK:begin                                // wait for ps2_clk to be released together with ps2_data
          if(ps2_clk_s == 1'b1 && ps2_clk_s == 1'b1)begin  // (bus to be idle) and go back to idle state
            state_next = IDLE;
          end else begin
            state_next = TX_RECEIVED_ACK;
          end
        end
        
      TX_ERROR_NO_ACK:begin
          if(ps2_clk_s == 1'b1 && ps2_clk_s == 1'b1)begin  // wait for ps2_clk to be released together with ps2_data
            err_next = 1'b1;                               // (bus to be idle) and go back to idle state
            state_next = IDLE;                             // signal error for not receiving ack
          end else begin
            state_next = TX_ERROR_NO_ACK;
          end
        end
    
      default:begin                                        // if invalid transition occurred, signal error and
          err_next = 1'b1;                                 // go back to idle state
          state_next = IDLE;
        end
        
    endcase
  end
  
  always @ (posedge clk, posedge rst)begin
    if(rst)
      bits_count <= 0;
    else if(state==IDLE)
      bits_count <= 0;
    else if(state==RX_NEG_EDGE || state==TX_CLK_LOW)
      bits_count <= bits_count + 1'b1;
    else
      bits_count <= bits_count;
  end
    
endmodule

module KeyboardCtrl#(
   parameter SYSCLK_FREQUENCY_HZ = 100000000
)(
    output reg [7:0] key_in,
    output reg is_extend,
    output reg is_break,
    output reg valid,
    output err,
    inout PS2_DATA,
    inout PS2_CLK,
    input rst,
    input clk
);
//////////////////////////////////////////////////////////
// This Keyboard  Controller do not support lock LED control
//////////////////////////////////////////////////////////

    parameter RESET          = 3'd0;
    parameter SEND_CMD       = 3'd1;
    parameter WAIT_ACK       = 3'd2;
    parameter WAIT_KEYIN     = 3'd3;
    parameter GET_BREAK      = 3'd4;
    parameter GET_EXTEND     = 3'd5;
    parameter RESET_WAIT_BAT = 3'd6;
    
    parameter CMD_RESET           = 8'hFF; 
    parameter CMD_SET_STATUS_LEDS = 8'hED;
    parameter RSP_ACK             = 8'hFA;
    parameter RSP_BAT_PASS        = 8'hAA;
    
    parameter BREAK_CODE  = 8'hF0;
    parameter EXTEND_CODE = 8'hE0;
    parameter CAPS_LOCK   = 8'h58;
    parameter NUM_LOCK    = 8'h77;
    parameter SCR_LOCK    = 8'h7E;
    
    reg next_is_extend, next_is_break, next_valid;

    wire [7:0] rx_data;
    wire rx_valid;
    wire busy;
    
    reg [7:0] tx_data, next_tx_data;
    reg tx_valid, next_tx_valid;
    reg [2:0] state, next_state;
    reg [2:0] lock_status, next_lock_status;
    
    always @ (posedge clk, posedge rst)
        if(rst)
            key_in <= 0;
        else if(rx_valid)
            key_in <= rx_data;
        else
            key_in <= key_in;
    
    always @ (posedge clk, posedge rst)begin
        if(rst)begin
            state <= RESET;
            is_extend <= 1'b0;
            is_break <= 1'b1;
            valid <= 1'b0;
            lock_status <= 3'b0;
            tx_data <= 8'h00;
            tx_valid <= 1'b0;
        end else begin
            state <= next_state;
            is_extend <= next_is_extend;
            is_break <= next_is_break;
            valid <= next_valid;
            lock_status <= next_lock_status;
            tx_data <= next_tx_data;
            tx_valid <= next_tx_valid;
        end
    end
    always @ (*) begin
        case (state)
            RESET:    next_state = SEND_CMD;
            SEND_CMD: next_state = (busy == 1'b0) ? WAIT_ACK : SEND_CMD;
            WAIT_ACK: begin
                if(rx_valid == 1'b1) begin
                    if(rx_data == RSP_ACK && tx_data == CMD_RESET) begin
                        next_state = RESET_WAIT_BAT;
                    end else if(rx_data == RSP_ACK && tx_data == CMD_SET_STATUS_LEDS) begin
                        next_state = SEND_CMD;
                    end else begin
                        next_state = WAIT_KEYIN;
                    end
                end else begin
                    next_state = (err == 1'b1) ? RESET : WAIT_ACK;
                end
            end
            WAIT_KEYIN: begin
                if (rx_valid == 1'b1) begin
                    case (rx_data)
                        BREAK_CODE:  next_state = GET_BREAK;
                        EXTEND_CODE: next_state = GET_EXTEND;
                        default:     next_state = WAIT_KEYIN;
                    endcase
                end else begin
                    next_state = (err == 1'b1) ? RESET : WAIT_KEYIN;
                end
            end
            GET_BREAK: begin
                if (rx_valid == 1'b1)
                    next_state = WAIT_KEYIN;
                else
                    next_state = (err == 1'b1) ? RESET : GET_BREAK;
            end
            GET_EXTEND: begin
                if (rx_valid == 1'b1)
                    next_state = (rx_data == BREAK_CODE) ? GET_BREAK : WAIT_KEYIN;
                else
                    next_state = (err == 1'b1) ? RESET : GET_EXTEND;
            end
            RESET_WAIT_BAT: begin
                if (rx_valid == 1'b1)
                    next_state = (rx_data == RSP_BAT_PASS) ? WAIT_KEYIN : RESET;
                else
                    next_state = (err == 1'b1) ? RESET : RESET_WAIT_BAT;
            end
            default: next_state = RESET;
        endcase
    end
    always @ (*) begin
        next_tx_valid = 1'b0;
        case (state)
            RESET:    next_tx_valid = 1'b0;
            SEND_CMD: next_tx_valid = ~busy;
            default:  next_tx_valid = next_tx_valid;
        endcase
    end
    always @ (*) begin
        next_tx_data = tx_data;
        case (state)
            RESET:    next_tx_data = CMD_RESET;
            WAIT_ACK: next_tx_data = (rx_data == RSP_ACK && tx_data == CMD_SET_STATUS_LEDS) ? {5'b00000, lock_status} : next_tx_data;
            default:  next_tx_data = next_tx_data;
        endcase
    end
    always @ (*) begin
        next_lock_status = (state == RESET) ? 3'b0 : lock_status;
    end
    always @ (*) begin
        next_valid = 1'b0;
        case (state)
            RESET:      next_valid = 1'b0;
            WAIT_KEYIN: next_valid = (rx_valid == 1'b1 && rx_data != BREAK_CODE && rx_data != EXTEND_CODE) ? 1'b1 : next_valid;
            GET_BREAK:  next_valid = (rx_valid == 1'b1) ? 1'b1 : next_valid;
            GET_EXTEND: next_valid = (rx_valid == 1'b1 && rx_data != BREAK_CODE) ? 1'b1 : next_valid;
            default: next_valid = next_valid;
        endcase
    end
    always @ (*) begin
        next_is_break = ((state == RESET) || (state == GET_BREAK && rx_valid == 1'b1)) ? 1'b1 : 1'b0;
        next_is_extend = 1'b0;
        case (state)
            RESET:      next_is_extend = 1'b0;
            GET_BREAK:  next_is_extend = is_extend;
            GET_EXTEND: next_is_extend = (rx_valid == 1'b1) ? 1'b1 : next_is_extend;
            default:    next_is_extend = next_is_extend;
        endcase
    end

    Ps2Interface #(
      .SYSCLK_FREQUENCY_HZ(SYSCLK_FREQUENCY_HZ)
    ) Ps2Interface_i(
      .ps2_clk(PS2_CLK),
      .ps2_data(PS2_DATA),
      
      .clk(clk),
      .rst(rst),
      
      .tx_data(tx_data),
      .tx_valid(tx_valid),
      
      .rx_data(rx_data),
      .rx_valid(rx_valid),
      
      .busy(busy),
      .err(err)
    );
        
endmodule

module KeyboardDecoder(
    output reg [511:0] key_down,
    output wire [8:0] last_change,
    output reg key_valid,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire rst,
    input wire clk
    );
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
    parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key, next_key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state, next_state;
    reg been_ready, been_extend, been_break;
    reg next_been_ready, next_been_extend, next_been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl inst (
        .key_in(key_in),
        .is_extend(is_extend),
        .is_break(is_break),
        .valid(valid),
        .err(err),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );
    
    OnePulse op (
        .signal_single_pulse(pulse_been_ready),
        .signal(been_ready),
        .clock(clk)
    );
    
    //for jotting down the data of an event
    //for updating the state
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            state <= INIT;
            been_ready  <= 1'b0;
            been_extend <= 1'b0;
            been_break  <= 1'b0;
            key <= 10'b0_0_0000_0000;
        end else begin
            state <= next_state;
            been_ready  <= next_been_ready;
            been_extend <= next_been_extend;
            been_break  <= next_been_break;
            key <= next_key;
        end
    end
    
    always @ (*) begin
        case (state)
            INIT:            next_state = (key_in == IS_INIT) ? WAIT_FOR_SIGNAL : INIT;
            WAIT_FOR_SIGNAL: next_state = (valid == 1'b0) ? WAIT_FOR_SIGNAL : GET_SIGNAL_DOWN;
            GET_SIGNAL_DOWN: next_state = WAIT_RELEASE;
            WAIT_RELEASE:    next_state = (valid == 1'b1) ? WAIT_RELEASE : WAIT_FOR_SIGNAL;
            default:         next_state = INIT;
        endcase
    end
    always @ (*) begin
        next_been_ready = been_ready;
        case (state)
            INIT:            next_been_ready = (key_in == IS_INIT) ? 1'b0 : next_been_ready;
            WAIT_FOR_SIGNAL: next_been_ready = (valid == 1'b0) ? 1'b0 : next_been_ready;
            GET_SIGNAL_DOWN: next_been_ready = 1'b1;
            WAIT_RELEASE:    next_been_ready = next_been_ready;
            default:         next_been_ready = 1'b0;
        endcase
    end

    //the three datas in a key
        always @ (*) begin
            next_been_extend = (is_extend) ? 1'b1 : been_extend;
            case (state)
                INIT:            next_been_extend = (key_in == IS_INIT) ? 1'b0 : next_been_extend;
                WAIT_FOR_SIGNAL: next_been_extend = next_been_extend;
                GET_SIGNAL_DOWN: next_been_extend = next_been_extend;
                WAIT_RELEASE:    next_been_extend = (valid == 1'b1) ? next_been_extend : 1'b0;
                default:         next_been_extend = 1'b0;
            endcase
        end
        always @ (*) begin
            next_been_break = (is_break) ? 1'b1 : been_break;//set to 1 because there is a possible legal break
            case (state)
                INIT:            next_been_break = (key_in == IS_INIT) ? 1'b0 : next_been_break;//reset to say that break signal is never given //keep the state whether if break signal is given
                WAIT_FOR_SIGNAL: next_been_break = next_been_break;
                GET_SIGNAL_DOWN: next_been_break = next_been_break;
                WAIT_RELEASE:    next_been_break = (valid == 1'b1) ? next_been_break : 1'b0;//clear the break signal collection record after an event
                default:         next_been_break = 1'b0;
            endcase
        end
        always @ (*) begin
            next_key = key;
            case (state)
                INIT:            next_key = (key_in == IS_INIT) ? 10'b0_0_0000_0000 : next_key;
                WAIT_FOR_SIGNAL: next_key = next_key;
                GET_SIGNAL_DOWN: next_key = {been_extend, been_break, key_in};//we jot down the data given throughout a multi clk cycle event 
                WAIT_RELEASE:    next_key = next_key;
                default:         next_key = 10'b0_0_0000_0000;
            endcase
        end

    //keydown the table for keys being pressed down
    //keyvalid set to 1 when there is a new change for key pressed/released
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            key_valid <= 1'b0;
            key_down <= 511'b0;
        end else if (key_decode[last_change] && pulse_been_ready) begin
            key_valid <= 1'b1;
            if (key[8] == 0) begin
                key_down <= key_down | key_decode;//combine all the pressed down keys
            end else begin
                key_down <= key_down & (~key_decode);//remove the key which is told to us that it has been released
            end
        end else begin
            key_valid <= 1'b0;
            key_down <= key_down;
        end
    end
endmodule

module debounce(debounced,undebounced,clk);
    input undebounced,clk;
    output debounced;

    reg [3:0] dff;
    always@(posedge clk)begin
        dff[0]<=undebounced;
        dff[3:1]<=dff[2:0];
    end

    and and0(debounced,dff[0],dff[1],dff[2],dff[3]);
endmodule

module OnePulse (
    output reg signal_single_pulse,
    input wire signal,
    input wire clock
    );
    
    reg signal_delay;

    always @(posedge clock) begin
        if (signal == 1'b1 & signal_delay == 1'b0)
            signal_single_pulse <= 1'b1;
        else
            signal_single_pulse <= 1'b0;
        signal_delay <= signal;
    end
endmodule







