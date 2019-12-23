module vga_signals(
    input wire i_clk,           // base clock
    input wire i_rst,           // reset: restarts frame
    output wire o_hs,           // horizontal sync
    output wire o_vs,           // vertical sync
    output wire o_active,       // high during active pixel drawing
    output wire [9:0] o_x,      // current pixel x position
    output wire [9:0] o_y       // current pixel y position
    );

    localparam HS_STA = (512+12)/2;             // horizontal sync start
    localparam HS_END = (512+12 + 68)/2;        // horizontal sync end
    localparam VS_STA = 768 + 3;        	// vertical sync start
    localparam VS_END = 768 + 3 + 6;    	// vertical sync end
    localparam VA_END = 768;             	// vertical active pixel end
    localparam LINE   = ((512+ 12 + 68 + 80)/2)-1;  // complete line (pixels)
    localparam SCREEN = 806-1;            	// complete screen (lines)

    reg [9:0] h_count;  // line position
    reg [9:0] v_count;  // screen position

    // generate horizontal & vertical sync signals (both active low for 640x480)
    assign o_hs = ~((h_count >= HS_STA) & (h_count < HS_END));
    assign o_vs = ~((v_count >= VS_STA) & (v_count < VS_END));

    // keep x and y bound within the active pixels
    assign o_x = h_count;
    assign o_y = v_count;

    // active: high during active pixel drawing
    assign o_active = (~h_count[8])&(~(v_count[9]&v_count[8]));

    always @ (posedge i_clk)
    begin
        if (i_rst)  // reset to start of frame
        begin
            h_count <= 0;
            v_count <= 0;
        end
        else
        begin
            if (h_count == LINE)  // end of line
            begin
                h_count <= 0;
                v_count <= v_count + 1;
                if (v_count == SCREEN)  // end of screen
					v_count <= 0;
            end
            else 
                h_count <= h_count + 1;
        end
    end
endmodule
