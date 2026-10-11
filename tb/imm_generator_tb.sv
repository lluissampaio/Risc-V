module imm_generator_tb;
	logic [31:0] instr;
	logic [31:0] imm;

	imm_generator dut (
		.instr(instr),
		.imm(imm)
	);

	task automatic check_imm(
		input logic [31:0] instruction,
		input logic [31:0] expected,
		input string       description
	);
		instr = instruction;
		#1;

		if (imm !== expected) begin
			$fatal(1, "FAIL: %s: instr=%h imm=%h esperado=%h",
				   description, instruction, imm, expected);
		end
		$display("PASS: %s", description);
	endtask

	initial begin
		$display("===== Iniciando testes do imm_generator =====");

		check_imm(32'h06420193, 32'h00000064, "I-type positivo");
		check_imm(32'hfff37293, 32'hffffffff, "I-type negativo com extensao de sinal");
		check_imm(32'hfff2a103, 32'hffffffff, "load com imediato negativo");
		check_imm(32'h00532523, 32'h0000000a, "S-type com imediato 10");
		check_imm(32'h00000863, 32'h00000010, "B-type com deslocamento positivo");
		check_imm(32'hfe000ee3, 32'hfffffffc, "B-type com deslocamento negativo");
		check_imm(32'h123452b7, 32'h12345000, "U-type LUI");
		check_imm(32'h12345097, 32'h12345000, "U-type AUIPC");
		check_imm(32'h0080006f, 32'h00000008, "J-type com deslocamento positivo");
		check_imm(32'hffdff06f, 32'hfffffffc, "J-type com deslocamento negativo");
		check_imm(32'h00c100e7, 32'h0000000c, "JALR com imediato positivo");
		check_imm(32'hfff302e7, 32'hffffffff, "JALR com imediato negativo");
		check_imm(32'h00000013, 32'h00000000, "opcode desconhecido retorna zero");

		$display("===== Todos os testes passaram! =====");
		$finish;
	end
endmodule
