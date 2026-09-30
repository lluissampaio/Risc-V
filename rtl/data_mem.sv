module data_mem( //leitura e escrita
    input logic clk,
    input logic we,
    input logic [31:0] addr, 
    input logic [31:0] wd,
    output logic [31:0] rd
);
    logic [31:0] mem [0:255];

    always_ff @(posedge clk) begin
        if (we) mem[addr[31:2]] <= wd;
    end    

    assign rd = mem[addr[31:2]];

endmodule