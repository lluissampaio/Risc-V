module shiftreg #(parameter int N = 8)(
    input logic clk,
    input logic rst,
    input logic data_in,
    output logic[N-1:0] data_out
);

    always_ff @(posedge clk, posedge rst)
        if (rst) data_out <= '0;
        else data_out <= {data_out[N-2:0],data_in};

endmodule