`timescale 1ns / 1ps

module Register_File(
    input logic clk_i, 
    input logic rst_ni,
    input logic we_i,
    input logic [31:0] data_in,
    input logic [4:0] addr1_r, addr2_r, addr3_w,
    output  logic [31:0] data_out_1, data_out_2
    );

    logic [31:0] reg_file [0:31];
    logic [5:0] i;
    
    assign data_out_1 = reg_file[addr1_r];
    assign data_out_2 = reg_file[addr2_r];
   
    always_ff @(negedge clk_i) begin
        if(!rst_ni) begin
            for (i = 0 ; i < 32 ; i = i +1) begin
                reg_file[i] <= 32'b0;
            end            
        end else begin
            if (we_i && addr3_w != 32'd0) begin
                reg_file[addr3_w] <= data_in;
            end
        end
    end
endmodule