module reg_file
import rv_pkg::*;(
    input logic clk,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic we,
    input logic [4:0] rd_addr,
    input logic [31:0] rd_data,
    output logic [31:0] rs1_val,
    output logic [31:0] rs2_val
);

logic [31:0] reg_file_1 [31:0]; 

always_comb begin
    rs1_val = '0;
    rs2_val = '0;
    rs1_val = reg_file_1[rs1_addr];
    rs2_val = reg_file_1[rs2_addr];

    if(we && (rs1_addr == rd_addr)) 
        rs1_val = rd_data;

    if(we && (rs2_addr == rd_addr)) 
        rs2_val = rd_data;

    if(rs1_addr == '0) rs1_val = '0;
    if(rs2_addr == '0) rs2_val = '0;

end

always_ff @ (posedge clk) begin 
        if(we) begin
            reg_file_1[rd_addr] <= rd_data; 
    end 
end
endmodule 