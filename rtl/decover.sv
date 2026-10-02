module decoder 
import rv_pkg::*;(
    input logic [31:0] instr,
    output ctrl_t ctrl
);

logic [6:0] opcode;
logic [2:0] funct3;
logic inst_30;


assign opcode = instr[6:0]; 
assign funct3  = instr[14:12];
assign inst_30 = instr[30];



//ctrl wires driving
always_comb begin
    ctrl = '0;
    case (opcode)
    OP_OP :     begin 
                    ctrl.alu_op = alu_op_t'({inst_30, funct3});
                    ctrl.wb_sel = WB_ALU;
                    ctrl.a_sel = A_RS_1;
                    ctrl.b_sel = B_RS_2;
                    ctrl.reg_write = 1'b1;
                end

    OP_IMM :    begin
                    ctrl.alu_op = alu_op_t'({(funct3 == 3'b101)?inst_30:1'b0, funct3});
                    ctrl.wb_sel = WB_ALU;
                    ctrl.a_sel = A_RS_1;
                    ctrl.b_sel = B_IMM;
                    ctrl.reg_write = 1'b1;
                end

    OP_STORE:   begin
                    ctrl.alu_op = ALU_ADD;
                    ctrl.wb_sel = WB_MEM;
                    ctrl.a_sel  = A_RS_1;
                    ctrl.b_sel  = B_IMM;
                    ctrl.mem_write = 1'b1;
                end

    OP_BRANCH:  begin
                    ctrl.alu_op = ALU_ADD;
                    ctrl.wb_sel = WB_PC4;
                    ctrl.a_sel  = A_PC;
                    ctrl.b_sel  = B_IMM;
                    ctrl.is_branch = 1'b1;
                end

    OP_LOAD:    begin
                    ctrl.alu_op = ALU_ADD;
                    ctrl.wb_sel = WB_MEM;
                    ctrl.a_sel  = A_RS_1;
                    ctrl.b_sel  = B_IMM;
                    ctrl.mem_read = 1'b1;
                    ctrl.reg_write = 1'b1;
                end 

    OP_JAL:     begin 
                    ctrl.alu_op = ALU_ADD;
                    ctrl.wb_sel = WB_PC4;
                    ctrl.a_sel  = A_PC;
                    ctrl.b_sel  = B_IMM;
                    ctrl.is_jal = 1'b1;
                    ctrl.reg_write = 1'b1;
                end 

    OP_JALR:    begin 
                    ctrl.alu_op = ALU_ADD;
                    ctrl.wb_sel = WB_PC4;
                    ctrl.a_sel  = A_RS_1;
                    ctrl.b_sel  = B_IMM;
                    ctrl.is_jalr = 1'b1;
                    ctrl.reg_write = 1'b1;
                end 

    OP_LUI:     begin
                ctrl.alu_op = ALU_ADD;
                ctrl.wb_sel = WB_ALU;
                ctrl.a_sel  = A_ZERO;
                ctrl.b_sel  = B_IMM;
                ctrl.reg_write = 1'b1;
                end
        
    OP_AUIPC:   begin
                ctrl.alu_op = ALU_ADD;
                ctrl.wb_sel = WB_ALU;
                ctrl.a_sel  = A_PC;
                ctrl.b_sel  = B_IMM;
                ctrl.reg_write = 1'b1;
                end

    OP_SYSTEM:  begin
                if((funct3 == 3'b000) && (instr[31:20] == 12'b000000000000))
                ctrl.halt = 1'b1;
                end    
    endcase

end
endmodule