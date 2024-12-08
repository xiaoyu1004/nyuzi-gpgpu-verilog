`include "defines.vh"

//
// ===========================================================================
//
// Description:
//  Verilog module sirv_gnrl DFF with Load-enable and Reset
//  Default reset value is 1
//
// ===========================================================================

module sirv_gnrl_dfflrs # (
    parameter DW = 32
) (
    input               lden    , 
    input      [DW-1:0] dnxt    ,
    output     [DW-1:0] qout    ,

    input               clk     ,
    input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n) 
begin : DFFLRS_PROC
    if (rst_n == 1'b0) begin
        qout_r <= {DW{1'b1}};
    end else if (lden == 1'b1) begin
        qout_r <= dnxt;
    end
end

assign qout = qout_r;

`ifdef SIMULATION//{
`ifdef ENABLE_SV_ASSERTION//{
//synopsys translate_off
sirv_gnrl_xchecker # (
  .DW(1)
) sirv_gnrl_xchecker(
  .i_dat(lden),
  .clk  (clk)
);
//synopsys translate_on
`endif//}
`endif//}
    

endmodule