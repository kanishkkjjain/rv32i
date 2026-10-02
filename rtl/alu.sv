module alu
    import rv_pkg::*;(
        input alu_op_t alu_op,
        input logic [31:0] a_reg,
        input logic [31:0] b_reg,
        output logic [31:0] result
     );

logic [31:0] signed_a, signed_b;
logic [63:0] sign_extended_a;

assign signed_a = {~a_reg[31],a_reg[30:0]};
assign signed_b = {~b_reg[31],b_reg[30:0]};
assign sign_extended_a = {{32{a_reg[31]}},a_reg};
always_comb begin
    result = '0;
    case (alu_op)
    ALU_ADD: result = a_reg + b_reg;
    ALU_SLL: result = a_reg << b_reg[4:0];
    ALU_SLTU: result = (a_reg<b_reg);
    ALU_SLT: result = (signed_a<signed_b);  
    ALU_XOR: result = (a_reg)^(b_reg);
    ALU_SRA: result = (sign_extended_a >> b_reg[4:0]);
    ALU_OR : result = (a_reg | b_reg);
    ALU_AND: result = (a_reg & b_reg);
    ALU_SUB: result = (a_reg + (~b_reg) + 1);
    ALU_SRL: result = (a_reg >> b_reg[4:0]);
    endcase
end
endmodule