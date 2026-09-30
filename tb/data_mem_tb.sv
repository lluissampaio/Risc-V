module data_mem_tb;
    logic clk;
    logic we;
    logic [31:0] addr;
    logic [31:0] wd;
    logic [31:0] rd;

    data_mem dut (
        .clk(clk),
        .we(we),
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

    initial begin
        we = 0;
        addr = 32'h00000000;
        wd = 32'h00000000;
        #1;

        // Escrita em um endereço e leitura imediata
        addr = 32'h00000000;
        wd = 32'hA5A5A5A5;
        we = 1;
        @(posedge clk);
        #1;
        check_read(wd, "leitura após escrita em addr 0");

        // Leitura sem escrever mantém o valor
        we = 0;
        #1;
        check_read(32'hA5A5A5A5, "leitura sem write em addr 0");

        // Escrita em outro endereço da memória
        addr = 32'h00000004;
        wd = 32'h12345678;
        we = 1;
        @(posedge clk);
        #1;
        check_read(wd, "leitura após escrita em addr 4");

        // Confirma que o valor do endereço anterior continua guardado
        we = 0;
        addr = 32'h00000000;
        #1;
        check_read(32'hA5A5A5A5, "valor anterior preservado em addr 0");

        // Teste adicional com outro endereço
        addr = 32'h00000008;
        wd = 32'hDEADBEEF;
        we = 1;
        @(posedge clk);
        #1;
        we = 0;
        addr = 32'h00000008;
        #1;
        check_read(32'hDEADBEEF, "leitura em addr 8");

        $display("Todos os testes da data_mem passaram.");
        $finish;
    end
endmodule