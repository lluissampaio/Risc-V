module mux5(
    input logic[31:0] srcA, srcB, srcC, srcD, srcE,
    input logic[2:0] sel,
    output logic[31:0] result
);
    
    always_comb begin    
        case (sel)
            3'b000: result = srcA;
            3'b001: result = srcB;
            3'b010: result = srcC;
            3'b011: result = srcD;
            3'b100: result = srcE;
            default: result = srcA;
        endcase
    end
endmodule