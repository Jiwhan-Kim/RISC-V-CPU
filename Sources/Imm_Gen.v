module Imm_Gen(
    input [31:7] inst,
    input [2:0] ImmSel,
    output reg [31:0] Imm
);
// Assign Immediate value according to the ImmSel signal (depending on instruction type)

always@(*) begin
    case (ImmSel)
        3'b000: begin
            Imm[11:0] <= inst[31:20];
            Imm[31:12] <= {20{inst[31]}}; // Sign Extension
        end
        3'b001: begin
            Imm[31:12] <= {30{inst[31]}};
            Imm[11:5] <= inst[31:25];
            Imm[4:0] <= inst[11:7];
        end
        3'b010: begin
            Imm[31:5] <= {27{1'b0}}; // No sign Extension (Always Unsigned)
            Imm[4:0] = inst[24:20];
        end
        3'b011: begin
            Imm[31:13] <= {29{inst[31]}};
            Imm[12] <= inst[31];
            Imm[11] <= inst[7];
            Imm[10:5] <= inst[30:25];
            Imm[4:1] <= inst[11:8];
            Imm[0] <= 1'b0;
        end
        3'b100: begin
            Imm[31:21] <= {11{inst[31]}};
            Imm[20] <= inst[31];
            Imm[19:12] <= inst[19:12];
            Imm[11] <= inst[20];
            Imm[10:1] <= inst[30:21];
            Imm[0] <= 0;
        end
        default: Imm <= {32{1'b0}};
    endcase
end

endmodule