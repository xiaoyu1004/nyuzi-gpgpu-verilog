module oh_to_idx #(
    parameter OH_WIDTH     = 4                ,
    parameter IDX_WIDTH   = $clog2(OH_WIDTH)
) (
    input   [OH_WIDTH-1 :0]       one_hot ,
    output  [IDX_WIDTH-1:0]       idx
);
    wire [IDX_WIDTH-1:0] gen_idx    [OH_WIDTH];

    genvar i;
    generate
        for (i = 0; i < OH_WIDTH; i = i + 1)
        begin : gen_for_blk_oh_to_idx
            assign gen_idx[i] = {IDX_WIDTH{one_hot[i]}} & IDX_WIDTH'(i);
        end
    endgenerate

    assign idx = gen_idx[0] | gen_idx[1] | gen_idx[2] | gen_idx[3];
endmodule