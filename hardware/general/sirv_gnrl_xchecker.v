
`ifdef SIMULATION//{
`ifdef ENABLE_SV_ASSERTION//{

module sirv_gnrl_xchecker # (
    parameter DW = 32
) (
    input  [DW-1:0] i_dat   ,

    input           clk
);

CHECK_THE_X_VALUE:
  assert property (@(posedge clk) 
                     ((^(i_dat)) !== 1'bx)
                  )
  else $fatal ("\n Error: Oops, detected a X value!!! This should never happen. \n");

endmodule

`endif
`endif