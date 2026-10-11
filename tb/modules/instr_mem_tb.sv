module instr_mem_tb;
    logic [31:0] addr;
    logic [31:0] instr;

    instr_mem dut (
        .addr(addr),
        .instr(instr)
    );

    task check_read(input logic [31:0] address, input logic [31:0] expected, input string msg);
        addr = address;
        #1;
        if (instr !== expected) begin
            $error("%s: esperado %h, obtido %h", msg, expected, instr);
            $finish;
        end else begin
            $display("PASS: %s -> %h", msg, instr);
        end
    endtask

    initial begin
        #1;

        check_read(32'h00000000, 32'h00000013, "instr em addr 0");
        check_read(32'h00000004, 32'h00500513, "instr em addr 4");
        check_read(32'h00000008, 32'h00A00593, "instr em addr 8");
        check_read(32'h0000000C, 32'h00B00613, "instr em addr 12");

        $display("Todos os testes da instr_mem passaram.");
        $finish;
    end
endmodule