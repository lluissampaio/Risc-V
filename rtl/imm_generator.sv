module imm_generator(
    input logic[31:0] instr,
    output logic[31:0] imm
);
    always_comb begin
        imm = 32'b0;
        case (instr[6:0])
            7'b0010011: imm = {{20{instr[31]}}, instr[31:20]}; // I-Type normal
            7'b0000011: imm = {{20{instr[31]}}, instr[31:20]}; // I-Type loads
            7'b0100011: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type stores
            7'b1100011: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-Type 
            7'b0110111: imm = {instr[31:12], {12{1'b0}}}; // U-Type - lui
            7'b0010111: imm = {instr[31:12], {12{1'b0}}}; // U-Type - auipc
            7'b1101111: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-Type - jal
            7'b1100111: imm = {{20{instr[31]}}, instr[31:20]}; // I-Type - jalr
            default: ; //keep default values
        endcase
    end

endmodule
