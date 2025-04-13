`timescale 1ns / 1ps

module data_mem  #(parameter DMemInitFile = "dmem.mem", 
                   parameter w = 32, d = 1024, d_bit = $clog2(d),
                   parameter BASE_ADDR = 32'h8000_0000)(
    input  logic clk_i,
    input  logic we_i,
    input  logic [31:0] data_in,
    input  logic [31:0] addr_in,
    input  logic [3:0]  wstrb_i,
    input  logic [3:0]  wstrb_load,
    output logic [31:0] data_out,
    
    input logic address_son,
    output logic data_son
    );
    
    logic [w-1:0] data_mem [0:d];
    
    integer i;
    initial begin
        for(i = 0; i < 1024; i = i + 1) begin
            data_mem[i] = 32'b0;
        end
        //$readmemh(DMemInitFile, data_mem);
    end
    
    logic [9:0] address;

    //logic [31:0] offset = (addr_in - BASE_ADDR) >> 2;
    
    always_ff @(posedge clk_i) begin
        if (we_i) begin
            if (wstrb_i == 4'b0001)
                data_mem[address][7:0] <= data_in[7:0]; 
            else if (wstrb_i == 4'b0011)
                data_mem[address][15:0] <= data_in[15:0];
            else if (wstrb_i == 4'b1111)
                data_mem[address] <= data_in; 
            else
                data_mem[address] <= data_in; 
        end
     end
     
       
     always_comb begin
          if(wstrb_load == 4'b0001)
              data_out <= {{24{data_mem[address][31]}},data_mem[address][7:0]};
          if(wstrb_load == 4'b0011)
              data_out <= {{16{data_mem[address][31]}},data_mem[address][15:0]};
          if(wstrb_load == 4'b1111)
              data_out <= data_mem[address];
          if(wstrb_load == 4'b1001)
              data_out <= {24'd0,data_mem[address][7:0]};
          if(wstrb_load == 4'b1011)
              data_out <= {16'd0,data_mem[address][15:0]};
          
         address = (addr_in - BASE_ADDR) >> 2;
     end
     
     assign data_son = data_mem[address_son];

endmodule