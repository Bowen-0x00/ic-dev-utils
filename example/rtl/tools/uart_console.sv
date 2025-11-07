
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
