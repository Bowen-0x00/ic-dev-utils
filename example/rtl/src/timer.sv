// timer.sv
`timescale 1ns/1ps
module timer #(
    parameter int PERIOD = 10,            // number of clk cycles in one period
    parameter int DUTY   = 50             // duty cycle in percent (0..100)
)(
    input  logic clk,
    input  logic rst_n,                   // active low reset
    input  logic enable,                  // when low, counter is paused and outputs low
    output logic pulse,                   // high during duty window
    output logic tick                     // one-cycle pulse at period boundary
);

    // protect from invalid parameters (synthesis-friendly)
    localparam int _PERIOD = (PERIOD > 0) ? PERIOD : 1;
    localparam int _DUTY   = (DUTY >= 0 && DUTY <= 100) ? DUTY : 50;
    // threshold cycles for pulse high (at least 0, at most PERIOD)
    localparam int THRESH = (_PERIOD * _DUTY) / 100;

    // If THRESH == 0, pulse never asserted; if THRESH==PERIOD, pulse full-cycle.
    // Use an integer counter
    int unsigned cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt   <= 0;
            tick  <= 1'b0;
            pulse <= 1'b0;
        end else if (!enable) begin
            // paused: keep outputs low and do not advance counter
            cnt   <= cnt;
            tick  <= 1'b0;
            pulse <= 1'b0;
        end else begin
            // normal counting behavior
            if (cnt == _PERIOD - 1) begin
                // end of period: emit tick next cycle, reset counter
                cnt  <= 0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1;
                tick <= 1'b0;
            end

            // pulse asserted when cnt is in [0, THRESH-1]
            if (THRESH > 0 && cnt < THRESH)
                pulse <= 1'b1;
            else
                pulse <= 1'b0;
        end
    end

    // Optional: asynchronous debug-friendly display (synthesis will ignore)
    // synthesis translate_off
    // always_ff @(posedge clk) begin
    //     if (tick) $display("[%0t] tick asserted (cnt wrap)", $time);
    // end
    // synthesis translate_on

endmodule
