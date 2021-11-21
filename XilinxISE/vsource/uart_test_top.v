`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:37:31 11/13/2021 
// Design Name: 
// Module Name:    uart_test_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_test_top(
    input rst,
    input clk,
    input uart_rx,
    output uart_tx
    );

localparam  STATE_WAIT_RX = 2'd0,
            STATE_TX_LOAD = 2'd1,
            STATE_WAIT_TX_EMPTY = 2'd2;

reg rx_readed = 1'b0;
reg [7:0] data_echo = 8'd0;
reg [1:0] state = STATE_WAIT_RX;
reg [1:0] next_state = STATE_WAIT_RX;

wire rx_ready;
wire [7:0] rx_data;
wire rx_empty;

uart #( .CLK_FREQ (50_000_000),
		.BAUD_RATE(9600),
		.PARITY_BIT(0),
		.DATA_LEN(8),
		.STOP_BIT(1))
uart_test
(
    .rst(rst),
    .clk(clk),
    .tx_data(data_echo),
    .rx_data_readed(rx_readed),
    .rx(uart_rx),
    .tx(uart_tx),
    .tx_empty(tx_empty),
    .rx_data_ready(rx_ready),
    .rx_data(rx_data)
);

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= STATE_WAIT_RX;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case(state)
        STATE_WAIT_RX : begin
            if(rx_ready) begin
                next_state = STATE_TX_LOAD;
            end
            else begin
                next_state = STATE_WAIT_RX;
            end
            rx_readed = 0;
            data_echo = rx_data;
        end
        STATE_TX_LOAD : begin
            next_state = STATE_WAIT_TX_EMPTY;
            data_echo = rx_data;
            rx_readed = 1'b1;
        end
        STATE_WAIT_TX_EMPTY : begin
            if(tx_empty) begin
                next_state = STATE_WAIT_RX;
            end
            else begin
                next_state = STATE_WAIT_TX_EMPTY;
            end
            rx_readed = 1'b0;
            data_echo = 0;
        end
        default : begin
            next_state = STATE_WAIT_RX;
        end
    endcase
end 


endmodule
