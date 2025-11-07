module axi_addr_logger #(
    parameter string FILENAME = "axi_addr.log",
    parameter type REQ_T = logic,
    parameter type RESP_T = logic
) (
    input logic  clk,
    input logic  rst_n,
    input REQ_T  ara_axi_req,
    input RESP_T ara_axi_resp
);

  integer fd;
  bit     enabled;

  logic   prev_ar_hs;
  logic   prev_aw_hs;

  initial begin
    string envv;
    fd = 0;
    enabled = 0;

    
    $value$plusargs("DUMP_AXI_ADDR=%s", envv);
    if (envv != "") begin
    enabled = 1;
    end

    if (enabled) begin
      fd = $fopen(FILENAME, "w");
      if (fd == 0) begin
        $display("axi_addr_logger: ERROR: failed to open %s for writing", FILENAME);
        enabled = 0;
      end else begin
        $display("axi_addr_logger: logging enabled -> file: %s", FILENAME);

        $fdisplay(fd, "%% ax i addr logger opened at time %0t", $time);
        $fdisplay(fd, "%% Format: <time> <chan> <id?> <addr(hex)>");
      end
    end else begin
      $display(
          "axi_addr_logger: logging disabled (no +DUMP_AXI_ADDR plusarg and no DUMP_AXI_ADDR env)");
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_ar_hs <= 0;
      prev_aw_hs <= 0;
    end else begin

      logic cur_ar_hs;
      logic cur_aw_hs;

      cur_ar_hs <= (ara_axi_req.ar_valid && ara_axi_resp.ar_ready);
      cur_aw_hs <= (ara_axi_req.aw_valid && ara_axi_resp.aw_ready);

      if (cur_ar_hs && !prev_ar_hs) begin
        if (enabled && fd != 0) begin
          $fdisplay(fd, "%0t AR addr: %0h", $time, ara_axi_req.ar.addr);
          $fflush(fd);
        end
      end

      if (cur_aw_hs && !prev_aw_hs) begin
        if (enabled && fd != 0) begin
          $fdisplay(fd, "%0t AW addr: %0h", $time, ara_axi_req.aw.addr);
          $fflush(fd);
        end
      end

      prev_ar_hs <= cur_ar_hs;
      prev_aw_hs <= cur_aw_hs;
    end
  end

  final begin
    if (fd != 0) begin
      $fdisplay(fd, "%% ax i addr logger closed at time %0t", $time);
      $fclose(fd);
    end
  end
endmodule
