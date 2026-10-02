    module core 
    import rv_pkg::*;#(
        parameter logic [31:0] RESET_PC = 32'h8000_0000
    )(
        input  logic clk, 
        input  logic rst_n,
        input  logic [31:0] i_rdata,
        input  logic [31:0] d_rdata,
        output logic [31:0]  i_addr,
        output logic [31:0]  d_addr,
        output logic d_we,
        output logic [3:0] d_byte_en,
        output logic [31:0] d_wdata,
        output logic halt
    );

    logic [31:0] pc_q;
    id_reg_t id_reg;
    logic [31:0] pc_d;
    
    ex_reg_t ex_reg;
    logic [31:0] id_rs1_val;
    logic [31:0] id_rs2_val;
    logic [31:0] id_imm;
    ctrl_t id_ctrl;

    logic [31:0] ex_a;
    logic [31:0] ex_b;
    logic [31:0] ex_alu_result;
    logic bu_taken;
    logic ex_redirect;
    logic [31:0] ex_target;
    mem_reg_t mem_reg;
    logic [31:0] mem_load_val;
    wb_reg_t wb_reg;
    logic [31:0] wb_rd_data;
    
    logic [31:0] ex_fwd_rs1;
    logic ex_fw_check_1_rs1;
    logic ex_fw_check_2_rs1;

    logic [31:0] ex_fwd_rs2;
    logic ex_fw_check_1_rs2;
    logic ex_fw_check_2_rs2;
    logic stall;

    assign stall = ex_reg.ctrl.mem_read && (ex_reg.instr[11:7] != '0) && ((ex_reg.instr[11:7] == id_reg.instr[19:15]) || (ex_reg.instr[11:7] == id_reg.instr[24:20]));

    assign ex_redirect = (ex_reg.ctrl.is_branch && bu_taken) || (ex_reg.ctrl.is_jal) || (ex_reg.ctrl.is_jalr);
    assign ex_target   = ex_reg.ctrl.is_jalr? {ex_alu_result[31:1],1'b0}: ex_alu_result;
    
    //if stage
    assign i_addr = pc_q;
    assign pc_d = ex_redirect ? ex_target : pc_q + 4;
    always_ff @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pc_q <= RESET_PC; //reset to this addr.
            id_reg <= '0;
        end
        else begin
            if(ex_redirect) begin 
                id_reg <= '0;
                pc_q <= pc_d;
            end
            else if (stall) begin
                id_reg <= id_reg;
                pc_q <= pc_q;
            end

            else begin
            id_reg.instr <= i_rdata;
            id_reg.pc <= pc_q;
            pc_q <= pc_d;
            end
        end
    end

    //decode stage
    


    decoder u_decoder (.instr(id_reg.instr),.ctrl(id_ctrl));
    reg_file u_reg_file(.clk(clk), 
                        .rs1_addr(id_reg.instr[19:15]), 
                        .rs2_addr(id_reg.instr[24:20]), 
                        .we(wb_reg.ctrl.reg_write),  
                        .rd_addr(wb_reg.instr[11:7]),
                        .rd_data(wb_rd_data),
                        .rs1_val(id_rs1_val),
                        .rs2_val(id_rs2_val));

    immgen u_immgen(.instr(id_reg.instr[31:7]),
                    .opcode(id_reg.instr[6:0]),
                    .imm(id_imm));
    

    
    always_ff @ (posedge clk or negedge rst_n) begin 
        if(!rst_n) begin
            ex_reg <= '0;
        end
        else begin
            if(ex_redirect) begin 
                ex_reg <= '0;
            end

            else if(stall)
                ex_reg.ctrl <= '0;
            else begin
            ex_reg.ctrl <= id_ctrl;
            ex_reg.instr <=  id_reg.instr;
            ex_reg.rs1_val <= id_rs1_val;
            ex_reg.rs2_val <= id_rs2_val;           
            ex_reg.imm <= id_imm;
            ex_reg.pc <= id_reg.pc;
            end
        end
    end

    //execute stage 


    assign ex_fw_check_1_rs1 = ((ex_reg.instr[19:15] == mem_reg.instr[11:7]) && mem_reg.ctrl.reg_write && (mem_reg.instr[11:7] != '0));
    assign ex_fw_check_2_rs1 = ((ex_reg.instr[19:15] == wb_reg.instr[11:7]) && wb_reg.ctrl.reg_write && (wb_reg.instr[11:7] != '0));

    assign ex_fwd_rs1 = ex_fw_check_1_rs1 ? mem_reg.result:(ex_fw_check_2_rs1?wb_rd_data:ex_reg.rs1_val);
    

    assign ex_fw_check_1_rs2 = ((ex_reg.instr[24:20] == mem_reg.instr[11:7]) && mem_reg.ctrl.reg_write && (mem_reg.instr[11:7] != '0));
    assign ex_fw_check_2_rs2 = ((ex_reg.instr[24:20] == wb_reg.instr[11:7]) && wb_reg.ctrl.reg_write && (wb_reg.instr[11:7] != '0));

    assign ex_fwd_rs2 = ex_fw_check_1_rs2 ? mem_reg.result:(ex_fw_check_2_rs2?wb_rd_data:ex_reg.rs2_val);


    always_comb begin
        ex_a = '0;
        ex_b = '0;
        case (ex_reg.ctrl.a_sel)
        A_RS_1 : ex_a = ex_fwd_rs1;
        A_PC   : ex_a = ex_reg.pc;
        A_ZERO : ex_a = '0;
        endcase

        case (ex_reg.ctrl.b_sel)
        B_RS_2 : ex_b = ex_fwd_rs2;
        B_IMM  : ex_b = ex_reg.imm;
        endcase
        end

    alu u_alu ( .alu_op(ex_reg.ctrl.alu_op),
                .a_reg(ex_a),
                .b_reg(ex_b),
                .result(ex_alu_result));

    branch_unit u_branch_unit (
        .rs1_val(ex_fwd_rs1),
        .rs2_val(ex_fwd_rs2),
        .funct3(branch_op_t'(ex_reg.instr[14:12])),
        .taken(bu_taken));
    
    always_ff @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem_reg<='0;
    end
    else begin
        mem_reg.ctrl <= ex_reg.ctrl;
        mem_reg.result <= ((ex_reg.ctrl.is_jal) || (ex_reg.ctrl.is_jalr))? (ex_reg.pc + 4) : ex_alu_result;
        mem_reg.rs2_val <= ex_fwd_rs2;
        mem_reg.instr <= ex_reg.instr;
        end
    end

    //mem stage
    lsu u_lsu  (.store_val(mem_reg.rs2_val),
                .funct3(lsu_op_t'(mem_reg.instr[14:12])),
                .addr_off(mem_reg.result[1:0]),
                .rdata(d_rdata), 
                .wdata(d_wdata),
                .byte_en(d_byte_en),
                .load_val(mem_load_val));
    assign d_we = mem_reg.ctrl.mem_write;
    assign d_addr = mem_reg.result;

    always_ff @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wb_reg <= '0;
        end
        else begin 
            wb_reg.ctrl <= mem_reg.ctrl;
            wb_reg.result <= mem_reg.result;
            wb_reg.instr <= mem_reg.instr;
            wb_reg.load_val <= mem_load_val;
        end

    end

    // wb stage
    always_comb begin
        wb_rd_data = '0;
        case (wb_reg.ctrl.wb_sel) 
            WB_ALU: wb_rd_data = wb_reg.result;
            WB_MEM: wb_rd_data = wb_reg.load_val;
            WB_PC4: wb_rd_data = wb_reg.result;
        endcase
    end

    assign halt = wb_reg.ctrl.halt;


endmodule