
module slave_control(clk, rst_n, request, ack, data_in, notice, valid, data);
    input clk;
    input rst_n;
    input request;
    input [5-1:0] data_in;
    input valid;
    output reg ack;
    output reg notice;
    output reg [5-1:0] data;

    parameter state_wait_rqst = 2'b00;
    parameter state_wait_to_send_ack = 2'b01;
    parameter state_send_ack = 2'b10;
    parameter state_wait_data = 2'b11;

    reg [2-1:0] state, next_state;
    reg start, next_start;
    reg next_ack;
    reg next_notice;
    reg [5-1:0] next_data;
    wire done;
    counter cnt_0(.clk(clk), .rst_n(rst_n), .start(start), .done(done));

    always@(posedge clk) begin
        if (rst_n == 0) begin
            state <= state_wait_rqst;
            notice <= 0;
            ack <= 0;
            data <= 0;
            start <= 0;
        end
        else begin
            state <= next_state;
            notice <= next_notice;
            ack <= next_ack;
            data <= next_data;
            start <= next_start;
        end
    end

    always@(*) begin
        next_state = state;
        next_notice = notice;
        next_ack = ack;
        next_data = data;
        next_start = start;
        case(state)
            state_wait_rqst: begin
                next_state = (request == 1)? state_wait_to_send_ack: state_wait_rqst;
                next_notice = 1'b0;
                next_ack = 1'b0;
                next_data = data;
                next_start = (request == 1)? 1'b1: 1'b0;
            end
            state_wait_to_send_ack: begin
                next_state = (done == 1)? state_wait_data : state_wait_to_send_ack;
                next_notice = 1'b1;
                next_ack = (done == 1) ? 1'b1 : 1'b0;
                next_data = data;
                next_start = 1'b1;
            end
            state_wait_data: begin
                next_state = (valid == 1)? state_wait_rqst : state_wait_data;
                next_notice = 1'b0;
                next_ack = (valid == 1) ? 1'b0 : 1'b1; // from just 1'b1
                next_data = (valid == 1)? data_in : 5'd0; 
                next_start = 1'b0;
            end
            default: begin
            end
        endcase
    end
endmodule
