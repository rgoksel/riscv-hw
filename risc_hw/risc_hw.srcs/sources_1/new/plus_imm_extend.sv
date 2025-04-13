`timescale 1ns / 1ps

module plus_imm_extend(
    input  logic  [31:0] PC,
    input  logic  [31:0] Imm_Ext,
    output logic  [31:0] PC_Target
);


    assign PC_Target = PC + Imm_Ext;

endmodule
