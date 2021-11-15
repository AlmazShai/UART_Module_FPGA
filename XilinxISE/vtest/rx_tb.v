`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:43:58 11/14/2021
// Design Name:   uart_rx
// Module Name:   E:/projects/Xilinx/UART/XilinxISE/vsource/rx_tb.v
// Project Name:  UART_Test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: uart_rx
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module rx_tb;

	// Inputs
	reg clk;
	reg rst;
	reg rx;
	reg data_readed;

	// Outputs
	wire [7:0]out_data;
	wire data_ready;
	wire overwritten;
	wire parity_error;

	// Instantiate the Unit Under Test (UUT)
	uart_rx #(	.BAUD_RATE(9600),
				.PARITY_BIT(2),
				.DATA_LEN(8),
				.STOP_BIT(1),
				.CLK_FREQ(50_000_000))
	uut(
		.clk(clk), 
		.rst(rst), 
		.rx(rx), 
		.data_readed(data_readed), 
		.out_data(out_data), 
		.data_ready(data_ready), 
		.overwritten(overwritten), 
		.parity_error(parity_error)
	);

localparam SEND_BITS_SIZE = 11;
localparam SEND_BYTE = 8'b0100_1001;

integer i;

reg [SEND_BITS_SIZE - 1 : 0] send_data = {1'b1, 1'b1, SEND_BYTE, 1'b0};
reg [SEND_BITS_SIZE - 1 : 0] send_data2 = {1'b1, 1'b0, SEND_BYTE, 1'b0};

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		rx = 1;
		data_readed = 0;

		// Wait 100 ns for global reset to finish
		#10;
		rst = 1;
		#50;
		for(i = 0; i < SEND_BITS_SIZE; i = i + 1) begin
			rx <= send_data[i];
			#104000;
		end
        wait(data_ready);
		if(parity_error) begin
			$display("Patiry error");
		end
		if(overwritten) begin
			$display("Data overwritten");
		end
		if(out_data == SEND_BYTE) begin
			$display("Data equal");
		end
		else begin
			$display("Data not equal");
		end
		#20;
		data_readed = 1;
		#50;
		data_readed = 0;
		#50;
		for(i = 0; i < SEND_BITS_SIZE; i = i + 1) begin
			rx <= send_data2[i];
			#104000;
		end
        wait(data_ready);
		if(parity_error) begin
			$display("Patiry error");
		end
		if(overwritten) begin
			$display("Data overwritten");
		end
		if(out_data == SEND_BYTE) begin
			$display("Data equal");
		end
		else begin
			$display("Data not equal");
		end
		#20;
		data_readed = 1;
		#50;
		data_readed = 0;
		$finish;
		// Add stimulus here

	end

	always begin
		clk = ~clk;
		#10;
	end
      
endmodule

