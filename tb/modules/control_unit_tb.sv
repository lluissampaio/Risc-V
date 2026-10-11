module control_unit_tb;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;
    logic       reg_write;
    logic       mem_write;
    logic       mem_read;
    logic       branch;
    logic [3:0] alu_op;
    logic       pc_src;
    logic       alu_src;
    logic       mem_to_reg;

    control_unit dut(
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .branch(branch),
        .alu_op(alu_op),
        .pc_src(pc_src),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg)
    );

    // Constantes para ALU_OP
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

    task check_instruction(input logic [31:0] instr,
                          input logic exp_reg_write,
                          input logic exp_mem_write,
                          input logic exp_mem_read,
                          input logic exp_branch,
                          input logic [3:0] exp_alu_op,
                          input logic exp_alu_src,
                          input logic exp_pc_src,
                          input logic exp_mem_to_reg,
                          input string msg);
        // Decodificar a instrução
        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7_5 = instr[30];
        #1;

        if (reg_write !== exp_reg_write || mem_write !== exp_mem_write ||
            mem_read !== exp_mem_read || branch !== exp_branch ||
            alu_op !== exp_alu_op || alu_src !== exp_alu_src ||
            pc_src !== exp_pc_src || mem_to_reg !== exp_mem_to_reg) begin
            $error("%s: FALHOU", msg);
            $display("  Instrução: %h", instr);
            $display("  reg_write: %b (esperado %b)", reg_write, exp_reg_write);
            $display("  mem_write: %b (esperado %b)", mem_write, exp_mem_write);
            $display("  mem_read: %b (esperado %b)", mem_read, exp_mem_read);
            $display("  branch: %b (esperado %b)", branch, exp_branch);
            $display("  alu_op: %b (esperado %b)", alu_op, exp_alu_op);
            $display("  alu_src: %b (esperado %b)", alu_src, exp_alu_src);
            $display("  pc_src: %b (esperado %b)", pc_src, exp_pc_src);
            $display("  mem_to_reg: %b (esperado %b)", mem_to_reg, exp_mem_to_reg);
            $finish;
        end else begin
            $display("PASS: %s (%h)", msg, instr);
        end
    endtask

    initial begin
        $display("===== Iniciando testes do control_unit =====\n");

        // ===== R-Type =====
        $display("--- R-Type (add, sub, and, or, xor, sll, srl, sra, slt, sltu) ---");
        // add x3, x4, x5 -> funct7=0000000, rs2=00101, rs1=00100, funct3=000, rd=00011, opcode=0110011
        check_instruction(32'h005201B3, 1'b1, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b0, 1'b0, "add x3, x4, x5");
        // sub x6, x7, x8 -> funct7=0100000, rs2=01000, rs1=00111, funct3=000, rd=00110, opcode=0110011
        check_instruction(32'h40838333, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SUB, 1'b0, 1'b0, 1'b0, "sub x6, x7, x8");
        // and x9, x10, x11 -> funct7=0000000, rs2=01011, rs1=01010, funct3=111, rd=01001, opcode=0110011
        check_instruction(32'h00b574b3, 1'b1, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 1'b0, "and x9, x10, x11");
        // or x12, x13, x14 -> funct7=0000000, rs2=01110, rs1=01101, funct3=110, rd=01100, opcode=0110011
        check_instruction(32'h00e6e633, 1'b1, 1'b0, 1'b0, 1'b0, ALU_OR,  1'b0, 1'b0, 1'b0, "or x12, x13, x14");
        // xor x15, x16, x17 -> funct7=0000000, rs2=10001, rs1=10000, funct3=100, rd=01111, opcode=0110011
        check_instruction(32'h011847b3, 1'b1, 1'b0, 1'b0, 1'b0, ALU_XOR, 1'b0, 1'b0, 1'b0, "xor x15, x16, x17");
        // sll x18, x19, x20 -> funct7=0000000, rs2=10100, rs1=10011, funct3=001, rd=10010, opcode=0110011
        check_instruction(32'h01499933, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SLL, 1'b0, 1'b0, 1'b0, "sll x18, x19, x20");
        // srl x21, x22, x23 -> funct7=0000000, rs2=10111, rs1=10110, funct3=101, rd=10101, opcode=0110011
        check_instruction(32'h017b5ab3, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SRL, 1'b0, 1'b0, 1'b0, "srl x21, x22, x23");
        // sra x24, x25, x26 -> funct7=0100000, rs2=11010, rs1=11001, funct3=101, rd=11000, opcode=0110011
        check_instruction(32'h41ad5c33, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SRA, 1'b0, 1'b0, 1'b0, "sra x24, x25, x26");
        // slt x27, x28, x29 -> funct7=0000000, rs2=11101, rs1=11100, funct3=010, rd=11011, opcode=0110011
        check_instruction(32'h01ce2db3, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SLT, 1'b0, 1'b0, 1'b0, "slt x27, x28, x29");
        // sltu x30, x31, x1 -> funct7=0000000, rs2=00001, rs1=11111, funct3=011, rd=11110, opcode=0110011
        check_instruction(32'h0013bf33, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SLTU, 1'b0, 1'b0, 1'b0, "sltu x30, x31, x1");

        // ===== I-Type =====
        $display("\n--- I-Type (addi, andi, ori, xori, slli, srli, srai, slti, sltiu) ---");
        // addi x3, x4, 100 -> imm=0000000100, rs1=00100, funct3=000, rd=00011, opcode=0010011
        check_instruction(32'h06420193, 1'b1, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b0, "addi x3, x4, 100");
        // andi x5, x6, -1 -> imm=111111111111, rs1=00110, funct3=111, rd=00101, opcode=0010011
        check_instruction(32'hfff37293, 1'b1, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b1, 1'b0, 1'b0, "andi x5, x6, -1");
        // ori x7, x8, 256 -> imm=010000000000, rs1=01000, funct3=110, rd=00111, opcode=0010011
        check_instruction(32'h40046393, 1'b1, 1'b0, 1'b0, 1'b0, ALU_OR,  1'b1, 1'b0, 1'b0, "ori x7, x8, 256");
        // xori x9, x10, 50 -> imm=0000110010, rs1=01010, funct3=100, rd=01001, opcode=0010011
        check_instruction(32'h03254493, 1'b1, 1'b0, 1'b0, 1'b0, ALU_XOR, 1'b1, 1'b0, 1'b0, "xori x9, x10, 50");
        // slli x11, x12, 3 -> funct7=0000000, shamt=00011, rs1=01100, funct3=001, rd=01011, opcode=0010011
        check_instruction(32'h00361593, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SLL, 1'b1, 1'b0, 1'b0, "slli x11, x12, 3");
        // srli x13, x14, 2 -> funct7=0000000, shamt=00010, rs1=01110, funct3=101, rd=01101, opcode=0010011
        check_instruction(32'h00275693, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SRL, 1'b1, 1'b0, 1'b0, "srli x13, x14, 2");
        // srai x15, x16, 4 -> funct7=0100000, shamt=00100, rs1=10000, funct3=101, opcode=0010011
        check_instruction(32'h40425693, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SRA, 1'b1, 1'b0, 1'b0, "srai x15, x16, 4");
        // slti x17, x18, 10 -> imm=0000001010, rs1=10010, funct3=010, rd=10001, opcode=0010011
        check_instruction(32'h00a92993, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SLT, 1'b1, 1'b0, 1'b0, "slti x17, x18, 10");
        // sltiu x19, x20, -5 -> imm=111111011, rs1=10100, funct3=011, rd=10011, opcode=0010011
        check_instruction(32'hffb7b993, 1'b1, 1'b0, 1'b0, 1'b0, ALU_SLTU, 1'b1, 1'b0, 1'b0, "sltiu x19, x20, -5");

        // ===== I-Type LOAD =====
        $display("\n--- I-Type LOAD (lw, lh, lb, lhu, lbu) ---");
        // lw x3, 0(x4) -> imm=0, rs1=00100, funct3=010, rd=00011, opcode=0000011
        check_instruction(32'h00022183, 1'b1, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b1, "lw x3, 0(x4)");
        // lh x5, 4(x6) -> imm=4, rs1=00110, funct3=001, rd=00101, opcode=0000011
        check_instruction(32'h00431283, 1'b1, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b1, "lh x5, 4(x6)");
        // lb x7, 8(x8) -> imm=8, rs1=01000, funct3=000, rd=00111, opcode=0000011
        check_instruction(32'h00840383, 1'b1, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b1, "lb x7, 8(x8)");
        // lhu x9, 2(x10) -> imm=2, rs1=01010, funct3=101, rd=01001, opcode=0000011
        check_instruction(32'h00255483, 1'b1, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b1, "lhu x9, 2(x10)");
        // lbu x11, 1(x12) -> imm=1, rs1=01100, funct3=100, rd=01011, opcode=0000011
        check_instruction(32'h0012c583, 1'b1, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b1, "lbu x11, 1(x12)");

        // ===== S-Type STORE =====
        $display("\n--- S-Type STORE (sw, sh, sb) ---");
        // sw x5, 0(x6) -> imm[11:5]=0, rs2=00101, rs1=00110, funct3=010, imm[4:0]=0, opcode=0100011
        check_instruction(32'h00532023, 1'b1, 1'b1, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b0, "sw x5, 0(x6)");
        // sh x7, 4(x8) -> imm[11:5]=0, rs2=00111, rs1=01000, funct3=001, imm[4:0]=00100, opcode=0100011
        check_instruction(32'h00741223, 1'b1, 1'b1, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b0, "sh x7, 4(x8)");
        // sb x9, 2(x10) -> imm[11:5]=0, rs2=01001, rs1=01010, funct3=000, imm[4:0]=00010, opcode=0100011
        check_instruction(32'h00950123, 1'b1, 1'b1, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b0, 1'b0, "sb x9, 2(x10)");

        $display("\n===== Todos os testes passaram! =====");
        $finish;
    end    

endmodule