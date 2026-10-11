module riscv_tb #( parameter PROGRAM_FILE = "tb/hex/program1.hex");
    logic clk = 0;
    logic reset = 1;

    riscv #(.PROGRAM_FILE(PROGRAM_FILE)) dut(
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;
        repeat (24) @(posedge clk);
        #1;
        for (int i = 0; i < 32; i++)
            $display("x%0d = 0x%08h", i, dut.regfile.registers[i]);
        $display("mem[0] = 0x%08h", dut.data_mem.mem[0]);
        $display("mem[1] = 0x%08h", dut.data_mem.mem[1]);
        $display("mem[2] = 0x%08h", dut.data_mem.mem[2]);
        $finish;
    end


endmodule