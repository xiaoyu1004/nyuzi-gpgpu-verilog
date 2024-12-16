`ifndef DEFINES_VH
`define DEFINES_VH

`include "config.vh"

// `define VENDOR_XILINX

/* core */
parameter NUM_WARP_PER_CORE     = 4;
parameter NUM_WARP_PER_CORE_LOG = $clog2(NUM_WARP_PER_CORE);

parameter ADDR_WIDTH            = 32;
parameter DATA_WIDTH            = 32;

/* pipeline regs */
parameter IFT_TO_IFD_BUS_WIDTH  = ADDR_WIDTH + NUM_WARP_PER_CORE_LOG;

/* cache */

parameter L1_CACHE_NUM_WAYS_LOG   = $clog2(L1_CACHE_NUM_WAYS);
parameter L1_CACHE_NUM_SETS_LOG   = $clog2(L1_CACHE_NUM_SETS);

parameter CACHE_LINE_BYTE_WIDTH   = NUM_VECTOR_LANES * 4;
parameter CACHE_LINE_BIT_WIDTH    = CACHE_LINE_BYTE_WIDTH * 8;
parameter CACHE_LINE_WORD_WIDTH   = CACHE_LINE_BYTE_WIDTH / 4;

parameter CACHE_LINE_BYTE_WIDTH_LOG  = $clog2(CACHE_LINE_BYTE_WIDTH);
parameter CACHE_LINE_TAG_WIDTH       = 32 - (L1_CACHE_NUM_SETS_LOG + CACHE_LINE_BYTE_WIDTH_LOG);

`endif