`timescale 1ns / 1ps

module PC(
    input   logic clk_i,
    input   logic rst_ni,
    input   logic [31:0] pc_next,
    output  logic [31:0] PC
);
    
    /*initial begin
        PC <= 32'h80000000;
    end */
    
    always_ff @(posedge clk_i) begin
        if(!rst_ni)
            PC <= 32'h80000000;
        else
            PC <= pc_next;
    end
endmodule