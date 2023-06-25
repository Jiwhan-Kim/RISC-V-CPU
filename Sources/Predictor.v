`timescale 1ns / 1ps

// Branch Target Buffer
module Predictor(
    input wire         clk,
    input wire         rst,
    
    input wire         stall,
    input wire         branch_indicator,
    input wire         branch, // Do Branch!
    input wire   [7:0] pc_branch,

    input wire   [7:0] PC,
    input wire   [7:0] IF_ID_PC,

    output wire        taken,
    output wire  [7:0] pc_predicted
);
    reg [7:0] Buffer [0:127];
    reg [1:0] Taken  [0:127]; // Store whether Branch was taken or not.

    assign taken             = Taken[PC >> 2][1];
    assign pc_predicted[7:0] = Buffer[PC >> 2][7:0];

    integer i;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 128; i = i + 1) begin
                Buffer[i] <= 8'b0;
                Taken[i]  <= 2'b1;
            end
        end
        else begin
            if (branch_indicator && (!stall)) begin
                if (branch) begin
                    $display("%h", pc_branch);
                    Buffer[IF_ID_PC >> 2] <= pc_branch;
                    Taken[IF_ID_PC >> 2]  <= (Taken[IF_ID_PC >> 2] != 2'b11) ? Taken[IF_ID_PC >> 2] + 1'b1 : 2'b11;
                end
                else begin
                    Buffer[IF_ID_PC >> 2] <= pc_branch;
                    Taken[IF_ID_PC >> 2]  <= (Taken[IF_ID_PC >> 2] != 2'b00) ? Taken[IF_ID_PC >> 2] - 1'b1 : 2'b00;
                end
            end
            else ;
        end
    end
    
endmodule