`include "defines.vh"

module cache_tag #(
    parameter NUM_WAYS              = 4                 ,
    parameter NUM_SETS              = 16                ,

    parameter CACHE_LINE_TAG_WIDTH  = 22                ,

    parameter NUM_WAYS_LOG      = $clog2(NUM_WAYS)      ,
    parameter NUM_SETS_LOG      = $clog2(NUM_SETS) 
) (
    input                               clk                 ,
    input                               rst_n               ,

    input                               access_en           ,
    input   [NUM_SETS_LOG-1         :0] access_tag_set_idx  ,
    input   [CACHE_LINE_TAG_WIDTH-1 :0] access_tag          ,

    input   [NUM_SETS_LOG-1         :0] access_data_set_idx ,
    output  [NUM_WAYS-1             :0] access_hit_oh       ,

    input                               update_en           ,
    input   [NUM_WAYS_LOG-1         :0] update_way_idx      ,
    input   [NUM_SETS_LOG-1         :0] update_set_idx      ,
    input   [CACHE_LINE_TAG_WIDTH-1 :0] update_tag          ,
    input                               update_valid
);
    // valid
    wire [NUM_SETS-1:0] tags_valid[NUM_WAYS-1:0];

    genvar i;
    generate
    for (i = 0; i < NUM_WAYS; i = i + 1) 
        begin : gen_for_blk_cache_tag_valid0

            genvar j;
            for (j = 0; j < NUM_SETS; j = j + 1)
            begin : gen_for_blk_cache_tag_valid1

                wire update_valid_en = update_en && (update_way_idx == i) && (update_set_idx == j);

                sirv_gnrl_dfflr #(
                    .DW(1)
                ) inst_tag_valid (
                    .clk    (clk)               ,
                    .rst_n  (rst_n)             ,

                    .lden   (update_valid_en)   ,
                    .dnxt   (update_valid)      ,
                    .qout   (tags_valid[i][j])
                );
            end
        end
    endgenerate

    // tag
    wire [CACHE_LINE_TAG_WIDTH-1:0] read_tags[NUM_WAYS-1:0];

    genvar k;
    generate
        for (k = 0; k < NUM_WAYS; k = k + 1) 
        begin : gen_for_blk_cache_tag
            wire write_en = update_en && (update_way_idx == k);

            sram_1r1w #(
                .DATA_WIDTH (CACHE_LINE_TAG_WIDTH),
                .SIZE       (NUM_SETS)
            ) inst_cache_tag_sram (
                .clk        (clk)               ,

                .read_en    (access_en)         ,
                .read_addr  (access_tag_set_idx),
                .read_data  (read_tags[k])      ,

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
            assign access_hit_oh[p] = (tags_valid[p][access_data_set_idx]) && (read_tags[p] == access_tag);
        end
    endgenerate
endmodule