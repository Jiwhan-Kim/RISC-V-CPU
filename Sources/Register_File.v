module Register_File(
    input RegWrite, rst,
    input [4:0] Read_Reg1, Read_Reg2, Write_Reg,
    input [31:0] Write_Data,
    output [31:0] Read_Data1, Read_Data2
);

reg [31:0] Register_file [0:31];
integer i;
always @ (posedge RegWrite or posedge rst or Write_Data) begin
    if (rst) begin
        for (i = 0; i < 32; i = i + 1) begin
            Register_file[i] <= {32{1'b0}};
        end
    end
    else if (RegWrite && Write_Reg != 5'b0) begin
        Register_file[Write_Reg] <= Write_Data;
    end else begin
        Register_file[Write_Reg] <= Register_file[Write_Reg];
    end
end

// Register Read
assign Read_Data1 = Register_file[Read_Reg1];
assign Read_Data2 = Register_file[Read_Reg2];


endmodule