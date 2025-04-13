`timescale 1ns / 1ps

module immediate_extend (
    input  logic [31:0] instr_i, //12 bit imm
    input  logic [2:0]  imm_src_i,
    output logic [31:0] Imm_Ext_o
);

    assign Imm_Ext_o = (imm_src_i == 3'b000) ? {{20{instr_i[31]}}, instr_i[31:20]}: 
                       (imm_src_i == 3'b001) ? {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]}:  //s typr
                       (imm_src_i == 3'b010) ? {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}: //b type
                       (imm_src_i == 3'b011) ? {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}: ////j typ //21 olabilir
                       (imm_src_i == 3'b100 || 3'b101) ? ({instr_i[31:12], 12'd0}) : 
                       32'd0; //auipc

endmodule
