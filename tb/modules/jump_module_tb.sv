module jump_module_tb;
    logic [1:0] jump_control;
    logic       flag_zero;
    logic [2:0] funct3;
    logic [31:0] pc_4;
    logic [31:0] pc_imm;
    logic [31:0] alu_result;
    logic [31:0] pc_next;

    jump_module dut (
        .jump_control(jump_control),
        .flag_zero(flag_zero),
        .funct3(funct3),
        .pc_4(pc_4),
        .pc_imm(pc_imm),
        .alu_result(alu_result),
        .pc_next(pc_next)
    );

    task automatic check_case(
        input logic [1:0] jc,
        input logic [2:0] f3,
        input logic z,
        input logic [31:0] p4,
        input logic [31:0] pimm,
        input logic [31:0] alu,
        input logic [31:0] expected,
        input string desc
    );
        begin
            jump_control = jc;
            funct3 = f3;
            flag_zero = z;
            pc_4 = p4;
            pc_imm = pimm;
            alu_result = alu;
            #1;

            if (pc_next !== expected) begin
                $fatal(1, "FAIL: %s | expected=%h got=%h | jump=%b funct3=%b zero=%b", desc, expected, pc_next, jc, f3, z);
            end

            $display("PASS: %s", desc);
        end
    endtask

    initial begin
        $display("===== jump_module testbench =====");
        $display("===== Defined cases =====");

        // no jump / sequential
        check_case(2'b00, 3'b000, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "sequential pc + 4");

        // jal
        check_case(2'b10, 3'b000, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "jal -> pc_imm");

        // jalr
        check_case(2'b11, 3'b000, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000030, "jalr -> alu_result");

        // beq taken
        check_case(2'b01, 3'b000, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "beq taken");

        // beq not taken
        check_case(2'b01, 3'b000, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "beq not taken");

        // bne taken
        check_case(2'b01, 3'b001, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "bne taken");

        // bne not taken
        check_case(2'b01, 3'b001, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "bne not taken");

        // blt taken
        check_case(2'b01, 3'b100, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "blt taken");

        // blt not taken
        check_case(2'b01, 3'b100, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "blt not taken");

        // bge taken
        check_case(2'b01, 3'b101, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "bge taken");

        // bge not taken
        check_case(2'b01, 3'b101, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "bge not taken");

        // bltu taken
        check_case(2'b01, 3'b110, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "bltu taken");

        // bltu not taken
        check_case(2'b01, 3'b110, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "bltu not taken");

        // bgeu taken
        check_case(2'b01, 3'b111, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000020, "bgeu taken");

        // bgeu not taken
        check_case(2'b01, 3'b111, 1'b0, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "bgeu not taken");

        $display("===== Edge cases =====");

        // unknown funct3 in branch -> default -> pc_4
        check_case(2'b01, 3'b010, 1'b1, 32'h00000010, 32'h00000020, 32'h00000030, 32'h00000010, "branch with invalid funct3 -> pc_4");

        // boundary values
        check_case(2'b10, 3'b000, 1'b0, 32'hFFFFFFFF, 32'h7FFFFFFF, 32'h80000000, 32'h7FFFFFFF, "jal with maximum values");

        check_case(2'b11, 3'b000, 1'b0, 32'h00000000, 32'h00000000, 32'hFFFFFFFF, 32'hFFFFFFFE, "jalr with maximum alu_result (LSB cleared)");

        // same value for pc_4 and pc_imm
        check_case(2'b10, 3'b000, 1'b0, 32'h00001000, 32'h00001000, 32'h00002000, 32'h00001000, "jal when pc_imm == pc_4");

        // branch with zero_flag at boundary value
        check_case(2'b01, 3'b000, 1'b0, 32'h00000001, 32'h0000FFFF, 32'h00000000, 32'h00000001, "beq not taken with small values");

        $display("===== All tests passed =====");
        $finish;
    end
endmodule
