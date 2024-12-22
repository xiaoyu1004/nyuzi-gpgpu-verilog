`include "defines.vh"

module test_cache(input clk, input rst_n);

    reg                                 access_tag_en         ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]   access_tag_set_idx    ;
    
    reg   [L1_CACHE_LINE_TAG_WIDTH-1:0]   access_tag            ;
    wire                                access_tag_hit        ;

    reg                                 access_data_en        ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]   access_data_set_idx   ;
    wire  [CACHE_LINE_BIT_WIDTH-1 :0]   access_data           ;

    reg                                 update_tag_en         ;
    reg   [L1_CACHE_NUM_WAYS_LOG-1:0]   update_tag_way_idx    ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]   update_tag_set_idx    ;
    reg   [L1_CACHE_LINE_TAG_WIDTH-1:0]   update_tag            ;
    reg                                 update_tag_valid      ;

    reg                                 update_data_en        ;
    reg   [L1_CACHE_NUM_WAYS_LOG-1:0]   update_data_way_idx   ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]   update_data_set_idx   ;
    reg   [CACHE_LINE_BIT_WIDTH-1 :0]   update_data           ;

    reg                                 lru_fill_en           ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]   lru_fill_set          ;
    wire  [L1_CACHE_NUM_WAYS_LOG-1:0]   lru_fill_way_idx      ;

    cache #(
        .NUM_WAYS           (L1_CACHE_NUM_WAYS)         ,
        .NUM_SETS           (L1_CACHE_NUM_SETS)         ,

        .CACHE_LINE_TAG_WIDTH    (L1_CACHE_LINE_TAG_WIDTH)   ,
        .CACHE_LINE_BYTES   (CACHE_LINE_BYTE_WIDTH)
    ) inst_icache (
        .clk                            (clk)                           ,
        .rst_n                          (rst_n)                         ,

        .access_tag_en                  (access_tag_en)                 ,
        .access_tag_set_idx             (access_tag_set_idx)            ,

        .access_tag                     (access_tag)                    ,
        .access_tag_hit                 (access_tag_hit)                ,

        .access_data_en                 (access_data_en)                ,
        .access_data_set_idx            (access_data_set_idx)           ,
        .access_data                    (access_data)                   ,

        .update_tag_en                  (update_tag_en)                 ,
        .update_tag_way_idx             (update_tag_way_idx)            ,
        .update_tag_set_idx             (update_tag_set_idx)            ,
        .update_tag                     (update_tag)                    ,
        .update_tag_valid               (update_tag_valid)              ,

        .update_data_en                 (update_data_en)                ,
        .update_data_way_idx            (update_data_way_idx)           ,
        .update_data_set_idx            (update_data_set_idx)           ,
        .update_data                    (update_data)                   ,

        .lru_fill_en                    (lru_fill_en)                   ,
        .lru_fill_set                   (lru_fill_set)                  ,
        .lru_fill_way_idx               (lru_fill_way_idx)
    );

    wire [CACHE_LINE_BIT_WIDTH-1:0] DATA1 = {(CACHE_LINE_BYTE_WIDTH / 4){32'h7114c100}};
    wire [CACHE_LINE_BIT_WIDTH-1:0] DATA2 = {(CACHE_LINE_BYTE_WIDTH / 4){32'h8d490c12}};
    wire [CACHE_LINE_BIT_WIDTH-1:0] DATA3 = {(CACHE_LINE_BYTE_WIDTH / 4){32'h12763338}};
    wire [CACHE_LINE_BIT_WIDTH-1:0] DATA4 = {(CACHE_LINE_BYTE_WIDTH / 4){32'h52714514}};

    localparam ADDR1 = 'h8c7c4f10;
    localparam ADDR2 = 'h8d764752;
    localparam ADDR3 = 'h1f764318;
    localparam ADDR4 = 'h4f254214;
    localparam ADDR5 = 'h9cdfa214;

    wire [L1_CACHE_LINE_TAG_WIDTH-1:0] ADDR1_TAG   =  ADDR1[ADDR_WIDTH-1:(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG)];
    wire [L1_CACHE_LINE_TAG_WIDTH-1:0] ADDR2_TAG   =  ADDR2[ADDR_WIDTH-1:(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG)];
    wire [L1_CACHE_LINE_TAG_WIDTH-1:0] ADDR3_TAG   =  ADDR3[ADDR_WIDTH-1:(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG)];
    wire [L1_CACHE_LINE_TAG_WIDTH-1:0] ADDR4_TAG   =  ADDR4[ADDR_WIDTH-1:(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG)];
    wire [L1_CACHE_LINE_TAG_WIDTH-1:0] ADDR5_TAG   =  ADDR5[ADDR_WIDTH-1:(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG)];

    wire [L1_CACHE_NUM_SETS_LOG-1:0] ADDR1_SET  =  ADDR1[(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG - 1):CACHE_LINE_BYTE_WIDTH_LOG];
    wire [L1_CACHE_NUM_SETS_LOG-1:0] ADDR2_SET  =  ADDR2[(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG - 1):CACHE_LINE_BYTE_WIDTH_LOG];
    wire [L1_CACHE_NUM_SETS_LOG-1:0] ADDR3_SET  =  ADDR3[(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG - 1):CACHE_LINE_BYTE_WIDTH_LOG];
    wire [L1_CACHE_NUM_SETS_LOG-1:0] ADDR4_SET  =  ADDR4[(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG - 1):CACHE_LINE_BYTE_WIDTH_LOG];
    wire [L1_CACHE_NUM_SETS_LOG-1:0] ADDR5_SET  =  ADDR5[(L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG - 1):CACHE_LINE_BYTE_WIDTH_LOG];

    integer cycle;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            cycle               <= 0;

            access_tag_en       <= '0;
            access_tag_set_idx  <= '0;

            access_tag          <= '0;

            access_data_en      <= '0;
            access_data_set_idx <= '0;

            update_tag_en       <= '0;
            update_tag_way_idx  <= '0;
            update_tag_set_idx  <= '0;
            update_tag          <= '0;
            update_tag_valid    <= '0;

            update_data_en      <= '0;
            update_data_way_idx <= '0;
            update_data_set_idx <= '0;
            update_data         <= '0;

            lru_fill_en         <= '0;
            lru_fill_set        <= '0;
        end else begin
            cycle               <= cycle + 1;

            access_tag_en       <= '0;
            access_tag_set_idx  <= '0;

            access_tag          <= '0;

            access_data_en      <= '0;
            access_data_set_idx <= '0;

            update_tag_en       <= '0;
            update_tag_way_idx  <= '0;
            update_tag_set_idx  <= '0;
            update_tag          <= '0;
            update_tag_valid    <= '0;

            update_data_en      <= '0;
            update_data_way_idx <= '0;
            update_data_set_idx <= '0;
            update_data         <= '0;

            lru_fill_en         <= '0;
            lru_fill_set        <= '0;

            case (cycle)
                /* fill addr1 */
                0: begin
                    // lookup fill way
                    lru_fill_en         <= 'h1;
                    lru_fill_set        <= ADDR1_SET;
                end

                1: begin
                    // fill tag
                    update_tag_en       <= 'h1;
                    update_tag_way_idx  <= lru_fill_way_idx;
                    update_tag_set_idx  <= ADDR1_SET;
                    update_tag          <= ADDR1_TAG;
                    update_tag_valid    <= 'h1;

                    // fill data
                    update_data_en      <= 'h1;
                    update_data_way_idx <= lru_fill_way_idx;
                    update_data_set_idx <= ADDR1_SET;
                    update_data         <= DATA1;
                end

                /* fill addr2 */
                2: begin
                    // lookup fill way
                    lru_fill_en         <= 'h1;
                    lru_fill_set        <= ADDR1_SET;
                end

                3: begin
                    // fill tag
                    update_tag_en       <= 'h1;
                    update_tag_way_idx  <= lru_fill_way_idx;
                    update_tag_set_idx  <= ADDR2_SET;
                    update_tag          <= ADDR2_TAG;
                    update_tag_valid    <= 'h1;

                    // fill data
                    update_data_en      <= 'h1;
                    update_data_way_idx <= lru_fill_way_idx;
                    update_data_set_idx <= ADDR2_SET;
                    update_data         <= DATA2;
                end

                /* fill addr3 */
                4: begin
                    // lookup fill way
                    lru_fill_en         <= 'h1;
                    lru_fill_set        <= ADDR3_SET;
                end

                5: begin
                    // fill tag
                    update_tag_en       <= 'h1;
                    update_tag_way_idx  <= lru_fill_way_idx;
                    update_tag_set_idx  <= ADDR3_SET;
                    update_tag          <= ADDR3_TAG;
                    update_tag_valid    <= 'h1;

                    // fill data
                    update_data_en      <= 'h1;
                    update_data_way_idx <= lru_fill_way_idx;
                    update_data_set_idx <= ADDR3_SET;
                    update_data         <= DATA3;
                end

                /* fill addr4 */
                6: begin
                    // lookup fill way
                    lru_fill_en         <= 'h1;
                    lru_fill_set        <= ADDR4_SET;
                end

                7: begin
                    // fill tag
                    update_tag_en       <= 'h1;
                    update_tag_way_idx  <= lru_fill_way_idx;
                    update_tag_set_idx  <= ADDR4_SET;
                    update_tag          <= ADDR4_TAG;
                    update_tag_valid    <= 'h1;

                    // fill data
                    update_data_en      <= 'h1;
                    update_data_way_idx <= lru_fill_way_idx;
                    update_data_set_idx <= ADDR4_SET;
                    update_data         <= DATA4;
                end

                /* read addr1 */
                8: begin
                    access_tag_en       <= 'h1;
                    access_tag_set_idx  <= ADDR1_SET;
                end

                9: begin
                    access_tag          <= ADDR1_TAG;

                    access_data_en      <= 'h1;
                    access_data_set_idx <= ADDR1_SET;
                end

                10: begin
                    assert(access_tag_hit == 'h1);
                end

                11: begin
                    assert(access_data == DATA1);
                end

                /* read addr2 */
                12: begin
                    access_tag_en       <= 'h1;
                    access_tag_set_idx  <= ADDR2_SET;
                end

                13: begin
                    access_tag          <= ADDR2_TAG;

                    access_data_en      <= 'h1;
                    access_data_set_idx <= ADDR2_SET;
                end

                14: begin
                    assert(access_tag_hit == 'h1);
                end

                15: begin
                    assert(access_data == DATA2);
                end

                /* read addr3 */
                16: begin
                    access_tag_en       <= 'h1;
                    access_tag_set_idx  <= ADDR3_SET;
                end

                17: begin
                    access_tag          <= ADDR3_TAG;

                    access_data_en      <= 'h1;
                    access_data_set_idx <= ADDR3_SET;
                end

                18: begin
                    assert(access_tag_hit == 'h1);
                end

                19: begin
                    assert(access_data == DATA3);
                end

                /* read addr4 */
                20: begin
                    access_tag_en       <= 'h1;
                    access_tag_set_idx  <= ADDR4_SET;
                end

                21: begin
                    access_tag          <= ADDR4_TAG;

                    access_data_en      <= 'h1;
                    access_data_set_idx <= ADDR4_SET;
                end

                22: begin
                    assert(access_tag_hit == 'h1);
                end

                23: begin
                    assert(access_data == DATA4);
                end

                /* read addr5 */
                24: begin
                    access_tag_en       <= 'h1;
                    access_tag_set_idx  <= ADDR5_SET;
                end

                25: begin
                    access_tag          <= ADDR5_TAG;
                end

                26: begin
                    assert(access_tag_hit == 'h0);
                end

                27: begin
                    $display("PASS");
                    $finish;
                end
            endcase
        end
    end
endmodule