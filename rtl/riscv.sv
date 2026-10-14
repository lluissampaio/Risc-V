module riscv #( parameter PROGRAM_FILE = "tb/hex/program1.hex")(
    input logic clk,
    input logic reset
);
    
    // Outputs of Control Unit
    logic we;
    logic mem_write;
    logic mem_read;
    logic [1:0] jump;
    logic [3:0] alu_op;
    logic alu_src;
    logic [2:0] write_back;
    
    // Input and Output Program Counter
    logic [31:0] pc_next;
    logic [31:0] pc; 
    
    logic [31:0] instr; // Instruction Memory
    
    // Inputs and Outputs of Registers module
    logic [4:0]  rd, rs1, rs2; 
    logic [31:0] wd;
    logic [31:0] rd1,rd2;
    
    // Inputs and Outputs of alu module
    logic [31:0] regA, regB, result;
    logic zero;

    // Inputs and Output of RAM module
    logic [31:0] read_data;

    // Imm generator module
    logic [31:0] imm;

    logic [31:0] pc_4, pc_imm;

    assign regA = rd1;
    assign pc_4 = pc + 4;
    assign pc_imm = pc + imm;
    
    program_counter program_counter(clk,reset,pc_next,pc);
    instr_mem #(.PROGRAM_FILE(PROGRAM_FILE)) instr_mem(pc,instr);
    regfile regfile(clk, reset, we, instr[19:15], instr[24:20], instr[11:7], wd, rd1, rd2);
    control_unit control(instr[6:0],instr[14:12],instr[30], we, mem_write,mem_read, jump, alu_op,alu_src, write_back);
    alu alu(regA,regB,alu_op,result,zero);
    data_mem data_mem(clk,mem_write,mem_read,instr[14:12],result,rd2,read_data);
    imm_generator imm_generator(instr,imm); 
    jump_module jump_module(jump,zero,instr[14:12],pc_4,pc_imm,result,pc_next);
    
    mux2 AluSrc(rd2,imm,alu_src,regB);
    mux5 WriteBack(result,read_data,pc_4,pc_imm,imm,write_back,wd); 

endmodule