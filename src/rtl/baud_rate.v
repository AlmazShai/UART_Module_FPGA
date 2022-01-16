`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:39:39 11/13/2021 
// Design Name: 
// Module Name:    baud_rate 
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
module baud_rate
	#(parameter CLK_FREQ = 50_000_00,
	  parameter BAUD_RATE = 9600)(
    input clk,
	input enable,
    output baud_rate
    );

localparam MAX_COUNT = CLK_FREQ / (BAUD_RATE * 4);

reg [16:0] counter = 0;
reg r_baud_rate = 1'b1;

always @(posedge clk)
begin
	if(enable == 1) begin
		if(counter == MAX_COUNT) begin
			counter <= 0;
			r_baud_rate <= ~r_baud_rate;
		end
		else begin
			counter <= counter + 1'b1;
			r_baud_rate <= r_baud_rate;
		end
	end
	else begin
		counter <= 0;
		r_baud_rate <= 1'b1;
	end
end

assign baud_rate = r_baud_rate;

endmodule
