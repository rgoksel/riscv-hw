`timescale 1ns / 1ps

module alu2(
    input  logic [31:0] A, B,
    input  logic [3:0]  op,
    input  logic        u_s,
    input  logic [1:0]  zero_counter,
    output logic [31:0] FU,
    output logic  zero
    );
        
    logic [31:0] au_out, logic_out, shifter_out, lzc_count;
    logic zero_au;
    
    Arithmetic_Unit au(
        .A_i(A), .B_i(B), .C_i(1'b0),
        .arith_op(op), .u_s(u_s),
        .Sum_o(au_out), .zero_au(zero_au)
    );
    
    Logic_Unit lu(
        .A_i(A), .B_i(B),
        .logic_op(op), .logic_out(logic_out)
    );
    
    Shifter_Unit su(
        .A_i(A), .B_i(B),
        .shifter_op(op), .shifter_out(shifter_out)
    );
    
    lzc lzc1(.zero_counter(zero_counter), .A(A), .lzc_count(lzc_count));
    
    always_comb begin
        case(op)
            4'b0000, 4'b0001, 4'b1110: FU = au_out;                   // ADD/SUB/LUI
            4'b0010, 4'b0100, 4'b0110: FU = shifter_out;              // SLL/SRL/SRA
            4'b1000, 4'b1010, 4'b1100: FU = logic_out;                // AND/XOR/OR
            4'b0011:                   FU = zero ? 32'd1 : 32'd0;  // SLT/SLTU
            4'b1111:                   FU = lzc_count;
            default:                   FU = 32'd0;
        endcase
    end
    
    assign zero = (op== 4'b0011 || op == 4'b0101 || op== 4'b0111 || op == 4'b1001 || op == 4'b1011) ? zero_au : 1'd0;  
endmodule

module lzc (
    input  logic  [1:0]  zero_counter,
    input  logic  [31:0] A,
    output logic  [31:0] lzc_count
);

always_comb begin
    case (zero_counter)
        2'b00: begin // Leading zero count (from MSB)
            lzc_count = 32;
            for (int i = 31; i >= 0; i--) begin
                if (A[i]) begin
                    lzc_count = 31 - i;
                    break;
                end
            end
        end    
        2'b01: begin // Trailing zero count (from LSB)
            lzc_count = 32;
            for (int i = 0; i < 32; i++) begin
                if (A[i]) begin
                    lzc_count = i;
                    break;
                end
            end
        end
        2'b10: begin // Population count (count 1's)
            lzc_count = 0;
            for (int i = 0; i < 32; i++) begin
                lzc_count += A[i];
            end
        end
        2'b11: begin // Undefined case, output 0
            lzc_count = 0;
        end
    endcase
end

endmodule


module Arithmetic_Unit(
    input [31:0]    A_i, B_i,
    input           C_i,
    input [3:0]     arith_op,
    input           u_s,
    output [31:0]   Sum_o,
    output          zero_au
    );
    
    logic [31:0] C;
    logic [31:0] B_has;
    logic [31:0] A_sel;
    
    assign B_has = arith_op[0] ? (~B_i + 1) : B_i;
    assign A_sel = (arith_op == 4'b1110) ? 32'd0 : A_i;
    
    genvar i;
    generate 
        for (i = 0; i < 32 ; i = i +1) begin
            if ( i == 0)
                full_adder fa_1(.A_i(A_sel[i]), .B_i(B_has[i]), .Cin(C_i),
                                .Sum(Sum_o[i]), .Cout(C[i]));
            else  if ( i > 0)
                full_adder fa_1(.A_i(A_sel[i]), .B_i(B_has[i]), .Cin(C[i-1]),
                                .Sum(Sum_o[i]), .Cout(C[i]));
        end
    endgenerate
    
    assign C_o = C[31];
    assign Overflow_o = C[31] ^ C[30];
    
    //zero flag olayi buraya eklenecek
    assign zero_au = (arith_op == 4'b0011 && u_s == 1) ? ((C_o == 1) ? 1 : 0) : //sltu
                     (arith_op == 4'b0101)             ? ((Sum_o == 32'd0) ? 1 : 0) : //eq
                     (arith_op == 4'b0111)             ? ((Sum_o != 32'd0) ? 1 : 0) : //not eq
                     (arith_op == 4'b1001 && u_s == 1) ? ((C_o == 1) ? 1 : 0) : // less
                     (arith_op == 4'b1011 && u_s == 1) ? ((C_o == 0) ? 1 : 0) : //grater
                     (arith_op == 4'b0011 && u_s == 0) ? (((Overflow_o == 0 && Sum_o[31] == 1) || (Overflow_o == 1 && Sum_o[31] == 0)) ? 1 :0 ): //slt
                     (arith_op == 4'b1001 && u_s == 0) ? (((Overflow_o == 0 && Sum_o[31] == 1) || (Overflow_o == 1 && Sum_o[31] == 0)) ? 1 :0 ): // less
                     (arith_op == 4'b1011 && u_s == 0) ? (((Overflow_o == 0 && Sum_o[31] == 0) || (Overflow_o == 1 && Sum_o[31] == 1)) ? 1 :0 ): //grater
                     0;   
endmodule

module full_adder (
    input  logic A_i, B_i, Cin,
    output logic Sum,  Cout
);
    assign Sum  =  A_i ^ B_i ^ Cin;
    assign Cout = (A_i & B_i) | (B_i & Cin) | (Cin & A_i);
    
endmodule

module Logic_Unit(
    input logic  [31:0]  A_i, B_i,
    input logic  [3:0]   logic_op,
    output logic [31:0]  logic_out
    );
    
    assign logic_out= (logic_op == 4'b1000)   ? A_i & B_i :
                      (logic_op == 4'b1010)   ? A_i ^ B_i :
                      (logic_op == 4'b1100)   ? A_i | B_i :
                      A_i;
endmodule

module Shifter_Unit(
    input  logic [31:0] A_i, B_i,
    input  logic [3:0]  shifter_op,
    output logic [31:0] shifter_out
    );
        
    localparam [1:0] SLL = 4'b0010, SRL = 4'b0100, SRA = 4'b0110;
                         
    always_comb begin
        case(shifter_op)
            SLL: shifter_out = A_i << B_i[4:0];   // SLL/SLLI
            SRL: shifter_out = A_i >> B_i[4:0];   // SRL/SRLI
            SRA: shifter_out = $signed(A_i) >>> B_i[4:0]; // SRA/SRAI
            default: shifter_out = A_i;
        endcase
    end
    
endmodule
