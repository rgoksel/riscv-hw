`timescale 1ns / 1ps

module mux_pcnext(
    input  logic         PC_Src,
    input  logic  [31:0] PC_plus4,
    input  logic  [31:0] PC_target,
    output logic  [31:0] PC_next
    );
    assign PC_next = PC_Src ? PC_target : PC_plus4;
endmodule

module mux_Bin(
    input           ALU_Src,
    input [31:0]    RD_2,
    input [31:0]    Imm_Ext,
    output [31:0]   Src_B
    );
    assign Src_B = ALU_Src ? Imm_Ext : RD_2;
endmodule


module mux_result(
    input  [1:0]  Res_Src,
    input  [31:0] ALU_res,
    input  [31:0] read_data,
    input  [31:0] PC_plus4,
    input  [31:0] PC_target,
    output [31:0] Result
    );
    assign Result = (Res_Src == 2'b00) ? ALU_res   :
                    (Res_Src == 2'b01) ? read_data :
                    (Res_Src == 2'b10) ? PC_plus4  : 
                    (Res_Src == 2'b11) ? PC_target : 32'd0;
endmodule

module mux_jalr (
    input  [31:0]  rs1, 
    input  [31:0]  pc,
    input          pc_in_sel,
    output [31:0]  PC_in
);
    assign PC_in = pc_in_sel ? rs1 : pc;
endmodule