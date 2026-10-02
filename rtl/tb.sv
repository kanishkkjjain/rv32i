// tb.sv - simulation harness for the RV32I core
//
// Compile:  xvlog -sv rv_pkg.sv immgen.sv decoder.sv alu.sv branch.sv reg_file.sv lsu.sv mem.sv core.sv tb.sv
// Elab:     xelab tb -s tb_sim -debug typical
// Run:      xsim tb_sim -R -testplusarg HEX=C:/rv32i/tests/my_test.hex
//           (use forward slashes and an absolute path)
//
// Pass/fail convention (same as riscv-tests):
//   program ends with ECALL; at that point x3 (gp) == 1 means PASS,
//   anything else means FAIL, failing test number = gp >> 1.

module tb;

  localparam int TIMEOUT_CYCLES = 100_000;

  logic        clk;
  logic        rst_n;
  logic [31:0] i_addr, i_rdata;
  logic [31:0] d_addr, d_wdata, d_rdata;
  logic        d_we;
  logic [3:0]  d_byte_en;
  logic        halt;

  string       hexfile;
  int          cycles = 0;
  logic [31:0] gp;

  // ---------------- clock: 10 ns period ----------------
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------- DUT + memory ----------------
  core u_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .i_rdata   (i_rdata),
    .d_rdata   (d_rdata),
    .i_addr    (i_addr),
    .d_addr    (d_addr),
    .d_we      (d_we),
    .d_byte_en (d_byte_en),
    .d_wdata   (d_wdata),
    .halt      (halt)
  );

  memory u_memory (
    .clk       (clk),
    .i_addr    (i_addr),
    .i_rdata   (i_rdata),
    .d_addr    (d_addr),
    .d_we      (d_we),
    .d_byte_en (d_byte_en),
    .d_wdata   (d_wdata),
    .d_rdata   (d_rdata)
  );

  // ---------------- load program, then release reset ----------------
  // Loading and reset live in ONE initial block so the program is
  // guaranteed to be in memory before the core starts fetching.
  initial begin
    rst_n = 1'b0;

    if (!$value$plusargs("HEX=%s", hexfile)) begin
      $display("ERROR: no program given. Run with -testplusarg HEX=<absolute path to .hex>");
      $finish;
    end

    $readmemh(hexfile, u_memory.mem);
    if ($isunknown(u_memory.mem[0]))
      $display("WARNING: mem[0] is X after loading %s - wrong path or empty file?", hexfile);
    else
      $display("Loaded %s (first word = %h)", hexfile, u_memory.mem[0]);

    repeat (3) @(posedge clk);
    @(negedge clk);          // release away from the active edge to avoid races
    rst_n = 1'b1;
  end

  // ---------------- end-of-test check + timeout ----------------
  always @(posedge clk) begin
    if (rst_n) begin
      cycles <= cycles + 1;

      if (halt) begin
        gp = u_core.u_reg_file.reg_file_1[3];
        if (gp == 32'd1)
          $display("PASS  (%0d cycles)", cycles);
        else
          $display("FAIL  test %0d  (gp = %h, %0d cycles)", gp >> 1, gp, cycles);
        dump_regs();
        $finish;
      end

      if (cycles >= TIMEOUT_CYCLES) begin
        $display("TIMEOUT after %0d cycles (pc = %h)", cycles, u_core.pc_q);
        dump_regs();
        $finish;
      end
    end
  end

  // ---------------- register dump for debugging ----------------
  task automatic dump_regs();
    for (int i = 0; i < 32; i++) begin
      if (i == 0)
        $display("  x%0d\t= %h", i, 32'h0);
      else
        $display("  x%0d\t= %h", i, u_core.u_reg_file.reg_file_1[i]);
    end
  endtask

endmodule