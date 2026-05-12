module top (
    /** Input Ports */
    input  CLK,

    /** Output Ports */
    output LCD_CLK,
    output LCD_DEN,
    output [4:0] LCD_R,
    output [5:0] LCD_G,
    output [4:0] LCD_B
);

/** Logic */
assign LCD_CLK = CLK;

logic [9:0] x_count;
logic [8:0] y_count;

// Horizontal/Vertical counters
always_ff @(posedge CLK) begin
    if (x_count == 10'd524) begin
        x_count <= 10'd0;
        if (y_count == 9'd284)
            y_count <= 9'd0;
        else
            y_count <= y_count + 1;
    end else begin
        x_count <= x_count + 1;
    end
end

assign LCD_DEN = (x_count < 10'd480) && (y_count < 9'd272);


logic [3:0] sprite_x, sprite_y;
logic [7:0] pixel_address;
logic [15:0] pixel;

assign sprite_x = x_count[3:0];        // x_count % 16
assign sprite_y = y_count[3:0];        // y_count % 16
assign pixel_address = {sprite_y, sprite_x}; // sprite_y*16 + sprite_x

dp_buffer sprite_mem (
    .clk   (CLK),
    .raddr (pixel_address),
    .rdata (pixel)
);

always_comb begin
    if (!LCD_DEN) begin
        LCD_R = 5'd0;
        LCD_G = 6'd0;
        LCD_B = 5'd0;
    end else begin
        LCD_R = pixel[15:11];
        LCD_G = pixel[10:5];
        LCD_B = pixel[4:0];
    end
end

endmodule