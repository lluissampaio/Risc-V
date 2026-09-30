module counter_tb; //declaração do módulo sem portos

    // declaração de sinais
    logic clk, rst;
    logic [3:0] count;

    // Instancia-se o DUT- Device under test
    counter #(.N(4)) dut (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    // Gerar o clock
    always begin // ou apenas always #5 clk = ~clk;
        #5; 
        clk = ~clk;
    end 
    // ou seja um ciclo de relogio vai ser 10 unidades de tempo
    
    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);
    end

    initial begin 
        clk = 0;
        rst = 1;
        #1;
        if (count !== 0)
            $fatal(1, "Reset falhou: count=%0d", count);
        
        repeat (3) @(posedge clk); //espera 3 rise do clock = 3 ciclos 
        #1; rst = 0;
        $display("tempo=%0t count=%0d", $time, count);

        repeat (5) begin //repete este bloco 5 vezes
            @(posedge clk);
            #1;                    // espera a atualização de count
            $display("tempo=%0t count=%0d", $time, count);
        end

        $finish;
    end
   
endmodule
