`timescale 1ns / 1ps

module plus_four(
    input  logic [31:0] PC,
    output logic [31:0] PC_plus4
);

    assign PC_plus4 = PC + 32'd4;

endmodule
