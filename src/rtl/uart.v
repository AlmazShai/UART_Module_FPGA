`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:33:07 11/21/2021 
// Design Name: 
// Module Name:    uart 
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
module uart
    #(  parameter CLK_FREQ = 50_000_000,
		parameter BAUD_RATE = 9600,
		parameter PARITY_BIT = 0,
		parameter DATA_LEN = 8,
		parameter STOP_BIT = 1)
    (
    input rst,
    input clk,
    input [DATA_LEN - 1 : 0] tx_data,
    input rx_data_readed,
    input rx,
    output tx,
    output tx_empty,
    output rx_data_ready,
    output rx_overwritten,
    output rx_parity_error,
    output [DATA_LEN - 1 : 0] rx_data
    );

uart_rx #(  .CLK_FREQ(CLK_FREQ),
		    .BAUD_RATE(BAUD_RATE),
		    .PARITY_BIT(PARITY_BIT),
		    .DATA_LEN(DATA_LEN),
		    .STOP_BIT(STOP_BIT))
my_uart_rx
(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .data_readed(rx_data_readed),
    .out_data(rx_data),
    .data_ready(rx_data_ready),
    .overwritten(rx_overwritten),
    .parity_error(rx_parity_error)
);

uart_tx #(  .CLK_FREQ(CLK_FREQ),
		    .BAUD_RATE(BAUD_RATE),
		    .PARITY_BIT(PARITY_BIT),
		    .DATA_LEN(DATA_LEN),
		    .STOP_BIT(STOP_BIT))
my_uart_tx
(
    .rst(rst),
    .clk(clk),
    .data(tx_data),
    .tx_empty(tx_empty),
	.tx(tx)
);

endmodule
