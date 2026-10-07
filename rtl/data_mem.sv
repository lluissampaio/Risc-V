module data_mem( //leitura e escrita
    input logic clk,
    input logic mem_write,
    input logic [2:0] funct3,
    input logic [31:0] addr, 
    input logic [31:0] wd,
    output logic [31:0] rd
);

    logic [31:0] mem [0:1023];
    logic [7:0]  b;
    logic [15:0] h;
    logic [31:0] word;

    always_ff @(posedge clk) begin
        if (mem_write==1'b1) begin
            case (funct3)
                3'b000: //sb
                    begin
                    case (addr[1:0])
                        2'b00: mem[addr[31:2]][7:0] <= wd[7:0];
                        2'b01: mem[addr[31:2]][15:8] <= wd[7:0];
                        2'b10: mem[addr[31:2]][23:16] <= wd[7:0];
                        2'b11: mem[addr[31:2]][31:24] <= wd[7:0];
                    endcase
                    end
                3'b001: //sh
                    begin
                    case (addr[1])
                        1'b0: mem[addr[31:2]][15:0] <= wd[15:0];
                        1'b1: mem[addr[31:2]][31:16] <= wd[15:0];
                    endcase
                    end
                3'b010: mem[addr[31:2]] <= wd; //sw
                default: ;
            endcase
        end    
    end    

    always_comb begin
        word = mem[addr[31:2]];
        case (addr[1:0])
            2'b00: 
                begin 
                    b = word[7:0]; 
                    h = word[15:0];
                end
            2'b01: b = word[15:8];
            2'b10: 
                begin
                    b = word[23:16]; 
                    h = word[31:16];
                end
            2'b11: b = word[31:24];
        endcase    
        case (funct3)
            3'b000: rd = {{24{b[7]}},b};//lb
            3'b001: rd = {{16{h[15]}},h};//lh
            3'b010: rd = word;//lw
            3'b100: rd = {{24{1'b0}},b};//lbu
            3'b101: rd = {{16{1'b0}},h};//lhu
            default: rd = word;
        endcase
    end     

endmodule