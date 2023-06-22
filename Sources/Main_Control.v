module Main_Control(
    input  [31:0] instruction, 
    input  BrEq, BrLt,
    output reg PCSel, RegWrite, BrU,
    output reg [2:0] ImmSel,
    output reg [2:0] DatasizeSel,
    output reg ASel, BSel, MemRW, 
    output reg [3:0] ALUSel,
    output reg [1:0] WBSel,
    output reg       branch_indicator
);

always@(*) begin
    case (instruction[6] == 1'b1)
        1'b1: begin  // UJ, I(jalr), SB Type Instructions
            /*
                For All Instructions, DatasizeSel. ALUSel are not needed. Set Value to 3'b111, 4'b0000.
                For some Instructions, MemRW, WBSel should be set as 1'b0, 2'b00. (Others do not need these).
            */
            DatasizeSel <= 3'b111; // No Needed
            MemRW <= 1'b0; // No Write on Memory Cache
            ALUSel <= 4'b0000; // No Needed
            WBSel <= 2'b00; // Write Back Sel to PC + 4 when needed.
            if (instruction[3] == 1'b1) begin
                // UJ (jal)
                PCSel <= 1'b1; // PC = PC + imm
                RegWrite <= 1'b1; // Store PC + 4 to Register
                BrU <= 1'b0; // No Needed
                ImmSel <= 3'b100;
                ASel <= 1'b0; // PC
                BSel <= 1'b1; // imm
                branch_indicator <= 1'b0;
            end else if (instruction[2] == 1'b1) begin
                // I (jalr)
                PCSel <= 1'b1; // PC = PC + imm
                RegWrite <= 1'b0; // No Need to write on Register
                BrU <= 1'b0; // No Needed
                ImmSel <= 3'b000;
                ASel <= 1'b1; // rs1
                BSel <= 1'b1; // imm
                branch_indicator <= 1'b0;
            end else if (instruction[2] == 1'b0) begin
                // SB Type Instructions
                RegWrite <= 1'b0; // No Need to write on Register
                BrU <= instruction[13]; // 1 (b**u) for unsigned, 0 (b**) for Signed Comparison
                ImmSel <= 3'b011;
                ASel <= 1'b0; // PC
                BSel <= 1'b1; // imm
                case ({instruction[14], instruction[12]})
                    2'b00: begin // beq
                        PCSel <= BrEq;
                    end
                    2'b01: begin // bne
                        PCSel <= !BrEq;
                    end
                    2'b10: begin // blt, bltu
                        PCSel <= BrLt;
                    end
                    2'b11: begin // bge, bgeu
                        PCSel <= !BrLt;
                    end
                endcase
                branch_indicator <= 1'b1;
            end else ;
        end
        1'b0: begin // I(load), S, I(immediate), R Type Instructions
            /*
                For All Instructions, BrU is not needed. Set Value to 1'b0.
                For All Instructions, PCSel, ASel should be set as 1'b0, 1'b1.
            */
            PCSel <= 1'b0; // PC = PC + 4
            BrU <= 1'b0; // No Needed
            ASel <= 1'b1; // rs1
            branch_indicator <= 1'b0;
            case (instruction[4])
                1'b0: begin // I(load), S Type Instructions
                    // instruction[5] I(load): 1'b0 / S: 1'b1
                    RegWrite <= !instruction[5]; // 1 (load) for Write, 0 (store) for Read
                    ImmSel <= (instruction[5]) ? 3'b001: 3'b000;
                    DatasizeSel <= instruction[14:12]; // FUNCT3 Responsible for the Size of Data
                    BSel <= 1'b1; // imm
                    MemRW <= instruction[5]; // 0 (load) for Read, 1 (store) for Write
                    ALUSel <= 4'b0000; // No ALU Operation
                    WBSel <= 2'b10; // Used for S Type Instructions
                end
                1'b1: begin // I(immediate), R Type Instructions
                    // instruction[5] I(immediate): 1'b0 / R: 1'b1
                    RegWrite <= 1; // 1 (I, R) for Write
                    ImmSel <= (instruction[5]) ? 3'b111 : (instruction[13:12] == 2'b01) ? 3'b010 : 3'b000;
                    DatasizeSel <= 3'b111; // No Data Size Selection
                    BSel <= !instruction[5]; // 1 (immediate) for imm, 0 (R) for rs2
                    MemRW <= 1'b0; // 0 (immediate, R) for Read
                    ALUSel[3] <= (instruction[5]) ? instruction[30] : (instruction[13:12] == 2'b01) ? instruction[30] : 1'b0;
                    ALUSel[2:0] <= instruction[14:12]; // FUNCT3 Responsible for ALU Operations
                    WBSel <= 2'b01; // 2'b01 (I, R) for ALU_result
                end
            endcase
        end
        default: ;
    endcase
end

endmodule