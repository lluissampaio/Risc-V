module shiftreg_tb;

    logic clk, rst, data_in;
    logic [7:0] data_out;

    shiftreg #(.N(8)) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0; rst = 1; data_in = 0;
    end
    
    always #5 clk = ~clk;

    initial begin
        @(posedge clk)
        #1;
        if (data_out !== 0)
            $fatal(1,"Reset falhou: data_out= %0b", data_out);

        rst=0;
        data_in = 1;
        repeat (8) begin
            @(posedge clk);
            #1;
            $display("data_out = %08b", data_out);
        end
    
        if (data_out !== 8'b11111111)
            $fatal(1,"Shift falhou: data_out= %08b", data_out);

        data_in = 0;
        repeat (8) begin
            @(posedge clk);
            #1;
            $display("data_out = %08b", data_out);
        end
        
        if (data_out !== 8'b0)
            $fatal(1,"Shift falhou: data_out= %08b", data_out);
        
        $finish;
    
    end

endmodule