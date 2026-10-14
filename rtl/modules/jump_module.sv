module jump_module(
    input logic branch,
    input logic flag_zero,
    input logic [2:0] funct3,
    output logic pc_src
);
    always_comb begin 
        pc_src = 1'b0;
        if (branch) begin
            case (funct3)
                3'b000: pc_src = flag_zerp ? 1'b1 : 1'b0; //beq
                3'b001: pc_src = flag_zero ? 1'b0 : 1'b1; //bne
                3'b100: pc_src = flag_zero ? 1'b0 : 1'b1; //blt
                3'b101: pc_src = flag_zero ? 1'b1 : 1'b0;//bge
                3'b100: pc_src = flag_zero ? 1'b0 : 1'b1;//bltu
                3'b101: pc_src = flag_zero ? 1'b1 : 1'b0;//bgeu
                default: ;
            endcase    
        end else pc_src = 0;    
    end

endmodule