module regfile (
    input  logic        clk,
    input  logic        we,           // write enable
    input  logic [4:0]  rs1, rs2,    // endereços de leitura
    input  logic [4:0]  rd,           // endereço de escrita
    input  logic [31:0] wd,           // dado a escrever
    output logic [31:0] rd1, rd2      // dados lidos
);   
    logic [31:0] registers [0:31];

    always_comb begin
        if (rd1 == 5'd0) rd1 = 32'd0;
        else rd1 = registers [rs1];
        if (rd2 == 5'd0) rd2 = 32'd0;
        else rd2 = registers [rs2];
    end    

    always_ff @(posedge clk) begin
        if (we && rd != 5'd0) registers[rd] <= wd; 
    end    

endmodule