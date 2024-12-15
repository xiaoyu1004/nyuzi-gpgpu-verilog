module idx_to_oh #(
    parameter IDX_WIDTH   = 2               ,
    parameter OH_WIDTH    = (1 << IDX_WIDTH)  
) (
    input   [IDX_WIDTH-1:0]       idx       ,
    output  [OH_WIDTH-1 :0]       one_hot 
);
    genvar i;
    generate
        for (i = 0; i < OH_WIDTH; i = i + 1)
        begin : gen_for_blk_idx_to_oh
            assign one_hot[i] = (idx == IDX_WIDTH'i);
        end
    endgenerate
endmodule