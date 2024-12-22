`include "defines.vh"

module test_cache(input clk, input rst_n);

    reg                                     access_en       ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]       access_set      ;
    // second cycle
    reg                                     update_en       ;
    reg   [L1_CACHE_NUM_WAYS_LOG-1:0]       update_way_idx  ;

    reg                                     fill_en         ;
    reg   [L1_CACHE_NUM_SETS_LOG-1:0]       fill_set        ;

    wire  [L1_CACHE_NUM_WAYS_LOG-1:0]       fill_way_idx    ;

    cache_lru #(
        .NUM_WAYS   (L1_CACHE_NUM_WAYS) ,
        .NUM_SETS   (L1_CACHE_NUM_SETS)
    ) inst_cache_lru (
        .clk            (clk)               ,
        .rst_n          (rst_n)             ,

        .access_en      (access_en)         ,
        .access_set     (access_set)        ,

        .update_en      (update_en)         ,
        .update_way_idx (update_way_idx)    ,

        .fill_en        (fill_en)           ,
        .fill_set       (fill_set)          ,
        .fill_way_idx   (fill_way_idx)
    );

    integer cycle;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            cycle           <= 0;

            access_en       <= 'h0;
            access_set      <= 'h0;

            update_en       <= 'h0;
            update_way_idx  <= 'h0;

            fill_en         <= 'h0;
            fill_set        <= 'h0;

        end else begin
            cycle           <= cycle + 1;

            access_en       <= 'h0;
            access_set      <= 'h0;

            update_en       <= 'h0;
            update_way_idx  <= 'h0;

            fill_en         <= 'h0;
            fill_set        <= 'h0;

            case (cycle)
                // fill
                0: begin
                    // abc: 000
                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                1: begin
                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                2: begin
                    assert(fill_way_idx == 'h0);
                    // abc: 110

                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                3: begin
                    assert(fill_way_idx == 'h2);
                    // abc: 101

                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                4: begin
                    assert(fill_way_idx == 'h1);
                    // abc: 011

                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                5: begin
                    assert(fill_way_idx == 'h3);
                    // abc: 000

                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                6: begin
                    assert(fill_way_idx == 'h0);
                    // abc: 110

                    fill_en       <= 'h1;
                    fill_set      <= 'h8;
                end

                7: begin
                    assert(fill_way_idx == 'h2);
                    // abc: 101
                end

                8: begin
                    assert(fill_way_idx == 'h0);
                end

                // read
                9: begin
                    access_en   <= 'h1;
                    access_set  <= 'h0;
                end

                10: begin
                    update_en       <= 'h1;
                    update_way_idx  <= 'h0;

                    // fill
                    fill_en       <= 'h1;
                    fill_set      <= 'h0;
                end

                11: begin
                    // abc: 111
                end

                12: begin
                    assert(fill_way_idx == 'h3);
                    // abc: 100
                end

                13: begin
                    $display("PASS");
                    $finish;
                end
            endcase
        end
    end
endmodule