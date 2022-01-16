`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:08:23 11/21/2021
// Design Name:   uart_test_top
// Module Name:   E:/projects/Xilinx/UART/XilinxISE/vtest/uart_full_test_tb.v
// Project Name:  UART_Test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: uart_test_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module uart_full_test_tb;

	localparam SEND_BITS_SIZE = 10;
	localparam SEND_BYTE = 8'b0100_1001;
	// Inputs
	reg rst;
	reg clk;
	reg uart_rx;

	// Outputs
	wire uart_tx;

	integer i;

	reg [SEND_BITS_SIZE - 1 : 0] send_data = {1'b1, SEND_BYTE, 1'b0};

	// Instantiate the Unit Under Test (UUT)
	uart_test_top uut (
		.rst(rst), 
		.clk(clk), 
		.uart_rx(uart_rx), 
		.uart_tx(uart_tx)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		clk = 0;
		uart_rx = 1;

		#10;
		rst = 1;
		#50;
		for(i = 0; i < SEND_BITS_SIZE; i = i + 1) begin
			uart_rx <= send_data[i];
			#104000;
		end

        
		// Add stimulus here

	end

	always begin
		clk = ~clk;
		#10;
	end
      
endmodule

