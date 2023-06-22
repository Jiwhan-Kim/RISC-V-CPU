module Branch_Comp(
    input [31:0] RD1, RD2,
    input BrU,
    output BrEq, BrLt
);

wire signed [31:0] RD1_signed, RD2_signed;

assign RD1_signed = RD1;
assign RD2_signed = RD2;

assign BrEq = RD1 == RD2;
assign BrLt = (BrU) ? RD1 < RD2 : RD1_signed < RD2_signed;

endmodule