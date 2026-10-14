module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    output logic       reg_write, 
    output logic       mem_write, 
    output logic       mem_read,
    output logic [1:0] jump,
    output logic [3:0] alu_op,
    output logic       alu_src,
    output logic [2:0] write_back
);
    localparam logic [3:0] ALU_ADD  = 4'b0000,
                           ALU_SUB  = 4'b0001,
                           ALU_AND  = 4'b0010,
                           ALU_OR   = 4'b0011,
                           ALU_XOR  = 4'b0100,
                           ALU_SLL  = 4'b0101,
                           ALU_SRL  = 4'b0110,
                           ALU_SRA  = 4'b0111,
                           ALU_SLT  = 4'b1000,
                           ALU_SLTU = 4'b1001;


    always_comb begin 
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        jump      = 2'b00;
        alu_op    = ALU_ADD;
        alu_src   = 1'b0;
        write_back= 3'b000;
        case (opcode) 
            7'b0110011: // R-Type
                begin
                    reg_write = 1'b1;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    jump = 2'b00;
                    alu_src = 1'b0; 
                    write_back = 3'b000;
                    case (funct3)
                        3'b000: alu_op = funct7_5 == 1'b0 ? ALU_ADD : ALU_SUB; 
                        3'b100: alu_op = ALU_XOR; 
                        3'b110: alu_op = ALU_OR; 
                        3'b111: alu_op = ALU_AND; 
                        3'b001: alu_op = ALU_SLL; 
                        3'b101: alu_op = funct7_5 ==  1'b0 ? ALU_SRL : ALU_SRA; 
                        3'b010: alu_op = ALU_SLT; 
                        3'b011: alu_op = ALU_SLTU;
                    endcase     
                end    
            7'b0010011: // I-Type
                begin 
                    reg_write = 1'b1;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    jump = 2'b00;
                    alu_src = 1'b1;
                    write_back = 3'b000;
                    case (funct3)
                        3'b000: alu_op = ALU_ADD; 
                        3'b100: alu_op = ALU_XOR; 
                        3'b110: alu_op = ALU_OR; 
                        3'b111: alu_op = ALU_AND; 
                        3'b001: alu_op = ALU_SLL; 
                        3'b101: alu_op = funct7_5 ==  1'b0 ? ALU_SRL : ALU_SRA; 
                        3'b010: alu_op = ALU_SLT; 
                        3'b011: alu_op = ALU_SLTU;
                    endcase
                end    
            7'b0000011: // I-Type Loads   
                begin
                    reg_write = 1'b1;
                    mem_read = 1'b1;
                    mem_write = 1'b0;
                    jump = 2'b00;
                    alu_src = 1'b1;
                    write_back = 3'b001;
                    alu_op = ALU_ADD;
                end    
            7'b0100011: // S-Type    
                begin
                    reg_write = 1'b0;
                    mem_write = 1'b1;
                    mem_read = 1'b0;
                    jump = 2'b00;
                    alu_src = 1'b1;
                    write_back = 3'b000;
                    alu_op = ALU_ADD;
                end    
            7'b1100011: // B-Type
                begin
                    reg_write = 1'b0;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    jump = 2'b01;
                    alu_src = 1'b0;
                    write_back = 3'b000;
                    case (funct3)
                        3'b000: alu_op = ALU_SUB; //beq
                        3'b001: alu_op = ALU_SUB; //bne ~beq
                        3'b100: alu_op = ALU_SLT; //blt x1<x2
                        3'b101: alu_op = ALU_SLT; //bge ~blt
                        3'b110: alu_op = ALU_SLTU;//bltu
                        3'b111: alu_op = ALU_SLTU;//bgeu ~bltu
                        default: alu_op = ALU_SUB;
                    endcase 
                end
            7'b1101111: // J-Type 
                begin
                    reg_write = 1'b1;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    alu_src = 1'b0;
                    write_back = 3'b010;
                    jump = 2'b10;
                end
            7'b1100111: //jalr
                begin
                    reg_write = 1'b1;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    alu_src = 1'b1;
                    write_back = 3'b010;
                    jump= 2'b11;
                    alu_op = ALU_ADD;
                end
            7'b0110111: //lui
                begin
                    reg_write = 1'b1;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    alu_src = 1'b0;
                    write_back = 3'b100;
                    jump= 2'b00;
                end
            7'b0010111: //auipc
                begin
                    reg_write = 1'b1;
                    mem_write = 1'b0;
                    mem_read = 1'b0;
                    alu_src = 1'b0;
                    write_back = 3'b011;
                    jump = 2'b00;
                end
            default: ; //keep default values
        endcase    
    end    
endmodule