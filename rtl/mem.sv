module memory
import rv_pkg::*;#(parameter int DEPTH =  65536)(
    input  logic clk,
    input  logic [31:0] i_addr,
    output logic [31:0] i_rdata,

    input  logic [31:0] d_addr,
    input  logic d_we,
    input  logic [3:0]  d_byte_en,
    input  logic [31:0] d_wdata,
    output logic [31:0] d_rdata
);

logic [31:0] mem [0:DEPTH-1];

assign i_rdata = mem[i_addr[$clog2(DEPTH) + 1:2]];
assign d_rdata = mem[d_addr[$clog2(DEPTH) + 1:2]];


always_ff @(posedge clk) begin
    if(d_we) begin
        for(int i = 0; i < 4; i= i + 1) begin
            if(d_byte_en[i]) begin
                mem[d_addr[$clog2(DEPTH) + 1:2]][8*i+:8] <= d_wdata[8*i+:8];  
            end
        end
    end

end

endmodule