module regfile_tb;
    logic        clk;
    logic        we;          // write enable
    logic [4:0]  rs1, rs2;    // endereços de leitura
    logic [4:0]  rd;         // endereço de escrita
    logic [31:0] wd;           // dado a escrever
    logic [31:0] rd1, rd2;      // dados l

    regfile dut (
        .clk(clk),
        .we(we),
        .rs1(rs1),.rs2(rs2),
        .rd(rd),
        .wd(wd),
        .rd1(rd1),.rd2(rd2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin 
        we = 0;
        rs1 = 0; rs2 = 0;
        wd = 0;
        #1;
        for (int i=1; i<32;i++) begin
            we = 1;
            rd = i;
            wd = i * 2;
            @(posedge clk);
        end
        for (int i=0 ; i<31 ; i = i+2) begin
            rs1 = i;
            rs2 = i+1;
            #1
            if (rd1 != i*2 || rd2 != (i+1)*2) begin
                $display("Errro");
            end
            else $display("Bom");    
        end
        $finish;
    end    

endmodule