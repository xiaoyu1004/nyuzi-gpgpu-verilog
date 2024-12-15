`include "defines.vh"

module cache #(
    parameter NUM_WAYS                  = 4                     ,
    parameter NUM_SETS                  = 16                    ,

    parameter CACHE_TAG_WIDTH           = 22                    ,
    parameter CACHE_LINE_BYTES          = 64                    ,

    parameter NUM_WAYS_LOG              = $clog2(NUM_WAYS)      ,
    parameter NUM_SETS_LOG              = $clog2(NUM_SETS)      ,

    parameter CACHE_LINE_BITS           = CACHE_LINE_BYTES * 8  ,
) (
    input                                 clk                   ,
    input                                 rst_n                 ,

    input                                 access_tag_en         ,
    input   [NUM_SETS_LOG-1         :0]   access_tag_set_idx    ,
    
    input   [CACHE_TAG_WIDTH-1      :0]   access_tag            ,
    output                                access_tag_hit        ,
    output  [NUM_WAYS_LOG-1         :0]   access_tag_hit_way_idx,

    input                                 access_data_en        ,
    input   [NUM_WAYS_LOG-1         :0]   access_data_way_idx   ,
    input   [NUM_SETS_LOG-1         :0]   access_data_set_idx   ,
    output  [CACHE_LINE_BITS-1      :0]   access_data           ,

    input                                 update_tag_en         ,
    input   [NUM_WAYS_LOG-1         :0]   update_tag_way_idx    ,
    input   [NUM_SETS_LOG-1         :0]   update_tag_set_idx    ,
    input   [CACHE_TAG_WIDTH-1      :0]   update_tag            ,
    input                                 update_tag_valid      ,

    input                                 update_data_en        ,
    input   [NUM_WAYS_LOG-1         :0]   update_data_way_idx   ,
    input   [NUM_SETS_LOG-1         :0]   update_data_set_idx   ,
    input   [CACHE_LINE_BITS-1      :0]   update_data           ,

    input                                 lru_fill_en           ,
    input   [NUM_SETS_LOG-1         :0]   lru_fill_set          ,
    output  [NUM_WAYS_LOG-1         :0]   lru_fill_way_idx  
);
    /* tag */
    wire [NUM_WAYS-1        :0] access_hit_oh;

    cache_tag #(
        .NUM_WAYS           (NUM_WAYS)  ,
        .NUM_SETS           (NUM_SETS)  ,

        .CACHE_TAG_WIDTH    (CACHE_TAG_WIDTH)
    ) inst_cache_tag (
        .clk            (clk)               ,
        .rst_n          (rst_n)             ,

        .access_en      (access_tag_en)     ,
        .access_set_idx (access_tag_set_idx),
        .access_tag     (access_tag)        ,
        .access_hit_oh  (access_hit_oh)     ,

        .update_en      (update_tag_en)     ,
        .update_way_idx (update_tag_way_idx),
        .update_set_idx (update_tag_set_idx),
        .update_tag     (update_tag)        ,
        .update_valid   (update_tag_valid)
    );

    assign access_tag_hit = |access_hit_oh;

    oh_to_idx #(
        .OH_WIDTH (NUM_WAYS)
    ) inst_cache_way_oh_to_idx (
        .one_hot    (access_hit_oh)         ,
        .idx        (access_tag_hit_way_idx)
    );

    /* data */
    cache_data #(
        .NUM_WAYS           (NUM_WAYS)          ,
        .NUM_SETS           (NUM_SETS)          ,
        .CACHE_LINE_BYTES   (CACHE_LINE_BYTES)
    ) inst_cache_data (
        .clk            (clk)                   ,
        .rst_n          (rst_n)                 ,

        .access_en      (access_data_en)        ,
        .access_way_idx (access_data_way_idx)   ,
        .access_set_idx (access_data_set_idx)   ,
        .access_data    (access_data)           ,

        .update_en      (update_data_en)        ,
        .update_way_idx (update_data_way_idx)   ,
        .update_set_idx (update_data_set_idx)   ,
        .update_data    (update_data)
    );

    /* lru */
    cache_lru #(
        .NUM_WAYS   (NUM_WAYS)  ,
        .NUM_SETS   (NUM_SETS)  
    ) inst_cache_lru (
        .clk            (clk)                   ,
        .rst_n          (rst_n)                 ,

        .access_en      (access_tag_en)         ,
        .access_set     (access_tag_set_idx)    ,
        .update_en      (access_data_en)        ,
        .update_way_idx (access_data_way_idx)   ,

        .fill_en        (lru_fill_en)           ,
        .fill_set       (lru_fill_set)          ,
        .fill_way_idx   (lru_fill_way_idx)
    );
endmodule