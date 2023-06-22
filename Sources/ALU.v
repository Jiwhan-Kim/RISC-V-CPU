`timescale 1ns / 1ps

module ALU(
    input signed [31:0] A, B,
    input [3:0] ALUSel,
    output reg [31:0] ALU_result
);

// Declare wires for results of each operation type. And then select one of them as ALU_result.
wire [31:0] A_unsigned;
wire [31:0] B_unsigned;
assign A_unsigned = A;
assign B_unsigned = B;


always@ (*) begin
    case (ALUSel)
        4'b0000: ALU_result <= A + B; // add, addi
        4'b1000: ALU_result <= A - B; // sub
        
        4'b0001: ALU_result <= A << B; // sll, slli
        4'b0101: ALU_result <= A >> B; // srl, srli
        4'b1101: ALU_result <= A >>> B; // sra, srai
        
        4'b0010: ALU_result <= A < B; // slt, slti
        4'b0011: ALU_result <= A_unsigned < B_unsigned; // sltu, sltiu
        
        4'b0100: ALU_result <= A ^ B; // xor, xori
        4'b0110: ALU_result <= A | B; // or, ori
        4'b0111: ALU_result <= A & B; // and, andi
        default: ALU_result <= {32{1'b0}};
    endcase
end

endmodule