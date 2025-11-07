
`timescale 1ns/1ps
module tb_watchdog;

    // clock generation
    logic clk;
    initial clk = 0;
    // 10ns period clock (toggle every 5ns)
    always #5 clk = ~clk;

    // reset and control
    logic rst_n;
    logic enable;

    // outputs
    logic pulse;
    logic tick;

    // instantiate timer with a small period to see many cycles quickly
    // e.g., PERIOD=8 (8 cycles), DUTY=25 -> pulse high for 2 cycles
    timer #(.PERIOD(8), .DUTY(25)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .pulse(pulse),
        .tick(tick)
    );

    // stimulus
    initial begin
        // initialize
        rst_n  = 1'b0;
        enable = 1'b0;
        repeat (2) @(posedge clk);                // wait 20ns
        rst_n = 1'b1;       // release reset at time 20ns

        @(posedge clk); 
        enable = 1'b1;      // start timer
        $display("[%0t] enable asserted", $time);

        // run for some cycles, observe ticks
        wait (tick); $display("[%0t] tick observed (1)", $time);
        wait (tick); $display("[%0t] tick observed (2)", $time);
        wait (tick); $display("[%0t] tick observed (3)", $time);

        // test pause behavior
        @(posedge clk);
        enable = 1'b0;
        $display("[%0t] enable deasserted (pause)", $time);
        // wait a bit to show no ticks while paused
        repeat (10) @(posedge clk);  
        enable = 1'b1;
        $display("[%0t] enable reasserted", $time);

        // collect a couple more ticks then finish
        wait (tick); $display("[%0t] tick observed (after resume)", $time);
        wait (tick); $display("[%0t] tick observed (final)", $time);

        repeat (2) @(posedge clk);  
        $display("[%0t] Simulation finished.", $time);
        $finish;
    end

    watchdog_sim wd_inst (
        .clk_i(clk)
    );

    uart_console uart_inst (
        .clk_i(clk),
        .rst_ni(rst_n),
        .penable_i(),
        .pwrite_i(),
        .paddr_i(),
        .psel_i(),
        .pwdata_i()
    );

endmodule




module uart_console #(
    parameter CONSOLE_ADDR = 32'h1000_0000
)(
    input  logic          clk_i,
    input  logic          rst_ni,
    input  logic          penable_i,
    input  logic          pwrite_i,
    input  logic [31:0]   paddr_i,
    input  logic          psel_i,
    input  logic [31:0]   pwdata_i
);
    always_ff @(posedge clk_i) begin
        if (psel_i && penable_i && pwrite_i && (paddr_i == CONSOLE_ADDR)) begin
            $write("%c", pwdata_i[7:0]);
        end
    end
endmodule

