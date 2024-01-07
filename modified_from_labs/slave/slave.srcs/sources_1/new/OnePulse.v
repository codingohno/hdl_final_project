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
