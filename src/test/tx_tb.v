`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:08:33 11/20/2021
// Design Name:   uart_tx
// Module Name:   E:/projects/Xilinx/UART/XilinxISE/vtest/uart_tx_test.v
// Project Name:  UART_Test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: uart_tx
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module uart_tx_test;

	// Inputs
	reg rst;
	reg clk;
	reg [7:0] data;

	// Outputs
	wire tx_empty;
	wire tx;

	reg[SEND_BYTE_SIZE - 1:0] r_read;
	//parameters
	localparam WRITE_BYTES = 8'b01101100;
	localparam SEND_BYTE_SIZE = 8;
	localparam PARITY_BIT = 1'b0;
	//variables
	integer i;

	// Instantiate the Unit Under Test (UUT)
	uart_tx 	#(.BAUD_RATE(9600),
				.PARITY_BIT(2),
				.DATA_LEN(8),
				.STOP_BIT(1),
				.CLK_FREQ(50_000_000))
	uut
	(
		.rst(rst), 
		.clk(clk), 
		.data(data), 
		.tx_empty(tx_empty),
		.tx(tx)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		clk = 0;
		data = 0;
		#50;
		rst = 1;
		#50;
		data = WRITE_BYTES;
		wait(tx == 0);
		#52000;
		if(tx != 0) begin
			$display("Staer bit error");
		end
		for(i = 0; i < SEND_BYTE_SIZE; i = i + 1) begin
			#104000;
			r_read[i] = tx;
		end
		#104000;
		if(tx != PARITY_BIT) begin
			$display("Parity error");
		end
		#104000
		if(tx != 1'b1) begin
			$display("Stop bit error");
		end
		if(r_read != WRITE_BYTES) begin
			$display("Data error");
		end
		wait(tx_empty == 1);
		#50;
		$finish;

		
        
		// Add stimulus here

	end

	always begin
		clk = ~clk;
		#10;
	end
      
endmodule

