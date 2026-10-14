module control_unit_tb;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;
    logic       reg_write;
    logic       mem_write;
    logic       mem_read;
    logic [1:0] jump;
    logic [3:0] alu_op;
    logic       alu_src;
    logic [2:0] write_back;

    int passed = 0;

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .jump(jump),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .write_back(write_back)
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

    task automatic check_instruction(
        input logic [31:0] instr,
        input logic        exp_reg_write,
        input logic        exp_mem_write,
        input logic        exp_mem_read,
        input logic [1:0]  exp_jump,
        input logic [3:0]  exp_alu_op,
        input logic        exp_alu_src,
        input logic [2:0]  exp_write_back,
        input string       msg
    );
        begin
            opcode   = instr[6:0];
            funct3   = instr[14:12];
            funct7_5 = instr[30];
            #1;

            if (reg_write !== exp_reg_write || mem_write !== exp_mem_write ||
                mem_read !== exp_mem_read || jump !== exp_jump ||
                alu_op !== exp_alu_op || alu_src !== exp_alu_src ||
                write_back !== exp_write_back) begin
                $error("FAIL: %s", msg);
                $display("  instr = %h", instr);
                $display("  reg_write = %b (expected %b)", reg_write, exp_reg_write);
                $display("  mem_write = %b (expected %b)", mem_write, exp_mem_write);
                $display("  mem_read  = %b (expected %b)", mem_read, exp_mem_read);
                $display("  jump      = %b (expected %b)", jump, exp_jump);
                $display("  alu_op    = %b (expected %b)", alu_op, exp_alu_op);
                $display("  alu_src   = %b (expected %b)", alu_src, exp_alu_src);
                $display("  write_back= %b (expected %b)", write_back, exp_write_back);
                $finish;
            end else begin
                passed++;
                $display("PASS: %s (%h)", msg, instr);
            end
        end
    endtask

    initial begin
        $display("===== Iniciando testes do control_unit =====");

        // ===== R-Type (add, sub, and, or, xor, sll, srl, sra, slt, sltu) =====
        $display("\n--- R-Type (add, sub, and, or, xor, sll, srl, sra, slt, sltu) ---");
        // add x3, x4, x5
        check_instruction(32'h005201B3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b000, "add x3, x4, x5");
        // sub x6, x7, x8
        check_instruction(32'h40838333, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SUB, 1'b0, 3'b000, "sub x6, x7, x8");
        // and x9, x10, x11
        check_instruction(32'h00B574B3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_AND, 1'b0, 3'b000, "and x9, x10, x11");
        // or x12, x13, x14
        check_instruction(32'h00E6E633, 1'b1, 1'b0, 1'b0, 2'b00, ALU_OR, 1'b0, 3'b000, "or x12, x13, x14");
        // xor x15, x16, x17
        check_instruction(32'h011847B3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_XOR, 1'b0, 3'b000, "xor x15, x16, x17");
        // sll x18, x19, x20
        check_instruction(32'h01499933, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLL, 1'b0, 3'b000, "sll x18, x19, x20");
        // srl x21, x22, x23
        check_instruction(32'h017B5AB3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRL, 1'b0, 3'b000, "srl x21, x22, x23");
        // sra x24, x25, x26
        check_instruction(32'h41ACDC33, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRA, 1'b0, 3'b000, "sra x24, x25, x26");
        // slt x27, x28, x29
        check_instruction(32'h01DE2DB3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLT, 1'b0, 3'b000, "slt x27, x28, x29");
        // sltu x30, x31, x1
        check_instruction(32'h001FBF33, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLTU, 1'b0, 3'b000, "sltu x30, x31, x1");
        // add x1, x0, x0
        check_instruction(32'h000000B3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b000, "add x1, x0, x0");
        // sub x31, x30, x29
        check_instruction(32'h41DF0FB3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SUB, 1'b0, 3'b000, "sub x31, x30, x29");
        // sra x1, x2, x3
        check_instruction(32'h403150B3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRA, 1'b0, 3'b000, "sra x1, x2, x3");
        // srl x31, x31, x31
        check_instruction(32'h01FFDFB3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRL, 1'b0, 3'b000, "srl x31, x31, x31");
        // slt x5, x0, x5
        check_instruction(32'h005022B3, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLT, 1'b0, 3'b000, "slt x5, x0, x5");
        // sltu x0, x7, x8
        check_instruction(32'h0083B033, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLTU, 1'b0, 3'b000, "sltu x0, x7, x8");

        // ===== I-Type ALU (addi, andi, ori, xori, slli, srli, srai, slti, sltiu) =====
        $display("\n--- I-Type ALU (addi, andi, ori, xori, slli, srli, srai, slti, sltiu) ---");
        // addi x3, x4, 100
        check_instruction(32'h06420193, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "addi x3, x4, 100");
        // andi x5, x6, -1
        check_instruction(32'hFFF37293, 1'b1, 1'b0, 1'b0, 2'b00, ALU_AND, 1'b1, 3'b000, "andi x5, x6, -1");
        // ori x7, x8, 256
        check_instruction(32'h10046393, 1'b1, 1'b0, 1'b0, 2'b00, ALU_OR, 1'b1, 3'b000, "ori x7, x8, 256");
        // xori x9, x10, 50
        check_instruction(32'h03254493, 1'b1, 1'b0, 1'b0, 2'b00, ALU_XOR, 1'b1, 3'b000, "xori x9, x10, 50");
        // slli x11, x12, 3
        check_instruction(32'h00361593, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLL, 1'b1, 3'b000, "slli x11, x12, 3");
        // srli x13, x14, 2
        check_instruction(32'h00275693, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRL, 1'b1, 3'b000, "srli x13, x14, 2");
        // srai x15, x16, 4
        check_instruction(32'h40485793, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRA, 1'b1, 3'b000, "srai x15, x16, 4");
        // slti x17, x18, 10
        check_instruction(32'h00A92893, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLT, 1'b1, 3'b000, "slti x17, x18, 10");
        // sltiu x19, x20, -5
        check_instruction(32'hFFBA3993, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLTU, 1'b1, 3'b000, "sltiu x19, x20, -5");
        // addi x0, x0, 0
        check_instruction(32'h00000013, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "addi x0, x0, 0");
        // addi x1, x0, -1
        check_instruction(32'hFFF00093, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "addi x1, x0, -1");
        // addi x2, x0, 1024
        check_instruction(32'h40000113, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "addi x2, x0, 1024");
        // addi x3, x3, -2048
        check_instruction(32'h80018193, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "addi x3, x3, -2048");
        // addi x4, x5, 2047
        check_instruction(32'h7FF28213, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "addi x4, x5, 2047");
        // ori x6, x7, 1024
        check_instruction(32'h4003E313, 1'b1, 1'b0, 1'b0, 2'b00, ALU_OR, 1'b1, 3'b000, "ori x6, x7, 1024");
        // xori x8, x9, -1
        check_instruction(32'hFFF4C413, 1'b1, 1'b0, 1'b0, 2'b00, ALU_XOR, 1'b1, 3'b000, "xori x8, x9, -1");
        // slti x10, x11, -10
        check_instruction(32'hFF65A513, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLT, 1'b1, 3'b000, "slti x10, x11, -10");
        // slli x12, x13, 31
        check_instruction(32'h01F69613, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SLL, 1'b1, 3'b000, "slli x12, x13, 31");
        // srli x14, x15, 31
        check_instruction(32'h01F7D713, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRL, 1'b1, 3'b000, "srli x14, x15, 31");
        // srai x16, x17, 31
        check_instruction(32'h41F8D813, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRA, 1'b1, 3'b000, "srai x16, x17, 31");
        // srai x18, x18, 1
        check_instruction(32'h40195913, 1'b1, 1'b0, 1'b0, 2'b00, ALU_SRA, 1'b1, 3'b000, "srai x18, x18, 1");

        // ===== I-Type LOAD (lb, lh, lw, lbu, lhu) =====
        $display("\n--- I-Type LOAD (lb, lh, lw, lbu, lhu) ---");
        // lw x3, 0(x4)
        check_instruction(32'h00022183, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lw x3, 0(x4)");
        // lh x5, 4(x6)
        check_instruction(32'h00431283, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lh x5, 4(x6)");
        // lb x7, 8(x8)
        check_instruction(32'h00840383, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lb x7, 8(x8)");
        // lhu x9, 2(x10)
        check_instruction(32'h00255483, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lhu x9, 2(x10)");
        // lbu x11, 1(x12)
        check_instruction(32'h00164583, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lbu x11, 1(x12)");
        // lw x1, -4(x2)
        check_instruction(32'hFFC12083, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lw x1, -4(x2)");
        // lb x3, -1(x4)
        check_instruction(32'hFFF20183, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lb x3, -1(x4)");
        // lh x5, 2047(x6)
        check_instruction(32'h7FF31283, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lh x5, 2047(x6)");
        // lhu x7, -2048(x8)
        check_instruction(32'h80045383, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lhu x7, -2048(x8)");
        // lbu x0, 0(x9)
        check_instruction(32'h0004C003, 1'b1, 1'b0, 1'b1, 2'b00, ALU_ADD, 1'b1, 3'b001, "lbu x0, 0(x9)");

        // ===== S-Type STORE (sb, sh, sw) =====
        $display("\n--- S-Type STORE (sb, sh, sw) ---");
        // sw x5, 0(x6)
        check_instruction(32'h00532023, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sw x5, 0(x6)");
        // sh x7, 4(x8)
        check_instruction(32'h00741223, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sh x7, 4(x8)");
        // sb x9, 2(x10)
        check_instruction(32'h00950123, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sb x9, 2(x10)");
        // sw x1, -8(x2)
        check_instruction(32'hFE112C23, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sw x1, -8(x2)");
        // sb x3, -1(x4)
        check_instruction(32'hFE320FA3, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sb x3, -1(x4)");
        // sh x5, 2047(x6)
        check_instruction(32'h7E531FA3, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sh x5, 2047(x6)");
        // sw x31, -2048(x30)
        check_instruction(32'h81FF2023, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sw x31, -2048(x30)");
        // sb x0, 0(x0)
        check_instruction(32'h00000023, 1'b0, 1'b1, 1'b0, 2'b00, ALU_ADD, 1'b1, 3'b000, "sb x0, 0(x0)");

        // ===== B-Type (beq, bne, blt, bge, bltu, bgeu) =====
        $display("\n--- B-Type (beq, bne, blt, bge, bltu, bgeu) ---");
        // beq x5, x6, 8
        check_instruction(32'h00628463, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SUB, 1'b0, 3'b000, "beq x5, x6, 8");
        // bne x7, x8, 8
        check_instruction(32'h00839463, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SUB, 1'b0, 3'b000, "bne x7, x8, 8");
        // blt x9, x10, 8
        check_instruction(32'h00A4C463, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLT, 1'b0, 3'b000, "blt x9, x10, 8");
        // bge x11, x12, 8
        check_instruction(32'h00C5D463, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLT, 1'b0, 3'b000, "bge x11, x12, 8");
        // bltu x13, x14, 8
        check_instruction(32'h00E6E463, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLTU, 1'b0, 3'b000, "bltu x13, x14, 8");
        // bgeu x15, x16, 8
        check_instruction(32'h0107F463, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLTU, 1'b0, 3'b000, "bgeu x15, x16, 8");
        // beq x1, x2, -8
        check_instruction(32'hFE208CE3, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SUB, 1'b0, 3'b000, "beq x1, x2, -8");
        // bne x3, x4, -16
        check_instruction(32'hFE4198E3, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SUB, 1'b0, 3'b000, "bne x3, x4, -16");
        // blt x5, x6, -4
        check_instruction(32'hFE62CEE3, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLT, 1'b0, 3'b000, "blt x5, x6, -4");
        // bge x7, x8, 4094
        check_instruction(32'h7E83DFE3, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLT, 1'b0, 3'b000, "bge x7, x8, 4094");
        // bltu x9, x10, -4096
        check_instruction(32'h80A4E063, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLTU, 1'b0, 3'b000, "bltu x9, x10, -4096");
        // bgeu x11, x12, -2
        check_instruction(32'hFEC5FFE3, 1'b0, 1'b0, 1'b0, 2'b01, ALU_SLTU, 1'b0, 3'b000, "bgeu x11, x12, -2");

        // ===== J-Type and I-jump (jal, jalr) =====
        $display("\n--- J-Type and I-jump (jal, jalr) ---");
        // jal x1, 8
        check_instruction(32'h008000EF, 1'b1, 1'b0, 1'b0, 2'b10, ALU_ADD, 1'b0, 3'b010, "jal x1, 8");
        // jal x0, -16
        check_instruction(32'hFF1FF06F, 1'b1, 1'b0, 1'b0, 2'b10, ALU_ADD, 1'b0, 3'b010, "jal x0, -16");
        // jal x5, 2048
        check_instruction(32'h001002EF, 1'b1, 1'b0, 1'b0, 2'b10, ALU_ADD, 1'b0, 3'b010, "jal x5, 2048");
        // jal x31, -2
        check_instruction(32'hFFFFFFEF, 1'b1, 1'b0, 1'b0, 2'b10, ALU_ADD, 1'b0, 3'b010, "jal x31, -2");
        // jalr x1, x2, 4
        check_instruction(32'h004100E7, 1'b1, 1'b0, 1'b0, 2'b11, ALU_ADD, 1'b1, 3'b010, "jalr x1, x2, 4");
        // jalr x0, x1, 0
        check_instruction(32'h00008067, 1'b1, 1'b0, 1'b0, 2'b11, ALU_ADD, 1'b1, 3'b010, "jalr x0, x1, 0");
        // jalr x5, x6, -4
        check_instruction(32'hFFC302E7, 1'b1, 1'b0, 1'b0, 2'b11, ALU_ADD, 1'b1, 3'b010, "jalr x5, x6, -4");
        // jalr x31, x31, 2047
        check_instruction(32'h7FFF8FE7, 1'b1, 1'b0, 1'b0, 2'b11, ALU_ADD, 1'b1, 3'b010, "jalr x31, x31, 2047");

        // ===== U-Type (lui, auipc) =====
        $display("\n--- U-Type (lui, auipc) ---");
        // lui x5, 0x12345
        check_instruction(32'h123452B7, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b100, "lui x5, 0x12345");
        // auipc x6, 0x1
        check_instruction(32'h00001317, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b011, "auipc x6, 0x1");
        // lui x31, 0xFFFFF
        check_instruction(32'hFFFFFFB7, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b100, "lui x31, 0xFFFFF");
        // auipc x31, 0xFFFFF
        check_instruction(32'hFFFFFF97, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b011, "auipc x31, 0xFFFFF");
        // lui x0, 0x0
        check_instruction(32'h00000037, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b100, "lui x0, 0x0");
        // auipc x1, 0x80000
        check_instruction(32'h80000097, 1'b1, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b011, "auipc x1, 0x80000");

        // ===== Unsupported instructions: must behave like a nop (default values) =====
        $display("\n--- Unsupported (fence, ecall, ebreak, illegal) ---");
        // fence iorw, iorw
        check_instruction(32'h0FF0000F, 1'b0, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b000, "fence iorw, iorw");
        // ecall
        check_instruction(32'h00000073, 1'b0, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b000, "ecall");
        // ebreak
        check_instruction(32'h00100073, 1'b0, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b000, "ebreak");
        // all-zero word (illegal instruction)
        check_instruction(32'h00000000, 1'b0, 1'b0, 1'b0, 2'b00, ALU_ADD, 1'b0, 3'b000, "all-zero word (illegal instruction)");

        // ===== Invalid opcode: must keep the default values =====
        $display("\n--- Invalid opcode ---");
        opcode = 7'b1111111;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #1;
        if (reg_write !== 1'b0 || mem_write !== 1'b0 || mem_read !== 1'b0 ||
            jump !== 2'b00 || alu_op !== ALU_ADD || alu_src !== 1'b0 ||
            write_back !== 3'b000) begin
            $error("FAIL: invalid opcode should keep default values");
            $finish;
        end
        passed++;
        $display("PASS: invalid opcode defaults");

        $display("\n===== All tests passed! (%0d verifications) =====", passed);
        $finish;
    end
endmodule