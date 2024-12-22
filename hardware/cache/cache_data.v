`include "defines.vh"

module cache_data #(
    parameter NUM_WAYS          = 4                     ,
    parameter NUM_SETS          = 16                    ,

    parameter CACHE_LINE_BYTES  = 64                    ,

    parameter NUM_WAYS_LOG      = $clog2(NUM_WAYS)      ,
    parameter NUM_SETS_LOG      = $clog2(NUM_SETS)      ,

    parameter CACHE_LINE_BITS   = CACHE_LINE_BYTES * 8  
) (
    input                           clk             ,
    input                           rst_n           ,

    input                           access_en       ,
    input   [NUM_WAYS_LOG-1     :0] access_way_idx  ,
    input   [NUM_SETS_LOG-1     :0] access_set_idx  ,
    output  [CACHE_LINE_BITS-1  :0] access_data     ,

    input                           update_en       ,
    input   [NUM_WAYS_LOG-1     :0] update_way_idx  ,
    input   [NUM_SETS_LOG-1     :0] update_set_idx  ,
    input   [CACHE_LINE_BITS-1  :0] update_data     
);
    // reg
    wire [NUM_WAYS_LOG-1   :0] access_way_idx_r;

    sirv_gnrl_dfflr #(
        .DW(NUM_WAYS_LOG)
    ) inst_tag_valid (
        .clk    (clk)               ,
        .rst_n  (rst_n)             ,

        .lden   (access_en)         ,
        .dnxt   (access_way_idx)    ,
        .qout   (access_way_idx_r)
    );

    // data
    wire [CACHE_LINE_BITS-1:0] read_data[NUM_WAYS-1:0];

    genvar i;
    generate 
        for (i = 0; i < NUM_WAYS; i = i + 1) begin : gen_for_blk_cache_data
            wire write_en = update_en && (update_way_idx == i);

            sram_1r1w #(
                .DATA_WIDTH (CACHE_LINE_BITS)   ,
                .SIZE       (NUM_SETS)
            ) inst_cache_data_sram (
                .clk        (clk)               ,

                .read_en    (access_en)         ,
                .read_addr  (access_set_idx)    ,
                .read_data  (read_data[i])      ,

                .write_en   (write_en)          ,
                .write_addr (update_set_idx)    ,
                .write_data (update_data)
            );
        end
    endgenerate

    assign access_data = read_data[access_way_idx_r];
endmodule