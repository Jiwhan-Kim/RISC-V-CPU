`timescale 1ns / 1ps

module SC_RISCV_32I(
    input clk, rst, pc_en
);

// PC
reg  [7:0]  PC;
wire [7:0]  pc_4;
wire [7:0]  pc_next;
wire [7:0]  pc_branch;

assign pc_4    = stall ? (PC) : (PC + 8'h4);
assign pc_next = (!stall & branch) ? pc_branch : pc_4;

always @(posedge clk) begin
    if (rst) begin
        PC <= 0;
    end
    else if (pc_en) begin
        PC <= pc_next;
    end
end

// Finish Testbench
always @(posedge clk) begin
    if (pc_next == 8'b0) begin
        #10
        $finish;
    end
end

always @(posedge clk) begin
    if (pc_en && (pc_next === 8'hxx || pc_next === 8'hzz)) $finish;
end

// 01. Instruction Fetch
wire [31:0] Instruction;           // Instruction from Instruction Memory

// Connect Modules
Inst_Mem Inst_Mem(
    .PC             (PC), // Input PC (Program Counter)

    .instruction    (Instruction) // Output Instruction
);

// IF-ID Interstage
// Data
reg [31:0]  IF_ID_Instruction; // IF-ID Instruction
reg [7:0]   IF_ID_PC;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        IF_ID_Instruction[31:0] <= 32'b0;
        IF_ID_PC[7:0]           <= 8'b0;
    end
    else begin
        IF_ID_Instruction[31:0] <= Instruction[31:0];
        IF_ID_PC[7:0]           <= PC;
    end
end



// 02. Instruction Decode
// Data
wire [31:0] RD1, RD2;              // Register Data 1, 2
wire [31:0] Imm;                   // Immediate 

// Control Signals
wire        BrEq, BrLt;// Branch Output
wire        PCSel; // pc_next to 1 : ALU_result / 0 : pc_4
wire        RegWrite; // 1 : Read + Write on Register / 0 : Read Mode
wire        BrU; // 1 : Unsigned Branch / 0 : Signed Branch
wire [2:0]  ImmSel; // Immediate Select
wire [2:0]  DatasizeSel;
wire        ASel; // 1 : rd1 / 0 : PC
wire        Sel; // 1 : Imm / 0 : rd2
wire        MemRW; // 1 : Write Data on Memory / 0 : Read
wire [3:0]  ALUSel; // ALU Select
wire [1:0]  WBSel; // Write Back Select. 10, 11: Read_Data / 01: ALU_result / 00: pc_4
wire        stall; // Stall Pipeline
wire        branch; // Flush IF-ID Interstage Regiters

// Read Data from Register File
Register_File Reg_File(
    .clk        (clk),                      // Input Clock for Writing Data on Register
    .rst        (rst),                      // Input Reset
    .Read_Reg1  (IF_ID_Instruction[19:15]), // Input Instruction
    .Read_Reg2  (IF_ID_Instruction[24:20]), // Input Instruction
    .Write_Reg  (MEM_WB_RD[4:0]),           // Input Instruction
    .RegWrite   (MEM_WB_RegWrite),          // Input Register Write
    .Write_Data (WB[31:0]),                 // Input Write Back Data

    .Read_Data1 (RD1),                      // Output RD1 from RS1
    .Read_Data2 (RD2)                       // Output RD2 from RS2
);

// Immediate Generator
Imm_Gen Imm_Gen (
    .inst(IF_ID_Instruction[31:7]), // Input Instruction
    .ImmSel(ImmSel), // Input Immediate Select

    .Imm(Imm) // Output Immediate Value
);

// Branch Compare
Branch_Comp Br_Comp (
    .RD1(RD1),
    .RD2(RD2),
    .BrU(BrU),
    .BrEq(BrEq),
    .BrLt(BrLt)
);

// Control Unit
Main_Control Ctrl (
    .instruction(IF_ID_Instruction),
    .BrEq(BrEq),
    .BrLt(BrLt),

    .PCSel(PCSel),
    .RegWrite(RegWrite),
    .BrU(BrU),
    .ImmSel(ImmSel),
    .DatasizeSel(DatasizeSel),
    .ASel(ASel),
    .BSel(BSel),
    .MemRW(MemRW),
    .ALUSel(ALUSel),
    .WBSel(WBSel)
);

// Hazard Detection Unit
Hazard HazardDetect (
    .IF_ID_RS1(IF_ID_Instruction[19:15]), // RS1
    .IF_ID_RS2(IF_ID_Instruction[24:20]), // RS2
    .ID_EX_RD(ID_EX_RD),
    .DatasizeSel(DatasizeSel), // To Check Hazard when reading data

    .stall(stall)
);

Branch_Control Br_Ctrl (
    .PCSel(PCSel),
    .Imm(Imm),
    .IF_ID_PC(IF_ID_PC),

    .pc_branch(pc_branch), // Output PC_Branch Data
    .branch(branch)        // Output Branch Control Signal
);


// ID-EX Interstage
// Data
reg [4:0]   ID_EX_RS1, ID_EX_RS2, ID_EX_RD;
reg [31:0]  ID_EX_RD1, ID_EX_RD2;
reg [31:0]  ID_EX_Imm;
reg [7:0]   ID_EX_PC;

// Control Signals
reg         ID_EX_RegWrite; // 1 : Read + Write on Register / 0 : Read Mode
reg [2:0]   ID_EX_DatasizeSel;
reg         ID_EX_ASel; // 1 : rd1 / 0 : PC
reg         ID_EX_BSel; // 1 : Imm / 0 : rd2
reg         ID_EX_MemRW; // 1 : Write Data on Memory / 0 : Read
reg [3:0]   ID_EX_ALUSel; // ALU Select
reg [1:0]   ID_EX_WBSel; // Write Back Select. 10, 11: Read_Data / 01: ALU_result / 00: pc_4

always @(posedge clk or posedge rst) begin
    if (rst) begin
        ID_EX_RS1[4:0]  <= 5'b0;
        ID_EX_RS2[4:0]  <= 5'b0;
        ID_EX_RD[4:0]   <= 5'b0;
        ID_EX_RD1[31:0] <= 32'b0;
        ID_EX_RD2[31:0] <= 32'b0;
        ID_EX_Imm[31:0] <= 32'b0;
        ID_EX_PC[7:0]   <= 8'b0;

        ID_EX_RegWrite <= 1'b0;
        ID_EX_DatasizeSel[2:0] <= 3'b0;
        ID_EX_ASel <= 1'b0;
        ID_EX_BSel <= 1'b0;
        ID_EX_MemRW <= 1'b0;
        ID_EX_ALUSel[3:0] <= 4'b0;
        ID_EX_WBSel[1:0] <= 2'b0;
    end
    else begin
        ID_EX_RS1[4:0]  <= IF_ID_Instruction[19:15];
        ID_EX_RS2[4:0]  <= IF_ID_Instruction[24:20];
        ID_EX_RD [4:0]  <= IF_ID_Instruction[11:7];
        ID_EX_RD1[31:0] <= RD1[31:0];
        ID_EX_RD2[31:0] <= RD2[31:0];
        ID_EX_Imm[31:0] <= Imm[31:0];
        ID_EX_PC[7:0]   <= IF_ID_PC[7:0];

        if (!stall) begin // No Stall
            ID_EX_RegWrite <= RegWrite;
            ID_EX_DatasizeSel[2:0] <= DatasizeSel[2:0];
            ID_EX_ASel <= ASel;
            ID_EX_BSel <= BSel;
            ID_EX_MemRW <= MemRW;
            ID_EX_ALUSel[3:0] <= ALUSel[3:0];
            ID_EX_WBSel[1:0] <= WBSel[1:0];
        end
        else begin // Do Stall Cycle
            ID_EX_RegWrite <= 1'b0;
            ID_EX_DatasizeSel[2:0] <= 3'b0;
            ID_EX_ASel <= 1'b0;
            ID_EX_BSel <= 1'b0;
            ID_EX_MemRW <= 1'b0;
            ID_EX_ALUSel[3:0] <= 4'b0;
            ID_EX_WBSel[1:0] <= 2'b0;
        end
    end
end


// 03. Execute

// Data
wire [31:0] ALU_A, ALU_B;                                  // ALU Input
wire [31:0] ALU_result;                                    // ALU Result

// Control Signal
wire [1:0] Forward_ASel, Forward_BSel;

// ASel, BSel
assign ALU_A = Forward_ASel == 2'b11 ? MEM_WB_ALU_result :
               Forward_ASel == 2'b10 ? EX_MEM_ALU_result :
               Forward_ASel == 2'b01 ? ID_EX_RD1         :
                                       ID_EX_PC          ;

assign ALU_B = Forward_BSel == 2'b11 ? MEM_WB_ALU_result :
               Forward_BSel == 2'b10 ? EX_MEM_ALU_result :
               Forward_BSel == 2'b01 ? ID_EX_Imm         :
                                       ID_EX_RD2         ;

// ALU
ALU ALU(
    .A(ALU_A), // Input A
    .B(ALU_B), // Input B
    .ALUSel(ID_EX_ALUSel), // Input ALU Select

    .ALU_result(ALU_result) // Output ALU Result
);

// Forwarding Unit
assign Forward_ASel = (EX_MEM_RegWrite & (ID_EX_RS1 == EX_MEM_RD) & EX_MEM_RD != 5'b0) ? 2'b10 : // Forward from MEM
                      (MEM_WB_RegWrite & (ID_EX_RS1 == MEM_WB_RD) & MEM_WB_RD != 5'b0) ? 2'b11 : // Forward from WB
                      (ID_EX_ASel)                                                     ? 2'b01 : // RD1
                                                                                         2'b00 ; // PC
assign Forward_BSel = (EX_MEM_RegWrite & (ID_EX_RS2 == EX_MEM_RD) & EX_MEM_RD != 5'b0) ? 2'b10 : // Forward from MEM
                      (MEM_WB_RegWrite & (ID_EX_RS2 == MEM_WB_RD) & MEM_WB_RD != 5'b0) ? 2'b11 : // Forward from WB
                      (ID_EX_BSel)                                                     ? 2'b01 : // Imm
                                                                                         2'b00 ; // RD2

// EX-MEM Interstage
// Data
reg [4:0]   EX_MEM_RD;
reg [31:0]  EX_MEM_RD2;
reg [31:0]  EX_MEM_ALU_result;
reg [4:0]   EX_MEM_PC;

// Control Signal
reg         EX_MEM_RegWrite; // 1 : Read + Write on Register / 0 : Read Mode
reg [2:0]   EX_MEM_DatasizeSel;
reg         EX_MEM_MemRW; // 1 : Write Data on Memory / 0 : Read
reg [1:0]   EX_MEM_WBSel; // Write Back Select. 10, 11: Read_Data / 01: ALU_result / 00: pc_4

always @(posedge clk or posedge rst) begin
    if (rst) begin
        EX_MEM_RD[4:0]          <= 5'b0;
        EX_MEM_RD2[31:0]        <= 32'b0;
        EX_MEM_ALU_result[31:0] <= 32'b0;
        EX_MEM_PC[4:0]          <= 5'b0;

        EX_MEM_RegWrite         <= 1'b0;
        EX_MEM_DatasizeSel[2:0] <= 3'b0;
        EX_MEM_MemRW            <= 1'b0;
        EX_MEM_WBSel[1:0]       <= 2'b0;
    end
    else begin
        EX_MEM_RD[4:0]          <= ID_EX_RD;
        EX_MEM_RD2[31:0]        <= ID_EX_RD2;
        EX_MEM_ALU_result[31:0] <= ALU_result;
        EX_MEM_PC[4:0]          <= ID_EX_PC;

        EX_MEM_RegWrite         <= ID_EX_RegWrite;
        EX_MEM_DatasizeSel[2:0] <= ID_EX_DatasizeSel;
        EX_MEM_MemRW            <= ID_EX_MemRW;
        EX_MEM_WBSel[1:0]       <= ID_EX_WBSel;
    end
end


// 04. Read Data from Data Cache
// Data
wire [31:0] Read_Data;             // Read Data from Data Memory

// Control

Data_Mem Data_Mem(
    .clk(clk),
    .Address(EX_MEM_ALU_result),
    .WriteData(EX_MEM_RD2),
    .DatasizeSel(EX_MEM_DatasizeSel),
    .MemRW(EX_MEM_MemRW),

    .Read_Data(Read_Data) // Output when Read Data
);

// MEM-WB Interstage
// Data
reg [4:0]  MEM_WB_RD;
reg [31:0] MEM_WB_Read_Data;
reg [31:0] MEM_WB_ALU_result;
reg [4:0]  MEM_WB_PC;

// Control
reg         MEM_WB_RegWrite; // 1 : Read + Write on Register / 0 : Read Mode
reg [1:0]   MEM_WB_WBSel; // Write Back Select. 10, 11: Read_Data / 01: ALU_result / 00: pc_4

always @(posedge clk or posedge rst) begin
    if (rst) begin
        MEM_WB_RD[4:0]          <= 5'b0;
        MEM_WB_Read_Data[31:0]  <= 32'b0;
        MEM_WB_ALU_result[31:0] <= 32'b0;
        MEM_WB_PC[4:0]          <= 5'b0;

        MEM_WB_RegWrite         <= 1'b0;
        MEM_WB_WBSel[1:0]       <= 2'b0;
    end
    else begin
        MEM_WB_RD[4:0]          <= EX_MEM_RD[4:0];
        MEM_WB_Read_Data[31:0]  <= Read_Data;
        MEM_WB_ALU_result[31:0] <= EX_MEM_ALU_result;
        MEM_WB_PC[4:0]          <= MEM_WB_PC;

        MEM_WB_RegWrite         <= EX_MEM_RegWrite;
        MEM_WB_WBSel[1:0]       <= EX_MEM_WBSel;
    end

end


// 05. Write Back
// Data
wire [31:0] WB;      
assign WB = (MEM_WB_WBSel[1] == 1'b1) ? MEM_WB_Read_Data : (MEM_WB_WBSel[0] == 1'b1) ? MEM_WB_ALU_result : MEM_WB_PC;

endmodule