module Data_Mem(
    input clk,
    input [31:0] Address, WriteData,
    input [2:0] DatasizeSel,
    input MemRW,
    output reg [31:0] Read_Data
);

reg [7:0] Data_Memory [0:256*4];

always @ (posedge clk) begin // Write Data on Memory sensitive to clock
    if (MemRW) begin
        case (DatasizeSel)
            3'b000: begin
                Data_Memory[Address] <= WriteData[7:0];
            end
            3'b001: begin
                Data_Memory[Address + 1] <= WriteData[15:8];
                Data_Memory[Address] <= WriteData[7:0];
            end
            3'b010: begin
                Data_Memory[Address + 3] <= WriteData[31:24];
                Data_Memory[Address + 2] <= WriteData[23:16];
                Data_Memory[Address + 1] <= WriteData[15:8];
                Data_Memory[Address] <= WriteData[7:0];
            end
            default: ;
        endcase
    end
end

always@(*) begin // Read Data on Memory not sensitive to clock
    case (DatasizeSel[1:0])
        2'b00: begin
            Read_Data[7:0] = Data_Memory[Address];
            Read_Data[31:8] = (!DatasizeSel[2] & Read_Data[7]) ? {24{1'b1}}: {24{1'b0}};
        end
        2'b01: begin
            Read_Data[15:8] = Data_Memory[Address + 1];
            Read_Data[7:0] = Data_Memory[Address];
            Read_Data[31:16] = (!DatasizeSel[2] & Read_Data[15]) ? {16{1'b1}}: {16{1'b0}};
        end
        2'b10: begin
            Read_Data[31:24] = Data_Memory[Address + 3];
            Read_Data[23:16] = Data_Memory[Address + 2];
            Read_Data[15:8] = Data_Memory[Address + 1];
            Read_Data[7:0] = Data_Memory[Address];
        end
        default: Read_Data[31:0] = 32'b0;
    endcase
    
end


endmodule
