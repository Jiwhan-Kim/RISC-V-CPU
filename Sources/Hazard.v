module Hazard(
    input wire [4:0]    IF_ID_RS1,
    input wire [4:0]    IF_ID_RS2,
    input wire [4:0]    ID_EX_RD,
    input wire [2:0]    DatasizeSel,

    output wire     stall
);
    assign stall = (DatasizeSel != 3'b111) && ((ID_EX_RD == IF_ID_RS1) || (ID_EX_RD == IF_ID_RS2))  && ID_EX_RD != 5'b0 ? 1'b1 : 1'b0;
endmodule