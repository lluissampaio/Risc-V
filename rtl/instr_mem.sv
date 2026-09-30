module instr_mem( // Apenas leitura
    input logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [0:255];

    initial $readmemh("program.hex", mem);

    assign instr = mem[addr[31:2]]; // divide por 4 porque endereços são byte-addressed

endmodule