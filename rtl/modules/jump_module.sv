module jump_module(
    input logic [1:0] jump_control,
    input logic flag_zero,
    input logic [2:0] funct3,
    input logic [31:0] pc_4, pc_imm, alu_result,
    output logic [31:0] pc_next
);
    always_comb begin 
        pc_next = pc_4;
        case (jump_control)
            2'b00: pc_next = pc_4; // all instructions except the following ones
            2'b01: // Reserved for Branch instructions
                begin
                    case (funct3)
                        3'b000: pc_next = flag_zero ? pc_imm : pc_4; //beq
                        3'b001: pc_next = flag_zero ? pc_4   : pc_imm; //bne
                        3'b100: pc_next = flag_zero ? pc_4   : pc_imm; //blt
                        3'b101: pc_next = flag_zero ? pc_imm : pc_4;//bge
                        3'b110: pc_next = flag_zero ? pc_4   : pc_imm;//bltu
                        3'b111: pc_next = flag_zero ? pc_imm : pc_4;//bgeu
                        default: ;
                    endcase    
                end
            2'b10: pc_next = pc_imm; // Basic pc+imm instruction
            2'b11: pc_next = {alu_result[31:1], 1'b0}; // jalr instruction (LSb forced to 0)
        endcase
    end

endmodule