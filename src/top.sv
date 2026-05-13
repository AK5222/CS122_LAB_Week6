//Set-ExecutionPolicy -Scope Process Bypass -Force; . "C:\oss-cad-suite\oss-cad-suite\environment.ps1"; mkdir build -ErrorAction SilentlyContinue; yosys -p "synth_ecp5 -top top -json build/top.json" src/top.sv src/sprite_buf_Ex2.sv; nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json build/top.json --textcfg build/top.cfg --lpf top.lpf --freq 65; ecppack --svf build/top.svf build/top.cfg build/top.bit; icesprog build/top.bit

module top (
    input  CLK,

    // SPI slave (from Pico)
    input  spi_clk,
    input  spi_mosi,
    input  spi_cs,

    // LCD outputs
    output LCD_CLK,
    output LCD_DEN,
    output [4:0] LCD_R,
    output [5:0] LCD_G,
    output [4:0] LCD_B
);

assign LCD_CLK = CLK;

// ---------------- LCD raster (unchanged from Ex1) ----------------
logic [9:0] x_count;
logic [8:0] y_count;

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

logic [7:0]  pixel_address;
logic [15:0] pixel;
assign pixel_address = {y_count[3:0], x_count[3:0]};

// ---------------- SPI slave write path ----------------
logic        we;
logic [7:0]  waddr;
logic [15:0] wdata;

spi_slave u_spi (
    .clk   (CLK),
    .sck   (spi_clk),
    .mosi  (spi_mosi),
    .cs_n  (spi_cs),
    .we    (we),
    .waddr (waddr),
    .wdata (wdata)
);

dp_buffer sprite_mem (
    .clk   (CLK),
    .we    (we),
    .waddr (waddr),
    .wdata (wdata),
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


module spi_slave (
    input  logic clk,
    input  logic sck,
    input  logic mosi,
    input  logic cs_n,
    output logic we,
    output logic [7:0]  waddr,
    output logic [15:0] wdata
);
    logic [2:0] sck_q;
    logic [1:0] cs_q, mosi_q;

    always_ff @(posedge clk) begin
        sck_q  <= {sck_q[1:0], sck};
        cs_q   <= {cs_q[0],   cs_n};
        mosi_q <= {mosi_q[0], mosi};
    end

    wire sck_rise  = (sck_q[2:1] == 2'b01);
    wire cs_active = ~cs_q[1];

    logic [3:0]  bit_cnt;
    logic [15:0] shift;
    logic [7:0]  addr_reg;

    always_ff @(posedge clk) begin
        we <= 1'b0;
        if (!cs_active) begin
            bit_cnt <= 4'd0;
        end else if (sck_rise) begin
            shift <= {shift[14:0], mosi_q[1]};
            if (bit_cnt == 4'd15) begin
                bit_cnt  <= 4'd0;
                we       <= 1'b1;
                wdata    <= {shift[14:0], mosi_q[1]};
                waddr    <= addr_reg;
                addr_reg <= addr_reg + 8'd1;
            end else begin
                bit_cnt <= bit_cnt + 4'd1;
            end
        end
    end
endmodule
