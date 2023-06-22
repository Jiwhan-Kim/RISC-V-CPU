module Inst_Mem(
    input [7:0] PC,
    output [31:0] instruction
);

reg [31:0] Instruction_Memory [0:127];

// Instruction Fetch
assign instruction = Instruction_Memory[PC>>>2];

endmodule
