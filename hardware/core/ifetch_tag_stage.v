`include "defines.vh"

module ifetch_tag_stage(
    input                               clk                     ,
    input                               rst_n                   ,

    // from csr
    input  [NUM_WARP_PER_CORE-1     :0] warp_en_bitmap          ,

    // from ifetch data stage
    input                               ifd_allowin             ,

    input                               ifd_cache_miss          ,
    input                               ifd_near_miss           ,
    input  [NUM_WARP_PER_CORE_LOG-1 :0] ifd_cache_miss_warp_idx ,

    // to ifetch data stage
    output                              ift_to_ifd_valid        ,
    output [IFT_TO_IFD_BUS_WIDTH-1  :0] ift_to_ifd_bus          ,

    // to icache
    output                              ift_to_icache_fetch_en  ,
    output [L1_CACHE_NUM_SETS_LOG-1 :0] ift_to_icache_fetch_set_idx ,

    // from l2 interface
    input  [NUM_WARP_PER_CORE-1     :0] l2i_to_ift_wake_bitmap  ,

    // from writeback stage
    input                               wb_rollback_en          ,
    input  [NUM_WARP_PER_CORE_LOG-1 :0] wb_rollback_warp_idx    ,
    input  [ADDR_WIDTH-1            :0] wb_rollback_pc          
);
    /* pre ift stage */
    wire pre_ift_valid      = rst_n;
    wire pre_ift_ready_go   = 1'b1;
    wire to_ift_valid       = pre_ift_valid && pre_ift_ready_go;

    /* ift stage */
    wire ift_valid;
    wire ift_ready_go;

    assign ift_to_ifd_valid = ift_valid && ift_ready_go;

    wire ift_allowin = ~ift_valid || (ift_ready_go && ifd_allowin);

    sirv_gnrl_dfflr #(
        .DW (1)
    ) inst_dff_ift_valid (
        .clk        (clk)           ,
        .rst_n      (rst_n)         ,

        .lden       (ift_allowin)   ,
        .dnxt       (to_ift_valid)  ,
        .qout       (ift_valid)
    );

    /* to obtain can fetch warp bitmap */
    wire [NUM_WARP_PER_CORE-1:0]    icache_miss_warp_oh;
    idx_to_oh #(
        .IDX_WIDTH  (NUM_WARP_PER_CORE_LOG)
    ) inst_icache_miss_warp_idx_to_oh (
        .idx        (ifd_cache_miss_warp_idx)   ,
        .one_hot    (icache_miss_warp_oh)
    );

    wire [NUM_WARP_PER_CORE-1:0]    wb_rollback_warp_oh;
    idx_to_oh #(
        .IDX_WIDTH  (NUM_WARP_PER_CORE_LOG)
    ) inst_wb_rollback_warp_idx_to_oh (
        .idx        (wb_rollback_warp_idx)   ,
        .one_hot    (wb_rollback_warp_oh)
    );

    wire [NUM_WARP_PER_CORE-1:0] icache_wait_warps_bitmap;

    wire [NUM_WARP_PER_CORE-1:0] stop_fetch_warp_bitmap = icache_wait_warps_bitmap                                                      |
                                                        (icache_miss_warp_oh  & {NUM_WARP_PER_CORE{ifd_cache_miss || ifd_near_miss}})   |
                                                        (wb_rollback_warp_oh  & {NUM_WARP_PER_CORE{wb_rollback_en}});

    wire [NUM_WARP_PER_CORE-1:0] can_fetch_warp_bitmap  = warp_en_bitmap & (~stop_fetch_warp_bitmap);
    wire icache_fetch_en                                = |can_fetch_warp_bitmap && ift_valid;

    assign ift_ready_go = icache_fetch_en;

    wire [NUM_WARP_PER_CORE-1       :0]    selected_warp_oh;
    wire [NUM_WARP_PER_CORE_LOG-1   :0]    selected_warp_idx;

    rr_arbiter #(
        .NUM_REQUESTERS (NUM_WARP_PER_CORE)
    ) inst_rr_arbiter (
        .clk            (clk)                   ,
        .rst_n          (rst_n)                 ,

        .req_bitmap     (can_fetch_warp_bitmap) ,
        .update_en      (icache_fetch_en)       ,
        .grant_oh       (selected_warp_oh)
    );

    oh_to_idx #(
        .OH_WIDTH   (NUM_WARP_PER_CORE) 
    ) inst_ift_warp_oh_to_idx (
        .one_hot    (selected_warp_oh)  ,
        .idx        (selected_warp_idx)
    );

    wire [ADDR_WIDTH-1:0] ift_pc [NUM_WARP_PER_CORE];

    genvar warp_idx;
    generate 
        for (warp_idx = 0; warp_idx < NUM_WARP_PER_CORE; warp_idx = warp_idx + 1)
        begin : gen_for_blk_warp_pc
            wire warp_rollback    = wb_rollback_en && (wb_rollback_warp_idx == warp_idx);
            wire warp_cache_miss  = (ifd_cache_miss || ifd_near_miss) && (ifd_cache_miss_warp_idx == warp_idx);
            wire warp_selected    = icache_fetch_en && (selected_warp_idx == warp_idx);
            
            wire [ADDR_WIDTH-1:0] ift_pc_nxt =  warp_rollback   ? wb_rollback_pc          :
                                                warp_cache_miss ? (ift_pc[warp_idx] - 'h4) :
                                                warp_selected   ? (ift_pc[warp_idx] + 'h4) : 
                                                ift_pc[warp_idx];

            sirv_gnrl_dfflrs_val #(
                .DW (ADDR_WIDTH)
            ) inst_ift_pc (
                .clk        (clk)                           ,
                .rst_n      (rst_n)                         ,
                .rst_v      ('hfffffffc)                    ,

                .lden       (to_ift_valid && ift_allowin)   ,
                .dnxt       (ift_pc_nxt)                    ,
                .qout       (ift_pc[warp_idx])
            );
        end
    endgenerate

    wire [ADDR_WIDTH-1:0] pc_to_fetch_icache = ift_pc[selected_warp_idx];

    wire [L1_CACHE_NUM_SETS_LOG-1:0] pc_set_idx = pc_to_fetch_icache[(CACHE_LINE_BYTE_WIDTH_LOG + L1_CACHE_NUM_SETS_LOG - 1):CACHE_LINE_BYTE_WIDTH_LOG];

    /* to icache */
    assign ift_to_icache_fetch_en       = icache_fetch_en;
    assign ift_to_icache_fetch_set_idx  = pc_set_idx;

    /* icache miss wait warps */
    wire [NUM_WARP_PER_CORE-1:0]    icache_miss_sleep_warp_oh       = icache_miss_warp_oh & ({NUM_WARP_PER_CORE{ifd_cache_miss}});
    wire [NUM_WARP_PER_CORE-1:0]    icache_wait_warps_bitmap_nxt    = (icache_wait_warps_bitmap | icache_miss_sleep_warp_oh) & (~l2i_to_ift_wake_bitmap);

    sirv_gnrl_dffr #(
        .DW (NUM_WARP_PER_CORE)
    ) inst_icache_wait_warps_bitmap (
        .clk        (clk)                           ,
        .rst_n      (rst_n)                         ,

        .dnxt       (icache_wait_warps_bitmap_nxt)  ,
        .qout       (icache_wait_warps_bitmap)
    );

    /* to ifd stage */
    assign ift_to_ifd_bus = {
        pc_to_fetch_icache,
        selected_warp_idx
    };

endmodule