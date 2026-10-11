module mux2(
    input logic[31:0] srcA, srcB,
    input logic sel,
    output logic[31:0] result
);
    assign result = sel ? srcB : srcA;
endmodule