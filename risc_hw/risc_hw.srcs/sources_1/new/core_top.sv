`timescale 1ns / 1ps

 module core_model #(
    parameter XLEN = 32,
    parameter DMemInitFile = "dmem.mem", 
    parameter IMemInitFile = "imem.mem" 
) 
(
    input clk_i, // input clock
    input rstn_i, // logic-0 asserted asynch reset
    input  logic  [XLEN-1:0] addr_i,      // memory adddres input for reading
    output logic  [XLEN-1:0] data_o,      // memory data output for reading
    output logic             update_o,    // retire signal
    output logic  [XLEN-1:0] pc_o,        // retired program counter
    output logic  [XLEN-1:0] instr_o,     // retired instruction
    output logic  [     4:0] reg_addr_o,  // retired register address
    output logic  [XLEN-1:0] reg_data_o,  // retired register data
    output logic  [XLEN-1:0] mem_addr_o,  // retired memory address
    output logic  [XLEN-1:0] mem_data_o,  // retired memory data
    output logic             mem_wrt_o   // retired memory write enable signal

); 

    logic  [31:0] instr_out;
/*    logic  [6:0] op_code = instr_out[6:0];
    logic  [2:0] func3 = instr_out[14:12];
    logic  [6:0] func7 = instr_out[31:25];*/
    
    logic [31:0] PC;
    logic [31:0] pc_next;
    
    logic [31:0] Result;
    /*logic [4:0] addr1_r = instr_out[19:15];
    logic [4:0] addr2_r = instr_out[24:20];
    logic [4:0] addr3_w = instr_out[11:7];*/
    logic [31:0] rd1, rd2, Src_B;
    
    logic zero, PC_src, we, u_s, reg_write;
    logic [1:0] Res_src;
    logic [3:0] ALU_Control;
    logic ALU_src;
    logic [3:0] wstrb, wstrb_load;
    logic [2:0] Imm_src;
    logic [1:0] zero_counter;
    
    logic [31:0] ALU_res;
    
    logic [31:0] Read_Data;
    
    logic [31:0] PC_plus4, PC_target;
    
    logic [31:0] Imm_Ext;
    
    logic [31:0] PC_in;
    logic pc_in_sel;
    
    
    assign pc_o = PC;
    assign instr_o = instr_out;
    assign mem_wrt_o = we;
    assign update_o = 1'b1; 
    assign reg_addr_o = (instr_out[6:0] == 7'b1100011 || instr_out[6:0] == 7'b0100011) ? 5'd0 : instr_out[11:7];
    assign reg_data_o = (instr_out[6:0] == 7'b1100011 || instr_out[6:0] == 7'b0100011) ? 32'd0 : (instr_out[11:7] == 0 ? ALU_res : Result);
    assign mem_addr_o = ALU_res;
    assign mem_data_o = rd2; //rd2

    //assign addr_i = 1;
    assign data_o = (addr_i == ALU_res) ? Read_Data : 32'b0;
    
    mux_pcnext mux_pcnexttt(
        .PC_Src(PC_src),
        .PC_plus4(PC_plus4),
        .PC_target(PC_target),
        .PC_next(pc_next)
    );
        
    PC pc(
        .clk_i(clk_i),
        .rst_ni(rstn_i),
        .pc_next(pc_next),
        .PC(PC)
    );
    
    instr_mem #(.w(32), .d(2000), .IMemInitFile(IMemInitFile) , .BASE_ADDR(32'h8000_0000)) i_mem(
        .addr_instr(PC),
        .instr_out(instr_out)
    );
    
    plus_four plusfour(
        .PC(PC),
        .PC_plus4(PC_plus4)
    );
    
    Register_File rf(
        .clk_i(clk_i), 
        .rst_ni(rstn_i),
        .we_i(reg_write),
        .data_in(Result),
        .addr1_r(instr_out[19:15]), 
        .addr2_r(instr_out[24:20]), 
        .addr3_w(instr_out[11:7]),
        .data_out_1(rd1), 
        .data_out_2(rd2)
    );
    
    control_unit cont_unit(
        .instr_i(instr_out),
        .zero(zero),
        .PC_src(PC_src),
        .Res_src(Res_src),
        .mem_write(we),
        .ALU_Control(ALU_Control),
        .u_s(u_s),
        .ALU_src(ALU_src),
        .wstrb(wstrb),
        .wstrb_load(wstrb_load),
        .Imm_src(Imm_src),
        .reg_write(reg_write),
        .zero_counter(zero_counter),
        .pc_in_sel(pc_in_sel)
    );
    
    immediate_extend extendd(
        .instr_i(instr_out), //12 bit imm
        .imm_src_i(Imm_src),
        .Imm_Ext_o(Imm_Ext) //sign extended imm
    );
    
    mux_Bin mux_b_in(
        .ALU_Src(ALU_src),
        .RD_2(rd2),
        .Imm_Ext(Imm_Ext),
        .Src_B(Src_B)
    );
    
    ALU alu(
        .A(rd1), 
        .B(Src_B),
        .op(ALU_Control),
        .u_s(u_s),
        //.zero_counter(zero_counter),
        .FU(ALU_res),
        .zero(zero)
    );
    
    plus_imm_extend plus_imm_nextt(
        .PC(PC_in),
        .Imm_Ext(Imm_Ext),
        .PC_Target(PC_target)
    );
    
    data_mem  #(.w(32), .d(1024), .DMemInitFile(DMemInitFile)) d_mem(
        .clk_i(clk_i),
        .data_in(rd2),
        .addr_in(ALU_res),
        .we_i(we),
        .wstrb_i(wstrb),
        .wstrb_load(wstrb_load),
        .data_out(Read_Data)
    );    
    
    mux_result mux_res(
        .Res_Src(Res_src),
        .ALU_res(ALU_res),
        .read_data(Read_Data),
        .PC_plus4(PC_plus4),
        .PC_target(PC_target),
        .Result(Result)
    );
    
    mux_jalr mux_j(
    .rs1(rd1), 
    .pc(PC),
    .pc_in_sel(pc_in_sel),//controlden pc_in_sel �?kcak
    .PC_in(PC_in)
    );
    

    /*integer Log_file;
    integer f;
    
    initial begin
        f = $fopen("a.txt");
        Log_file = $fopen(Log_file);
    end*/
    
    /*integer i = 0;
    
    always @(posedge clk) begin
        i = i + 1;
        $display("%d   0x%x (0x%x) x%d 0x%x", i , PC, instr_out, addr3_w, Result);
        $fwrite(Log_file, "0x%x (0x%x) x%d 0x%x\n", PC, instr_out, addr3_w, Result);
        //$fwrite(Log_file, "x%0d 0x%16h", rf_idx_dec, rf_data_hex); // log the register file writes
        //$fwrite(Log_file, "mem 0x%h 0x%h", dmem_idx_dec, dmem_data_hex); // log the data memory writes
    end*/
    //d�zeltt
endmodule
