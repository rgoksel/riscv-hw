`timescale 1ns / 1ps

module instr_mem #(parameter IMemInitFile = "imem.mem",
                   parameter w = 32, d = 2000,
                   parameter BASE_ADDR = 32'h8000_0000)(
    input  logic [31:0] addr_instr,
    output logic [31:0] instr_out
);
    
    logic [w-1:0] instr_mem [0:d];
    
    initial begin
        $readmemh("imem.mem", instr_mem);
    end
    
    logic [31:0] address;
    
    assign address = (addr_instr - BASE_ADDR)>> 2;
    assign instr_out =  instr_mem[address];
    
 
endmodule
