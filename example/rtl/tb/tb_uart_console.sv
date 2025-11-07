// tb_uart_console.sv
`timescale 1ns/1ps

module tb_uart_console;
    // clock
    logic clk = 0;
    always #5 clk = ~clk; // 10ns period

    // reset (active low)
    logic rst_n;

    // APB-like signals to drive uart_console
    logic penable_i;
    logic pwrite_i;
    logic psel_i;
    logic [31:0] paddr_i;
    logic [31:0] pwdata_i;

    // Console address must match uart_console parameter
    localparam logic [31:0] CONSOLE_ADDR = 32'h1000_0000;

    // instantiate uart_console (assumes uart_console.sv present)
    uart_console #(.CONSOLE_ADDR(CONSOLE_ADDR)) uart_inst (
        .clk_i    (clk),
        .rst_ni   (rst_n),
        .penable_i(penable_i),
        .pwrite_i (pwrite_i),
        .paddr_i  (paddr_i),
        .psel_i   (psel_i),
        .pwdata_i (pwdata_i)
    );

    task automatic write_byte(input byte b);
        begin
            paddr_i   = CONSOLE_ADDR;
            pwdata_i  = {24'h0, b};
            psel_i    = 1'b1;
            pwrite_i  = 1'b1;
            penable_i = 1'b1;
            @(posedge clk);
            psel_i    = 1'b0;
            pwrite_i  = 1'b0;
            penable_i = 1'b0;
            pwdata_i  = 32'h0;
            paddr_i   = 32'h0;
            @(posedge clk);
        end
    endtask

    task automatic write_string(input string s);
        begin
            for (int i = 0; i < s.len()-1; i = i + 1) begin
                write_byte(s[i]);
            end
        end
    endtask

    // main stimulus
    initial begin
        string msg = "Hello, world!\n";
        rst_n     = 1'b0;
        psel_i    = 1'b0;
        penable_i = 1'b0;
        pwrite_i  = 1'b0;
        paddr_i   = 32'h0;
        pwdata_i  = 32'h0;

        // reset pulse
        repeat (4) @(posedge clk); // wait 4 cycles (40ns)
        rst_n = 1'b1;
        $display("[%0t] Release reset", $time);

        // wait a little, then send string
        repeat (2) @(posedge clk);
        // The string to print. You can change this to any text you like.
        

        $display("[%0t] Sending string via uart_console: \"%s\"", $time, msg);
        write_string(msg);

        // send another line to show multiple writes
        write_string("This is a test of uart_console.\n");

        // wait a few cycles to ensure console drained
        repeat (10) @(posedge clk);

        $display("[%0t] Testbench finished.", $time);
        $finish;
    end

    // Optional: small checker to ensure uart_console didn't hang (not required)
    // initial begin
    //     #10000;
    //     $display("Reached time limit, finishing.");
    //     $finish;
    // end

endmodule
