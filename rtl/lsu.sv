module lsu
import rv_pkg::*;(
    input logic [31:0] store_val,
    input lsu_op_t funct3,
    input logic [1:0] addr_off,
    input logic [31:0] rdata,

    output logic [31:0] wdata,
    output logic [3:0] byte_en,
    output logic [31:0] load_val
);

    
    always_comb begin

        wdata = '0;
        byte_en = '0;
        load_val = '0;
        case(funct3)
        LSU_LB_SB : begin 
                        byte_en[0] = (~addr_off[0] && ~addr_off[1]); 
                        byte_en[1] = (addr_off[0] &&  ~addr_off[1]);
                        byte_en[2] = (~addr_off[0]  && addr_off[1]);
                        byte_en[3] = (addr_off[0]  &&  addr_off[1]);

                        //Replication
                        wdata = {4{store_val[7:0]}};

                        //sign extending the load value

                        load_val = {{24{rdata[7 + 8*(addr_off)]}}, rdata[8*(addr_off) +: 8]};
                    end

        LSU_LH_SH : begin
                        byte_en[0] = (~addr_off[0] && ~addr_off[1]); 
                        byte_en[1] = (~addr_off[1]); 
                        byte_en[2] = (addr_off[0] || addr_off[1]); 
                        byte_en[3] = (addr_off[1]); 

                        //Replication
                        wdata = {2{store_val[15:0]}};

                        //sign extending the load value

                        load_val = {{16{rdata[15 + 8*(addr_off)]}}, rdata[8*(addr_off) +: 16]};
                        
                    end

        LSU_LW_SW : begin
                        byte_en = '1;
                        wdata = store_val;
                        load_val = rdata;
                    end

        LSU_LBU   : begin
                        byte_en[0] = (~addr_off[0] && ~addr_off[1]); 
                        byte_en[1] = (addr_off[0] &&  ~addr_off[1]);
                        byte_en[2] = (~addr_off[0]  && addr_off[1]);
                        byte_en[3] = (addr_off[0]  &&  addr_off[1]);

                        load_val = {{24{1'b0}}, rdata[8*(addr_off) +: 8]};

                    end

        LSU_LHU   : begin
                        byte_en[0] = (~addr_off[0] && ~addr_off[1]); 
                        byte_en[1] = (~addr_off[1]); 
                        byte_en[2] = (addr_off[0] || addr_off[1]); 
                        byte_en[3] = (addr_off[1]); 

                        load_val = {{16{1'b0}}, rdata[8*(addr_off) +: 16]};

                    end
    endcase
    end

endmodule