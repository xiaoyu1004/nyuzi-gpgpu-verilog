module test_rr_arbiter(input clk, input rst_n);
localparam NUM_REQUESTERS = 4;

reg [NUM_REQUESTERS-1:0] req_bitmap;
reg                      update_en;

reg [NUM_REQUESTERS-1:0]  grant_oh;

rr_arbiter #(
    .NUM_REQUESTERS (NUM_REQUESTERS)
) inst_rr_arbiter (
    .clk            (clk)           ,
    .rst_n          (rst_n)         ,

    .req_bitmap     (req_bitmap)    ,
    .update_en      (update_en)     ,

    .grant_oh       (grant_oh)
);

integer cycle = 0;

always @(posedge clk or negedge rst_n) 
begin
    if (rst_n == 1'b0) begin
        cycle       <= 0;
        req_bitmap  <= {NUM_REQUESTERS{1'b0}};
        update_en   <= 1'b0;
    end else begin
        cycle <=    cycle + 1;

        case (cycle)
            0: begin
                req_bitmap  <= {NUM_REQUESTERS{1'b1}};
                update_en   <= 1'b1;
            end

            1: assert(grant_oh == 4'b0001); // priority: 0001
            2: assert(grant_oh == 4'b0010); // priority: 0010
            3: assert(grant_oh == 4'b0100); // priority: 0100
            4: assert(grant_oh == 4'b1000); // priority: 1000

            // update_en clear, ensure it doesn't update
            5: begin
                assert(grant_oh == 4'b0001); // priority: 0001
                update_en   <= 1'b0;
            end

            6: assert(grant_oh == 4'b0010); // priority: 0010  update_en: 0
            7: assert(grant_oh == 4'b0010); // priority: 0010  update_en: 0
            8: assert(grant_oh == 4'b0010); // priority: 0010  update_en: 0

            // Two bit set
            9: begin
                assert(grant_oh == 4'b0010); // priority: 0010  update_en: 0
                update_en   <= 1'b1;
                req_bitmap  <= 4'b0101;
            end

            10: assert(grant_oh == 4'b0100); // priority: 0010  update_en: 1
            11: assert(grant_oh == 4'b0001); // priority: 1000  update_en: 1
            12: assert(grant_oh == 4'b0100); // priority: 0010  update_en: 1

            13: begin
                assert(grant_oh == 4'b0001); // priority: 1000  update_en: 1
                req_bitmap  <= 4'b1010;
            end

            14: assert(grant_oh == 4'b0010); // priority: 0010  update_en: 1
            15: assert(grant_oh == 4'b1000); // priority: 0100  update_en: 1

            // One bit set
            16: begin
                assert(grant_oh == 4'b0010); // priority: 0001  update_en: 1
                req_bitmap  <= 4'b0100;
            end

            17: assert(grant_oh == 4'b0100); // priority: 0100  update_en: 1
            18: assert(grant_oh == 4'b0100); // priority: 1000  update_en: 1

            // No request 
            19: begin
                assert(grant_oh == 4'b0100); // priority: 1000  update_en: 1
                req_bitmap  <= 4'b0000;
            end

            20: assert(grant_oh == 4'b0000); // priority: 1000  update_en: 1
            21: assert(grant_oh == 4'b0000); // priority: 1000  update_en: 1

            22: begin
                $display("PASS");
                $finish;
            end

        endcase
    end
end
endmodule