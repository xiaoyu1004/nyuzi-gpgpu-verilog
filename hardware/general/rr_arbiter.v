module rr_arbiter #(
    parameter NUM_REQUESTERS = 4
) (
    input                           clk             ,
    input                           rst_n           ,

    input   [NUM_REQUESTERS-1:0]    req_bitmap      ,
    input                           update_en       ,

    output  [NUM_REQUESTERS-1:0]    grant_oh
);

localparam PRIORITY_OH_RST_V = {{(NUM_REQUESTERS-1){1'b0}}, 1'b1};

wire [NUM_REQUESTERS-1:0] priority_oh;

wire [NUM_REQUESTERS-1:0] priority_oh_nxt = {grant_oh[NUM_REQUESTERS-2:0], grant_oh[NUM_REQUESTERS-1]};

wire lden = update_en && (|req_bitmap);

sirv_gnrl_dfflrs_val #(
    .DW (NUM_REQUESTERS)
) priority_oh_dff (
    .lden   (lden)              ,
    .dnxt   (priority_oh_nxt)   ,
    .qout   (priority_oh)       ,

    .clk    (clk)               ,
    .rst_n  (rst_n)             ,
    .rst_v  (PRIORITY_OH_RST_V) 
);

wire [2*NUM_REQUESTERS-1:0] req_rpt_bitmap  = {req_bitmap, req_bitmap};
wire [2*NUM_REQUESTERS-1:0] grant_oh_rpt    = ~(req_rpt_bitmap - ({{NUM_REQUESTERS{1'b0}}, priority_oh})) & req_rpt_bitmap;

assign grant_oh = grant_oh_rpt[2*NUM_REQUESTERS-1:NUM_REQUESTERS] | grant_oh_rpt[NUM_REQUESTERS-1:0];
    
endmodule
