module instr_mem #( parameter PROGRAM_FILE = "tb/hex/program1.hex")( // Apenas leitura
    input logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [0:255];

    initial $readmemh(PROGRAM_FILE, mem);

    assign instr = mem[addr[31:2]]; // divide por 4 porque endereços são byte-addressed

endmodule