module program_counter_tb;
	logic        clk;
	logic        reset;
	logic [31:0] pc_next;
	logic [31:0] pc;

	program_counter dut (
		.clk(clk),
		.reset(reset),
		.pc_next(pc_next),
		.pc(pc)
	);

	always #5 clk = ~clk;

	task automatic check_pc(
		input logic        reset_value,
		input logic [31:0] next_value,
		input logic [31:0] expected_value,
		input string       description
	);
		@(negedge clk);
		reset = reset_value;
		pc_next = next_value;
		@(posedge clk);
		#1;

		if (pc !== expected_value) begin
			$fatal(1, "FAIL: %s: pc=%h, esperado=%h",
				   description, pc, expected_value);
		end
		$display("PASS: %s", description);
	endtask

	initial begin
		clk = 1'b0;
		reset = 1'b0;
		pc_next = 32'b0;

		$display("===== Iniciando testes do program_counter =====");

		check_pc(1'b1, 32'h12345678, 32'h00000000,
				"reset zera o PC");
		check_pc(1'b0, 32'h00000100, 32'h00000100,
				"carrega o primeiro pc_next");
		check_pc(1'b0, 32'h00000104, 32'h00000104,
				"carrega pc_next no ciclo seguinte");
		check_pc(1'b1, 32'hdeadbeef, 32'h00000000,
				"reset tem prioridade sobre pc_next");

		@(negedge clk);
		reset = 1'b0;
		pc_next = 32'h00000200;
		@(posedge clk);
		#1;
		if (pc !== 32'h00000200) begin
			$fatal(1, "FAIL: carregamento após reset: pc=%h", pc);
		end
		$display("PASS: carregamento após reset");

		@(negedge clk);
		reset = 1'b1;
		pc_next = 32'hffffffff;
		#1;
		if (pc !== 32'h00000200) begin
			$fatal(1, "FAIL: reset deve ser síncrono, pc mudou antes do clock: %h", pc);
		end
		@(posedge clk);
		#1;
		if (pc !== 32'h00000000) begin
			$fatal(1, "FAIL: reset síncrono no flanco: pc=%h", pc);
		end
		$display("PASS: reset só atua no flanco de subida");

		$display("===== Todos os testes passaram! =====");
		$finish;
	end
endmodule
