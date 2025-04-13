`timescale 1ns / 1ps

module control_unit(
    input logic [31:0]  instr_i,
    input logic         zero,
    output              PC_src,
    output logic [1:0]  Res_src,
    output logic        mem_write,
    output logic [3:0]  ALU_Control,
    output logic        u_s,
    output logic        ALU_src,
    output logic [3:0]  wstrb,
    output logic [3:0]  wstrb_load,
    output logic [2:0]  Imm_src,
    output logic        reg_write,
    output logic [1:0]  zero_counter,
    output logic        pc_in_sel
    );
    
    logic [6:0] op_code;
    logic [2:0] func3;
    logic [6:0] func7;
    
    assign op_code  = instr_i[6:0];
    assign func3    = instr_i[14:12];
    assign func7    = instr_i[31:25];
    
    wire branch, jump;
    wire [1:0] ALU_op;
    
    main_decoder md(
        .op_code(op_code), .func3(func3), .Res_src(Res_src), .mem_write(mem_write), .ALU_src(ALU_src), .Imm_src(Imm_src),
        .wstrb(wstrb), .wstrb_load(wstrb_load), .reg_write(reg_write), .branch(branch), .jump(jump), .ALU_op(ALU_op), .pc_in_sel(pc_in_sel)
    );
    
    ALU_decoder ad(
        .ALU_op(ALU_op), .op_code(op_code),  .func3(func3),
        .func7(func7), .ALU_control(ALU_Control), .u_s(u_s)
    );
    
    always_comb begin
        if (ALU_op == 2'b10 && func3 == 3'b001 && func7[5] == 1)
            zero_counter = instr_i[21:20];
        else
            zero_counter = 2'b11;
        end
    assign PC_src = (zero & branch) | jump;
    
endmodule


module main_decoder (
    input  logic [6:0]  op_code,
    input  logic [2:0]  func3,
    output logic [1:0]  Res_src,
    output logic        mem_write,
    output logic        ALU_src,
    output logic [2:0]  Imm_src,
    output logic [3:0]  wstrb,
    output logic [3:0]  wstrb_load,
    output logic        reg_write,
    output logic        branch,
    output logic        jump,
    output logic [1:0]  ALU_op,
    output logic        pc_in_sel
);    

    localparam [6:0] 
         LOAD       = 7'b0000011,
         ALU_i      = 7'b0010011, 
         AUIPC      = 7'b0010111, 
         LUI        = 7'b0110111,
         STORE      = 7'b0100011, 
         ALU        = 7'b0110011, 
         BRANCH_OP  = 7'b1100011, 
         JALR       = 7'b1100111, 
         JAL        = 7'b1101111;
         
    assign mem_write = (op_code  == STORE )     ? 1 : 0;
    assign branch    = (op_code  == BRANCH_OP)  ? 1 : 0;
    assign pc_in_sel = (op_code  == JALR)       ? 1 : 0 ;  
    
    assign reg_write = (op_code  == STORE || op_code == BRANCH_OP) ? 0 : 1;
    assign jump      = (op_code  == JAL   ||  op_code == JALR)     ? 1 : 0;
    assign wstrb     = (op_code  == STORE)? (func3 == 3'b000 ? 4'b0001 : 
                                            (func3 == 3'b001 ? 4'b0011 : 4'b1111)) : 
                                            4'b1111;
                     
    always_comb begin
        case (op_code)
            LOAD: begin
                Res_src     = 2'b01;
                ALU_src     = 1'b1;
                Imm_src     = 3'b000;
                ALU_op      = 2'b00;
                case (func3)
                    3'b000:  wstrb_load = 4'b0001;  // LB
                    3'b001:  wstrb_load = 4'b0011;  // LH
                    3'b010:  wstrb_load = 4'b1111;  // LW
                    3'b100:  wstrb_load = 4'b1001;  // LBU
                    3'b101:  wstrb_load = 4'b1011;  // LHU
                    default: wstrb_load = 4'b1111;
                endcase
            end
            ALU_i: begin
                Res_src     = 2'b00;
                ALU_src     = 1'b1;
                Imm_src     = 3'b000; 
                ALU_op      = 2'b10; //Alu operasyolari i�in ama lw, sw, veya branch_rler yok
                wstrb_load  = 4'b1111;
            end
            AUIPC: begin
                Res_src     = 2'b11;
                ALU_src     = 1'b0;
                Imm_src     = 3'b100;
                ALU_op      = 2'b00; //xx aslinda kullanmicam 
                wstrb_load  = 4'b1111;
            end
            LUI: begin
                Res_src     = 2'b00;
                ALU_src     = 1'b1;
                Imm_src     = 3'b101;
                ALU_op      = 2'b10; //aluya gidiyo for toplama 
                wstrb_load  = 4'b1111;
            end
            STORE: begin
                Res_src     = 2'b00;
                ALU_src     = 1'b1;
                Imm_src     = 3'b001;
                ALU_op      = 2'b00; //alu store
                wstrb_load  = 4'b1111;
            end
            ALU: begin
                ALU_src     = 1'b0;
                Res_src     = 2'b00;
                ALU_op      = 2'b10; //alu
                Imm_src     = 3'b000; //3'bxxx aslinda kullanmicam ��nk�
                wstrb_load  = 4'b1111;
            end
            BRANCH_OP : begin
                ALU_src     = 1'b0;
                Res_src     = 2'b00; 
                ALU_op      = 2'b01; 
                Imm_src     = 3'b010;
                wstrb_load  = 4'b1111;
            end
            JALR : begin
                ALU_src     = 1'b1;
                Res_src     = 2'b10;
                ALU_op      = 2'b10;
                Imm_src     = 3'b000;
                wstrb_load  = 4'b1111;
            end
            JAL : begin
                ALU_src     = 1'b0;
                ALU_op      = 2'b10;
                Res_src     = 2'b10;
                Imm_src     = 3'b011;
                wstrb_load  = 4'b1111;
            end
            default : begin
                ALU_src     = 1'b0;
                Res_src     = 2'b00;
                ALU_op      = 2'b00;
                Imm_src     = 3'b000;
                wstrb_load  = 4'b1111;
            end
        endcase
    end 
endmodule

module ALU_decoder (
    input  logic [1:0]  ALU_op,
    input  logic [6:0]  op_code,
    input  logic [2:0]  func3,
    input  logic [6:0]  func7, 
    output logic [3:0]  ALU_control,
    output logic        u_s
);

    localparam [1:0] load_store = 2'b00, 
                     branch     = 2'b01,
                     alu        = 2'b10;

//func3 = 001 ise sll'nin fun7sine g�re hareket edicez. func7 yi 1 de�il 7 bit yap. sonras�nda 
    always_comb begin
        case (ALU_op)
            load_store: begin
                ALU_control = 4'b0000; //toplama for loadstroe
                u_s = func3[2];  // Unsigned for load/store
            end
            branch : begin
                u_s = func3[2] && func3[1];
                case (func3)
                    3'b000: ALU_control = 4'b0101; // BEQ
                    3'b001: ALU_control = 4'b0111; // BNE
                    3'b100: ALU_control = 4'b1001; // BLT
                    3'b101: ALU_control = 4'b1011; // BGE
                    3'b110: ALU_control = 4'b1001;  // BLTU
                    3'b111: ALU_control = 4'b1011;  // BGEU
                endcase
            end
            alu : begin
                if (op_code == 7'b0110111)  begin
                    u_s = 0; 
                    ALU_control = 4'b1110; //toplama for lui
                end else begin
                    u_s = !func3[2] & func3[1] & func3[0];
                    case (func3)
                        3'b010: ALU_control = 4'b0011; //slt
                        3'b011: ALU_control = 4'b0011; //sltu
                        3'b100: ALU_control = 4'b1010; //xor
                        3'b110: ALU_control = 4'b1100; //or
                        3'b111: ALU_control = 4'b1000; //and
                        3'b000: begin
                            if ({op_code[5], func7[5]} == 2'b11)
                                ALU_control = 4'b0001;  // SUB
                            else
                                ALU_control = 4'b0000;  // ADD/ADDI
                        end
                        3'b101: begin
                            if ({op_code[5], func7[5]} == 2'b01 || {op_code[5], func7[5]} == 2'b11)
                                ALU_control = 4'b0110;  // SRA/SRAI
                            else
                                ALU_control = 4'b0100;  // SRL/SRLI
                        end
                        3'b001: begin
                            if (func3 == 3'b001 && ({op_code[5], func7[5]} == 2'b10))  begin
                                ALU_control = 4'b0010; //sll
                                u_s = 0;
                            end
                            if (func3 == 3'b001 && ({op_code[5], func7[5]} == 2'b00))  begin
                                ALU_control = 4'b0010; //slli
                                u_s = 0;
                            end if (func7[6:5] == 2'b11) begin
                                ALU_control = 4'b1111; //ctz                            
                            end
                        end
                        
                    endcase
                end
            end 
            default: begin
                ALU_control <= 4'b0000;
                u_s <= 0;
            end
        endcase
    
    end
endmodule
