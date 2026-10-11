module data_mem_tb;
    logic clk;
    logic mem_write;
    logic mem_read;
    logic [2:0] funct3;
    logic [31:0] addr;
    logic [31:0] wd;
    logic [31:0] rd;

    data_mem dut (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .funct3(funct3),
        .addr(addr),
        .wd(wd),
        .rd(rd)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check_read(input logic [31:0] expected, input string msg);
        if (rd !== expected) begin
            $error("%s: esperado %h, obtido %h", msg, expected, rd);
            $finish;
        end else begin
            $display("PASS: %s -> %h", msg, rd);
        end
    endtask

    task write_mem(input logic [31:0] addr_in,
                   input logic [31:0] data_in,
                   input logic [2:0] funct3_in);
        addr = addr_in;
        wd = data_in;
        funct3 = funct3_in;
        mem_write = 1;
        mem_read = 0;
        @(posedge clk);
        #1;
        mem_write = 0;
    endtask

    task read_mem(input logic [31:0] addr_in,
                  input logic [2:0] funct3_in,
                  input logic [31:0] expected,
                  input string msg);
        addr = addr_in;
        funct3 = funct3_in;
        mem_write = 0;
        mem_read = 1;
        #1;
        check_read(expected, msg);
    endtask

    initial begin
        funct3 = 3'b000;
        addr = 32'h00000000;
        wd = 32'h00000000;
        mem_write = 0;
        mem_read = 0;
        #1;

        // 1) SW em 0x00 e LW em 0x00
        write_mem(32'h00000000, 32'hDEADBEEF, 3'b010);
        read_mem(32'h00000000, 3'b010, 32'hDEADBEEF, "lw após sw");

        // 2) SB em offset 0x00 e LB/LBU
        write_mem(32'h00000000, 32'h00000080, 3'b000);
        read_mem(32'h00000000, 3'b000, 32'hFFFFFF80, "lb com extensão de sinal");
        read_mem(32'h00000000, 3'b100, 32'h00000080, "lbu sem extensão");

        // 3) SH em offset 0x00 e LH/LHU
        write_mem(32'h00000000, 32'h00008000, 3'b001);
        read_mem(32'h00000000, 3'b001, 32'hFFFF8000, "lh com extensão de sinal");
        read_mem(32'h00000000, 3'b101, 32'h00008000, "lhu sem extensão");

        // 4) Escreve byte em offset 1 e lê com lb
        write_mem(32'h00000001, 32'h0000007F, 3'b000);
        read_mem(32'h00000001, 3'b000, 32'h0000007F, "lb no offset 1");

        // 5) Escreve halfword em offset 2 e lê com lh
        write_mem(32'h00000002, 32'h0000FFFF, 3'b001);
        read_mem(32'h00000002, 3'b001, 32'hFFFFFFFF, "lh no offset 2");

        // 6) Acesso em outro endereço da memória
        write_mem(32'h00000004, 32'h12345678, 3'b010);
        read_mem(32'h00000004, 3'b010, 32'h12345678, "lw em outro endereço");

        $display("Todos os testes da data_mem passaram.");
        $finish;
    end
endmodule