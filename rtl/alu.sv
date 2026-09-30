module alu (
    input logic[31:0] regA,
    input logic[31:0] regB,
    input logic[3:0] instr,
    output logic[31:0] res,  
    output logic zero_flag  
    );

    always_comb begin 
        case (instr)
            4'b0000: res = regA + regB; // ADD
            4'b0001: res = regA - regB; // SUB
            4'b0010: res = regA & regB; // AND
            4'b0011: res = regA | regB; // OR
            4'b0100: res = regA ^ regB; // XOR
            4'b0101: res = regA << (regB & 5'b11111); // SLL
            4'b0110: res = regA >> (regB & 5'b11111); // SRL
            4'b0111: res = $signed(regA) >>> (regB & 5'b11111);// SRA
            4'b1000: res = ($signed(regA) < $signed(regB)) ? 32'd1 : 32'd0; // SLT
            4'b1001: res = (regA < regB) ? 32'd1 : 32'd0;// SLTU
            default: res = 32'd0;
        endcase
        zero_flag = res == 32'd0 ? 1 : 0;
    end
    /*
    >> é um right shift lógico — desloca bits para a direita
     e preenche os bits mais significativos com zeros.
    >>> é um right shift aritmético — replica o bit de sinal (MSB) 
    para os bits mais significativos, preservando o sinal em representação two's‑complement.
    $signed(expressão) para interpretar o valor como signed, por defeito nao interpreta
    */



endmodule