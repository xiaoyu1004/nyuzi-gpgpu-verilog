`include "defines.vh"

module test_ifetch_tag_stage(input clk, input rst_n);

    // from csr
    reg [NUM_WARP_PER_CORE-1     :0]    warp_en_bitmap;

    /* from ifetch data stage */
    reg                                 ifd_allowin;

    reg                                 ifd_cache_miss;
    reg                                 ifd_near_miss;
    reg [NUM_WARP_PER_CORE_LOG-1 :0]    ifd_cache_miss_warp_idx;

    /* from l2i */
    reg [NUM_WARP_PER_CORE-1     :0]    l2i_to_ift_wake_bitmap;

    /* from ifetch data stage */
    reg                                 wb_rollback_en; 
    reg [NUM_WARP_PER_CORE_LOG-1 :0]    wb_rollback_warp_idx; 
    reg [ADDR_WIDTH-1            :0]    wb_rollback_pc;

    /* to ifetch data stage */
    wire                                ift_to_ifd_valid;
    wire [IFT_TO_IFD_BUS_WIDTH-1  :0]   ift_to_ifd_bus;

    wire [ADDR_WIDTH-1:0]               pc_to_fetch_icache;
    wire [NUM_WARP_PER_CORE_LOG-1 :0]   selected_warp_idx;

    assign {pc_to_fetch_icache, selected_warp_idx} = ift_to_ifd_bus;

    /* to icache */
    wire                                ift_to_icache_fetch_en;
    wire [L1_CACHE_NUM_SETS_LOG-1 :0]   ift_to_icache_fetch_set_idx;

    ifetch_tag_stage inst_ifetch_tag_stage (
        .clk                            (clk)                           ,
        .rst_n                          (rst_n)                         ,

        .warp_en_bitmap                 (warp_en_bitmap)                ,

        .ifd_allowin                    (ifd_allowin)                   ,
        .ifd_cache_miss                 (ifd_cache_miss)                ,
        .ifd_near_miss                  (ifd_near_miss)                 ,
        .ifd_cache_miss_warp_idx        (ifd_cache_miss_warp_idx)       ,

        .ift_to_ifd_valid               (ift_to_ifd_valid)              ,
        .ift_to_ifd_bus                 (ift_to_ifd_bus)                ,

        .ift_to_icache_fetch_en         (ift_to_icache_fetch_en)        ,
        .ift_to_icache_fetch_set_idx    (ift_to_icache_fetch_set_idx)   ,

        .l2i_to_ift_wake_bitmap         (l2i_to_ift_wake_bitmap)        ,

        .wb_rollback_en                 (wb_rollback_en)                ,
        .wb_rollback_warp_idx           (wb_rollback_warp_idx)          ,
        .wb_rollback_pc                 (wb_rollback_pc)
    );

    integer cycle;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            cycle                   <= 0;

            warp_en_bitmap          <= '0;

            ifd_allowin             <= 1'b0;

            ifd_cache_miss          <=  1'b0;
            ifd_near_miss           <=  1'b0;
            ifd_cache_miss_warp_idx <=  'h0;

            l2i_to_ift_wake_bitmap  <= 'b0;

            wb_rollback_en          <= 1'b0;
            wb_rollback_warp_idx    <= 'h0;
            wb_rollback_pc          <= 'h0;

        end else begin
            warp_en_bitmap          <= 'b0001;

            ifd_allowin             <= 1'b1;

            ifd_cache_miss          <=  1'b0;
            ifd_near_miss           <=  1'b0;
            ifd_cache_miss_warp_idx <=  'b0;

            l2i_to_ift_wake_bitmap  <=  'b0;

            wb_rollback_en          <= 1'b0;
            wb_rollback_warp_idx    <= 'b0;
            wb_rollback_pc          <= 'b0;

            cycle                   <= cycle + 1;

            case (cycle)
                0: begin
                    /* fetch inst */
                    warp_en_bitmap          <= 'b0000;
                    ifd_allowin             <= 1'b1;
                end

                1: begin
                end

                2: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h0);
                    assert(selected_warp_idx == 'b0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);
                end

                3: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h4);
                    assert(selected_warp_idx == 'b0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* warp en bitmap */
                    warp_en_bitmap  <=  'b0000;
                end

                4: begin
                    assert(ift_to_ifd_valid == 1'b0);
                    assert(ift_to_icache_fetch_en == 1'b0);
                end

                5: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h8);
                    assert(selected_warp_idx == 'b0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* icache data not allowin */
                    ifd_cache_miss          <= 1'b1;
                    ifd_cache_miss_warp_idx <= 'h0;
                end

                6: begin
                    assert(ift_to_ifd_valid == 1'b0);
                    assert(ift_to_icache_fetch_en == 1'b0);

                    /* l2i wake bitmap */
                    l2i_to_ift_wake_bitmap  <= 'b0001;
                end

                7: begin
                end

                8: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h8);
                    assert(selected_warp_idx == 'b0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);
                end

                9: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'hc);
                    assert(selected_warp_idx == 'b0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* warp en bitmap */
                    warp_en_bitmap  <=  'b0011;
                end

                10: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h0);
                    assert(selected_warp_idx == 'h1);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);
                end

                11: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h10);
                    assert(selected_warp_idx == 'h0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* warp en bitmap */
                    warp_en_bitmap  <=  'b1111;
                end

                12: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h4);
                    assert(selected_warp_idx == 'h1);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* warp en bitmap */
                    warp_en_bitmap  <=  'b1111;
                end

                13: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h0);
                    assert(selected_warp_idx == 'h2);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* warp en bitmap */
                    warp_en_bitmap  <=  'b1111;
                end

                14: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h0);
                    assert(selected_warp_idx == 'h3);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);

                    /* warp en bitmap */
                    warp_en_bitmap  <=  'b1111;
                end

                15: begin
                    assert(ift_to_ifd_valid == 1'b1);
                    assert(pc_to_fetch_icache == 'h14);
                    assert(selected_warp_idx == 'h0);

                    assert(ift_to_icache_fetch_en == 1'b1);
                    assert(ift_to_icache_fetch_set_idx == 'b0);
                end

                16: begin
                    $display("PASS");
                    $finish;
                end
            endcase
        end
    end

endmodule