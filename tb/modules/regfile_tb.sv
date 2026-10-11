module regfile_tb;
    logic        clk;
    logic        reset;
    logic        we;          // write enable
    logic [4:0]  rs1, rs2;    // endereços de leitura
    logic [4:0]  rd;         // endereço de escrita
    logic [31:0] wd;           // dado a escrever
    logic [31:0] rd1, rd2;      // dados l

    regfile dut (
        .clk(clk),
        .reset(reset),
        .we(we),
        .rs1(rs1),.rs2(rs2),
        .rd(rd),
        .wd(wd),
        .rd1(rd1),.rd2(rd2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin 
        reset = 1'b1;
        we = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd0;
        wd = 32'd0;

        @(posedge clk);
        #1;
        for (int i = 0; i < 32; i++) begin
            if (dut.registers[i] !== 32'd0)
                $fatal(1, "Reset nao limpou registers[%0d]", i);
        end

        @(negedge clk);
        reset = 1'b0;
        we = 1'b1;
        rd = 5'd1;
        wd = 32'h12345678;
        @(posedge clk);
        #1;
        we = 1'b0;
        rs1 = 5'd1;
        rs2 = 5'd0;
        #1;
        if (rd1 !== 32'h12345678 || rd2 !== 32'd0)
            $fatal(1, "Falha na leitura apos escrita: rd1=%h rd2=%h", rd1, rd2);

        @(negedge clk);
        reset = 1'b1;
        @(posedge clk);
        #1;
        for (int i = 0; i < 32; i++) begin
            if (dut.registers[i] !== 32'd0)
                $fatal(1, "Reset nao limpou registers[%0d] apos escrita", i);
        end

        $display("Todos os testes do regfile passaram.");
        $finish;
    end    

endmodule