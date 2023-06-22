`timescale 1ns/1ps
`include "./Sources/ALU.v"
`include "./Sources/Branch_Comp.v"
`include "./Sources/Branch_Control.v"
`include "./Sources/Data_Mem.v"
`include "./Sources/Hazard.v"
`include "./Sources/Imm_Gen.v"
`include "./Sources/Inst_Mem.v"
`include "./Sources/Main_Control.v"
`include "./Sources/Register_File.v"
`include "./Sources/SC_RISCV_32I.v"

module tb();
    integer cnt;
    reg clk, rst, pc_en;

    initial begin
        // Initialize Instruction & Data Memory
        $readmemb("./binary.txt", RISCV.Inst_Mem.Instruction_Memory);
        // $readmemh("C:/Xilinx/Vivado/RISC_V_32I_verilog_assignment/img1_byte.txt", RISCV.Data_Mem.Data_Memory);  

        cnt = 0;
        clk = 1;
        rst = 1;
        pc_en = 0;
        
        #20
        rst = 0;
        #15
        pc_en = 1;
    end

    SC_RISCV_32I RISCV(
        clk, rst, pc_en
    );

    always #10 clk <= ~clk;

    always @(negedge clk) begin
        cnt <= cnt + 1'b1;
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, tb);
    end

endmodule


