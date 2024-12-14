`include "defines.vh"

module cache_lru #(
    parameter NUM_WAYS          = 4                 ,
    parameter NUM_SETS          = 16                ,

    parameter NUM_WAYS_LOG      = $clog2(NUM_WAYS)  ,
    parameter NUM_SETS_LOG      = $clog2(NUM_SETS)  
) (
    input                           clk             ,
    input                           rst_n           ,

    // first cycle
    input                           access_en       ,
    input   [NUM_SETS_LOG-1:0]      access_set      ,
    // second cycle
    input                           update_en       ,
    input   [NUM_WAYS_LOG-1:0]      update_way_idx  ,

    input                           fill_en         ,
    input   [NUM_SETS_LOG-1:0]      fill_set        ,
    output  [NUM_WAYS_LOG-1:0]      fill_way_idx
);
    wire read_en                        = access_en || fill_en;
    wire [NUM_SETS_LOG-1:0] read_set    = fill_en ? fill_set : access_set;
    wire [NUM_WAYS-2:0] lru_flags;

    wire was_fill;
    wire [NUM_SETS_LOG-1:0] write_set;

    sirv_gnrl_dffr #(
        .DW (1)
    ) inst_dff_was_fill (
        .clk    (clk)       ,
        .rst_n  (rst_n)     ,

        .dnxt   (fill_en)   ,
        .qout   (was_fill)  
    );

    sirv_gnrl_dffl #(
        .DW (NUM_SETS_LOG)
    ) inst_dff_update_set (
        .clk    (clk)           ,

        .lden   (read_en)       ,
        .dnxt   (read_set)      ,
        .qout   (write_set)  
    );

    wire write_lru_en  = was_fill || update_en;

    wire [NUM_WAYS_LOG-1:0] keep_way_idx = was_fill ? fill_way_idx : update_way_idx;

    wire write_lru_flags = ({(NUM_WAYS-1){(keep_way_idx == 2'b00)}} & {2'b11, lru_flags[0]}) |
                           ({(NUM_WAYS-1){(keep_way_idx == 2'b01)}} & {2'b01, lru_flags[0]}) |
                           ({(NUM_WAYS-1){(keep_way_idx == 2'b10)}} & {lru_flags[2], 2'b01}) |
                           ({(NUM_WAYS-1){(keep_way_idx == 2'b11)}} & {lru_flags[2], 2'b00});

    sram_1r1w #(
        .DATA_WIDTH (NUM_WAYS)  ,
        .SIZE       (NUM_SETS)  
    ) inst_sram_lru_flags (
        .clk        (clk)               ,

        .read_en    (read_en)           ,
        .read_addr  (read_set)          ,
        .read_data  (lru_flags)         ,

        .write_en   (write_lru_en)      ,
        .write_addr (write_set)         ,
        .write_data (write_lru_flags)
    );

    assign update_way_idx = ({NUM_WAYS_LOG{(lru_flags[NUM_WAYS-2:1] == 2'b00)}} & {2'b00}) |
                            ({NUM_WAYS_LOG{(lru_flags[NUM_WAYS-2:1] == 2'b10)}} & {2'b01}) |
                            ({NUM_WAYS_LOG{(lru_flags[NUM_WAYS-3:0] == 2'b10)}} & {2'b10}) |
                            ({NUM_WAYS_LOG{(lru_flags[NUM_WAYS-3:0] == 2'b11)}} & {2'b11});
endmodule