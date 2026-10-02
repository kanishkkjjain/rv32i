module branch_unit

import rv_pkg::*;(
    input logic [31:0] rs1_val,
    input logic [31:0] rs2_val,
    input branch_op_t funct3,
    output logic taken
);
always_comb begin
    taken = 1'b0;

        case (funct3)
    BU_BEQ: taken = (rs1_val == rs2_val);
    BU_BNE: taken = (rs1_val != rs2_val);
    BU_BLT: taken = ({~rs1_val[31],rs1_val[30:0]}<{~rs2_val[31],rs2_val[30:0]});
    BU_BGE: taken = !({~rs1_val[31],rs1_val[30:0]}<{~rs2_val[31],rs2_val[30:0]});
    BU_BLTU: taken= (rs1_val<rs2_val);
    BU_BGEU: taken= !(rs1_val<rs2_val);
        endcase
end
endmodule


