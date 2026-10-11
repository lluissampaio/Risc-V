module alu_tb;
    logic [31:0] regA;
    logic [31:0] regB;
    logic [3:0] alu_op;
    logic [31:0] res;
    logic zero_flag;

    alu dut (
        .regA(regA),
        .regB(regB),
        .alu_op(alu_op),
        .res(res),
        .zero_flag(zero_flag)
    );

    task automatic check(input logic [31:0] a, b, expected_res,
                         input logic [3:0] op,
                         input logic expected_zero);
        begin
            regA = a;
            regB = b;
            alu_op = op;

            #1;

            if (res !== expected_res || zero_flag !== expected_zero) begin
                $error("FAIL op=%b a=%0d b=%0d -> got res=%0d zero=%b expected res=%0d zero=%b",
                       op, a, b, res, zero_flag, expected_res, expected_zero);
            end else begin
                $display("OK   op=%b a=%0d b=%0d -> res=%0d zero=%b",
                         op, a, b, res, zero_flag);
            end
        end
    endtask

    initial begin
        // ADD
        check(32'd5, 32'd10, 32'd15, 4'b0000, 1'b0);
        check(32'd0, 32'd0, 32'd0, 4'b0000, 1'b1);

        // SUB
        check(32'd10, 32'd5, 32'd5, 4'b0001, 1'b0);

        // AND
        check(32'd5, 32'd3, 32'd1, 4'b0010, 1'b0);

        // OR
        check(32'd5, 32'd2, 32'd7, 4'b0011, 1'b0);

        // XOR
        check(32'd5, 32'd3, 32'd6, 4'b0100, 1'b0);

        // SLL
        check(32'd5, 32'd2, 32'd20, 4'b0101, 1'b0);

        // SRL
        check(32'd8, 32'd2, 32'd2, 4'b0110, 1'b0);

        // SRA (signed)
        check(32'h80000000, 32'd1, 32'hC0000000, 4'b0111, 1'b0);

        // SLT (signed)
        check(32'd5, 32'd10, 32'd1, 4'b1000, 1'b0);

        // SLTU (unsigned)
        check(32'd5, 32'd10, 32'd1, 4'b1001, 1'b0);

        $display("All ALU tests passed.");
        $finish;
    end
endmodule