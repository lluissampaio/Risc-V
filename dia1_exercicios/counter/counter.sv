module counter #(
    parameter int N = 4
) (
    input logic clk,
    input logic rst,
    output logic [N-1:0] count
    );
    
    always_ff @(posedge clk, posedge rst)
        if (rst) count <= 0;
        else     count <= count+1; 
    /* 
    Podemos imaginar count como Q de um flip-flop.
    A lógica combinacional calcula count + 1 e liga esse valor a D.
    No flanco de subida do clock, o flip-flop guarda D em count (Q).
    Se rst subir, count é posto a zero sem esperar pelo clock. 
    */
endmodule    