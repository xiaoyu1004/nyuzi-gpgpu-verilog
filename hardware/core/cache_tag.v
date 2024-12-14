`include "defines.vh"

module cache_tag #(
    parameter NUM_WAYS          = 4                 ,
    parameter NUM_SETS          = 16                ,

    parameter CACHE_TAG_WIDTH   = 22                ,

    parameter NUM_WAYS_LOG      = $clog2(NUM_WAYS)  ,
    parameter NUM_SETS_LOG      = $clog2(NUM_SETS) 
) (
    input                           clk             ,
    input                           rst_n           ,

    input                           access_en       ,
    input   [NUM_SETS_LOG-1     :0] access_set_idx  ,
    input   [CACHE_TAG_WIDTH-1  :0] access_tag      ,
    output  [NUM_WAYS-1         :0] access_hit_oh   ,

    input                           update_en       ,
    input   [NUM_WAYS_LOG-1     :0] update_way_idx  ,
    input   [NUM_SETS_LOG-1     :0] update_set_idx  ,
    input   [CACHE_TAG_WIDTH-1  :0] update_tag      ,
    input                           update_valid
);
    // valid
    wire tag_ways_valid[NUM_WAYS];

    genvar i, j;
    generate
    for (i = 0; i < NUM_WAYS; i = i + 1) 
        begin : gen_for_blk_cache_tag_valid0

            wire [NUM_SETS-1:0] tag_sets_valid;

            for (j = 0; j < NUM_SETS; j = j + 1)
            begin : gen_for_blk_cache_tag_valid1

                wire update_valid_en = tag_update_en[i] && (tag_update_set_idx == j);

                sirv_gnrl_dfflr #(
                    .DW(1)
                ) inst_tag_valid (
                    .clk    (clk)               ,
                    .rst_n  (rst_n)             ,

                    .lden   (update_valid_en)   ,
                    .dnxt   (tag_update_valid)  ,
                    .qout   (tag_sets_valid[j])
                );

                assign tag_ways_valid[i] = (j == tag_access_set_idx) ? tag_sets_valid[j] : 1'b0;
            end
        end
    endgenerate

    // tag
    wire [CACHE_TAG_WIDTH-1:0] read_tag_data[NUM_WAYS];

    genvar k;
    generate
        for (k = 0; k < NUM_WAYS; k = k + 1) 
        begin : gen_for_blk_cache_tag
            wire write_en = update_en && (update_way_idx == k);

            sram_1r1w #(
                .DATA_WIDTH (CACHE_TAG_WIDTH),
                .SIZE       (NUM_SETS)
            ) inst_cache_tag_sram (
                .clk        (clk)               ,

                .read_en    (access_en)         ,
                .read_addr  (access_set_idx)    ,
                .read_data  (read_tag_data[k])  ,

                .write_en   (write_en)          ,
                .write_addr (update_set_idx)    ,
                .write_data (update_tag)
            );
        end
    endgenerate

    genvar p;
    generate
        for (p = 0; p < NUM_WAYS; p = p + 1)
        begin : gen_for_tag_result
            assign access_hit_oh[p] = tag_ways_valid[p] && (read_tag_data[p] == tag_data);
        end
    endgenerate
endmodule