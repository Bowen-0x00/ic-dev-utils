module watchdog_sim #(
    
)(
    input logic clk_i
);
    initial begin
        int timeout_cycles;
        timeout_cycles = 0;
        if ($test$plusargs("TIMEOUT")) begin
            $display("watchdog_sim: Using default TIMEOUT_CYCLES=%0d", timeout_cycles);
            $value$plusargs("TIMEOUT=%d", timeout_cycles);
        end
        if (timeout_cycles > 0) begin
            repeat (timeout_cycles) @(posedge clk_i);
            $fatal("Simulation watchdog: Timeout of %0d cycles reached. Terminating simulation.", timeout_cycles);
        end
    end
endmodule
