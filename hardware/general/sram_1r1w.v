`include "defines.vh"

// block ram, include 1 read port and 1 write port
// read and write are sync clk
// read new data when read and write in same cycle and same address 

module sram_1r1w #(
    parameter DATA_WIDTH        = 32,
    parameter SIZE              = 1024,
    parameter ADDR_WIDTH        = $clog2(SIZE),
    parameter READ_DURING_WRITE = "NEW_DATA"
) (
    input                           clk         ,

    input                           read_en     ,
    input       [ADDR_WIDTH-1:0]    read_addr   ,
    output      [DATA_WIDTH-1:0]    read_data   ,

    input                           write_en    ,
    input       [ADDR_WIDTH-1:0]    write_addr  ,
    input       [DATA_WIDTH-1:0]    write_data
);
`ifdef VENDOR_XILINX
    // TODO 
`else
    // SIMULATION
    reg [DATA_WIDTH-1:0] data[SIZE];
    reg [DATA_WIDTH-1:0] read_data_r;

    // read port
    always @(posedge clk) begin
        if (read_en && write_en && read_addr == write_addr) begin
            if (READ_DURING_WRITE == "NEW_DATA") begin
                read_data_r     <= write_data;
            end else begin
                read_data_r     <= data[read_addr];
            end
        end else if (read_en) begin
            read_data_r         <= data[read_addr];
        end
    end

    assign read_data = read_data_r;

    // write port
    always @(posedge clk) begin
        if (write_en) begin
            data[write_addr]    <= write_data;
        end
    end

`endif
endmodule