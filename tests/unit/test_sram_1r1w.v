module test_sram_1r1w(input clk, input rst_n);
    localparam DATA_WIDTH   = 32;
    localparam SIZE         = 64;
    localparam ADDR_WIDTH   = $clog2(SIZE);

    reg                     read_en;
    reg [ADDR_WIDTH-1:0]    read_addr;
    reg [DATA_WIDTH-1:0]    read_data1;
    reg [DATA_WIDTH-1:0]    read_data2;

    reg                     write_en;
    reg [ADDR_WIDTH-1:0]    write_addr;
    reg [DATA_WIDTH-1:0]    write_data;

    sram_1r1w #(
        .DATA_WIDTH         (DATA_WIDTH),
        .SIZE               (SIZE),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .READ_DURING_WRITE  ("NEW_DATA")
    ) inst_ram1 (
        .clk                (clk),

        .read_en            (read_en),
        .read_addr          (read_addr),
        .read_data          (read_data1),

        .write_en           (write_en),
        .write_addr         (write_addr),
        .write_data         (write_data)
    );

    sram_1r1w #(
        .DATA_WIDTH         (DATA_WIDTH),
        .SIZE               (SIZE),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .READ_DURING_WRITE  ("DONT_CARE")
    ) inst_ram2 (
        .clk                (clk),

        .read_en            (read_en),
        .read_addr          (read_addr),
        .read_data          (read_data2),

        .write_en           (write_en),
        .write_addr         (write_addr),
        .write_data         (write_data)
    );

    localparam ADDR1 = 12;
    localparam ADDR2 = 17;
    localparam ADDR3 = 19;

    localparam DATA1 = 'h245fa7d4;
    localparam DATA2 = 'h7b8261b;
    localparam DATA3 = 'h47b06ea2;
    localparam DATA4 = 'hdff64bb1;

    integer cycle;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            cycle       <= 0;
            read_en     <= 1'b0;
            write_en    <= 1'b0;
        end else begin
            cycle       <=  cycle + 1;
            read_en     <= 1'b0;
            write_en    <= 1'b0;

            case (cycle)
                // write some value
                0: begin
                    write_en    <= 1'b1;
                    write_addr  <= ADDR1;
                    write_data  <= DATA1;
                end

                1: begin
                    write_en    <= 1'b1;
                    write_addr  <= ADDR2;
                    write_data  <= DATA2;
                end

                // read them back
                2: begin
                    read_en     <= 1'b1;
                    read_addr   <= ADDR1;
                end

                4: begin
                    assert(read_data1 == DATA1);
                    assert(read_data2 == DATA1);
                end

                // read and write at same time, but diffrence adress
                5: begin
                    read_en     <= 1'b1;
                    read_addr   <= ADDR2;

                    write_en    <= 1'b1;
                    write_addr  <= ADDR3;
                    write_data  <= DATA3;
                end

                7: begin
                    assert(read_data1 == DATA2);
                    assert(read_data2 == DATA2);

                    // read back the written value
                    read_en     <= 1'b1;
                    read_addr   <= ADDR3;
                end

                9: begin
                    assert(read_data1 == DATA3);
                    assert(read_data2 == DATA3);
                end

                // read and write the same address simultaneously
                10: begin
                    read_en     <= 1'b1;
                    read_addr   <= ADDR3;

                    write_en    <= 1'b1;
                    write_addr  <= ADDR3;
                    write_data  <= DATA4;
                end

                12: begin
                    assert(read_data1 == DATA4);
                    assert(read_data2 != DATA4);
                end

                13: begin
                    // read back the address, ensure it write correctly
                    read_en     <= 1'b1;
                    read_addr   <= ADDR3;
                end

                15: begin
                    assert(read_data1 == DATA4);
                    assert(read_data2 == DATA4);
                end

                11: begin
                    $display("PASS");
                    $finish;
                end
            endcase
        end
    end
endmodule