
module motor_puppet(
    input clk,
    input rst,
    output  pwm_for_motor,
    output[2-1:0] motor_direction,
    input[6-1:0] player1_lights,
    input[6-1:0] player2_lights
    //the lights means how many times the motor should have moved
);
    //we always compare the current motor condition with the codition outside
    //ensure that no movement command is dropped

    reg[6-1:0] motor_player1_light, next_motor_player1_light;
    reg[6-1:0] motor_player2_light, next_motor_player2_light;
    reg[2-1:0] state, next_state;
    

    //state encoding
        parameter READY_STATE=2'b00;
        parameter SPIN_FORWARD=2'b01;
        parameter SPIN_BACKWARD=2'b10;

    //sequential update
    always@(posedge clk)begin
        state<=next_state;
        motor_player1_light<=next_motor_player1_light;
        motor_player2_light<=next_motor_player2_light;
    end

    //the timer
    wire rst_combined;
    assign rst_combined=(rst||(state==READY_STATE));
    wire motor_time_up;
    clk_divider motor_moving_timer (27'd100000000, clk, motor_time_up,rst_combined);

    assign motor_direction=state;
    
    //determine next state and next_motor_light
    always@(*)begin
        if(rst)begin
            //state
            next_state=READY_STATE;

            //the lights
            next_motor_player1_light=6'd0;
            next_motor_player2_light=6'd0;
        end
        else begin
            case(state)
                READY_STATE:begin
                    //for next state
                    if((player1_lights>motor_player1_light) || (player2_lights<motor_player2_light))begin//one is losing
                        next_state=SPIN_FORWARD;
                        next_motor_player1_light=player1_lights;
                        next_motor_player2_light=player2_lights;

                    end
                    else if((player2_lights>motor_player2_light) || (player1_lights<motor_player1_light))begin//two is losing
                        next_state=SPIN_BACKWARD;
                        next_motor_player1_light=player1_lights;
                        next_motor_player2_light=player2_lights;
                    end
                    else begin
                        next_state=state;
                        next_motor_player1_light=motor_player1_light;
                        next_motor_player2_light=motor_player2_light;
                    end
                end

                SPIN_FORWARD:begin 
                    if( motor_time_up /*detect times up*/)begin
                        next_state=READY_STATE;
                        next_motor_player1_light=motor_player1_light;
                        next_motor_player2_light=motor_player2_light;
                    end
                    else begin
                        next_state=state;
                        next_motor_player1_light=motor_player1_light;
                        next_motor_player2_light=motor_player2_light;
                    end
                end

                SPIN_BACKWARD:begin
                    if( motor_time_up /*detect times up*/)begin
                        next_state=READY_STATE;
                        next_motor_player1_light=motor_player1_light;
                        next_motor_player2_light=motor_player2_light;
                    end
                    else begin
                        next_state=state;
                        next_motor_player1_light=motor_player1_light;
                        next_motor_player2_light=motor_player2_light;
                    end
                end

                default:begin
                    next_state=READY_STATE;
                    next_motor_player1_light=motor_player1_light;
                    next_motor_player2_light=motor_player2_light;
                end
            endcase
        end
    end


    motor_pwm motor_pwm_lehh(clk,rst,10'b1111111111,pwm_for_motor);
    

endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 32'd100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 32'd1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 32'b0;
            PWM <= 1'b0;
        end else if (count < count_max) begin
            count <= count + 32'd1;
            if(count < count_duty)
                PWM <= 1'b1;
            else
                PWM <= 1'b0;
        end else begin
            count <= 32'b0;
            PWM <= 1'b0;
        end
    end
endmodule
