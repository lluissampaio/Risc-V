module riscv_tb #(
    parameter string PROGRAM_FILE = "tb/hex/program1.hex",
    parameter int    MAX_CYCLES   = 1000
);
    logic clk = 0;
    logic reset = 1;
    int   cycles = 0;
    int   errors = 0;
    logic halted = 0;

    riscv #(.PROGRAM_FILE(PROGRAM_FILE)) dut(
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    task automatic check_reg(input int idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = (idx == 0) ? 32'd0 : dut.regfile.registers[idx];
        if (actual !== expected) begin
            $display("[FAIL] x%0d: expected 0x%08h, got 0x%08h", idx, expected, actual);
            errors++;
        end
    endtask

    task automatic check_mem(input int idx, input logic [31:0] expected);
        if (dut.data_mem.mem[idx] !== expected) begin
            $display("[FAIL] mem[%0d]: expected 0x%08h, got 0x%08h", idx, expected, dut.data_mem.mem[idx]);
            errors++;
        end
    endtask

    task automatic check_pc(input logic [31:0] expected);
        if (dut.pc !== expected) begin
            $display("[FAIL] PC: expected 0x%08h, got 0x%08h", expected, dut.pc);
            errors++;
        end
    endtask

    initial begin
        // Apply synchronous reset
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Execute until halt condition or timeout
        while (!halted && (cycles < MAX_CYCLES)) begin
            #1;
            // Stop if end of loaded program (uninitialized instruction memory),
            // ecall (00000073) / ebreak (00100073), or parked on a self-loop (pc_next == pc)
            if ((^dut.instr === 1'bx) ||
                (dut.instr === 32'h00000073) ||
                (dut.instr === 32'h00100073) ||
                (dut.pc_next === dut.pc)) begin
                halted = 1;
            end else begin
                @(posedge clk);
                cycles++;
            end
        end
        #1;

        // Dump architectural state
        for (int i = 0; i < 32; i++)
            $display("x%0d = 0x%08h", i, dut.regfile.registers[i]);
        for (int i = 0; i < 4; i++)
            $display("mem[%0d] = 0x%08h", i, dut.data_mem.mem[i]);
        $display("PC = 0x%08h (completed in %0d cycles)", dut.pc, cycles);

        // Self-checking assertions per test program
        if (PROGRAM_FILE == "tb/hex/program1.hex") begin
            check_reg(0,  32'h00000000);
            check_reg(1,  32'h0000000a);
            check_reg(2,  32'h00000014);
            check_reg(3,  32'h0000001e);
            check_reg(4,  32'h0000000a);
            check_reg(5,  32'h00000000);
            check_reg(6,  32'h0000001e);
            check_reg(7,  32'h0000001e);
            check_reg(8,  32'hffffffff);
            check_reg(9,  32'h000000a0);
            check_reg(10, 32'h0000000f);
            check_reg(11, 32'hffffffff);
            check_reg(12, 32'h00000001);
            check_reg(13, 32'h00000000);
            check_reg(14, 32'h0000001e);
            check_reg(15, 32'hffffffff);
            check_reg(16, 32'h000000ff);
            check_reg(17, 32'h00a0140a);
            check_reg(18, 32'h000000a0);
            check_mem(0,  32'h0000001e);
            check_mem(1,  32'hffffffff);
            check_mem(2,  32'h00a0140a);
            check_pc(32'h00000060);
        end else if (PROGRAM_FILE == "tb/hex/program2.hex") begin
            check_reg(0,  32'h00000000);
            check_reg(1,  32'h00000005);
            check_reg(2,  32'h00000005);
            check_reg(3,  32'h00000000);
            check_reg(4,  32'h00000001);
            check_reg(5,  32'h00000007);
            check_reg(6,  32'h00000002);
            check_reg(8,  32'h00000003);
            check_reg(9,  32'h00000003);
            check_reg(10, 32'h0000002a);
            check_pc(32'h00000038);
        end else if (PROGRAM_FILE == "tb/hex/program3.hex") begin
            check_reg(0,  32'h00000000);
            check_reg(1,  32'hffffffff);
            check_reg(2,  32'h00000001);
            check_reg(3,  32'h00000001);
            check_reg(4,  32'h00000002);
            check_reg(5,  32'h00000048);
            check_reg(6,  32'h12345000);
            check_reg(7,  32'h00001050);
            check_reg(9,  32'h00000054);
            check_reg(10, 32'h0000005c);
            check_reg(11, 32'h00000007);
            check_reg(20, 32'h00000000);
            check_pc(32'h00000064);
        end else if (dut.instr === 32'h00000073) begin
            // Standard riscv-tests pass convention: a0 (x10) == 0 on ecall
            check_reg(10, 32'h00000000);
        end

        if (cycles >= MAX_CYCLES) begin
            $display("[FAIL] Simulation timed out after %0d cycles!", MAX_CYCLES);
            $fatal(1);
        end else if (errors == 0) begin
            $display("=== [PASS] %s verified with 0 errors (%0d cycles) ===", PROGRAM_FILE, cycles);
        end else begin
            $display("=== [FAIL] %s failed with %0d error(s) ===", PROGRAM_FILE, errors);
            $fatal(1);
        end

        $finish;
    end

endmodule