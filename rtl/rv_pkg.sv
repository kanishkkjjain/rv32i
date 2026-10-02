package rv_pkg;
localparam logic [6:0] OP_LUI   =  7'b0110111;
localparam logic [6:0] OP_AUIPC =  7'b0010111;
localparam logic [6:0] OP_JAL =    7'b1101111;
localparam logic [6:0] OP_JALR =   7'b1100111;
localparam logic [6:0] OP_BRANCH = 7'b1100011;
localparam logic [6:0] OP_LOAD =   7'b0000011;
localparam logic [6:0] OP_STORE =  7'b0100011;
localparam logic [6:0] OP_IMM =    7'b0010011;
localparam logic [6:0] OP_OP =     7'b0110011;
localparam logic [6:0] OP_FENCE =  7'b0001111;
localparam logic [6:0] OP_SYSTEM = 7'b1110011;

typedef enum logic [3:0] {
    ALU_ADD, ALU_SLL, ALU_SLT, 
    ALU_SLTU, ALU_XOR, ALU_SRL, 
    ALU_OR, ALU_AND, ALU_SUB, ALU_SRA  = 4'b1_101
} alu_op_t; //order is according to func3, dont change carelessly. 

typedef enum logic [2:0] {
    WB_ALU, WB_MEM, WB_PC4
} wb_sel_t;

typedef enum logic [1:0] {
    A_RS_1, A_PC, A_ZERO
} a_sel_t;

typedef enum logic {
    B_RS_2, B_IMM
} b_sel_t;

typedef enum logic [2:0] {
    BU_BEQ = 3'b000,
    BU_BNE = 3'b001,
    BU_BLT = 3'b100,
    BU_BGE = 3'b101,
    BU_BLTU= 3'b110,
    BU_BGEU= 3'b111
} branch_op_t;

typedef enum logic [2:0] {
    LSU_LB_SB = 3'b000,
    LSU_LH_SH = 3'b001,
    LSU_LW_SW = 3'b010,
    LSU_LBU   = 3'b100,
    LSU_LHU   = 3'b101
} lsu_op_t;

typedef struct packed {
    alu_op_t alu_op;
    wb_sel_t wb_sel;
    a_sel_t a_sel;
    b_sel_t b_sel;
    logic is_branch, is_jal, is_jalr;
    logic mem_read, mem_write;
    logic reg_write; //default reg read is async
    logic halt;
}   ctrl_t;


typedef struct packed {
        logic [31:0] instr;
        logic [31:0] pc;
    } id_reg_t;

typedef struct packed {
    ctrl_t ctrl;
    logic [31:0] result;
    logic [31:0] rs2_val;
    logic [31:0] instr;
} mem_reg_t;
typedef struct packed {
    ctrl_t ctrl;
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] imm;
    logic [31:0] pc;
    logic [31:0] instr;
} ex_reg_t;

typedef struct packed {
    ctrl_t ctrl;
    logic [31:0] result;
    logic [31:0] instr;
    logic [31:0] load_val;
} wb_reg_t;


endpackage