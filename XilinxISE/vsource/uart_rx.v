`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:53:26 11/13/2021 
// Design Name: 
// Module Name:    uart_rx 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// Parity bit settings 
//		PARITY_BIT = 0 - no patity
//		PARITY_BIT = 1 - odd patiry
//		PARITY_BIT = 2 - even parity
// Stop bit settings
//		STOP_BIT = 1 - stop bit 1
//		STOP_BIT = 2 - stop bit 2
//		STOP_BIT = 3 - stop bit 1.5
// Dependencies: 
//		baud_rate.v
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_rx
		#(parameter BAUD_RATE = 9600,
			parameter PARITY_BIT = 0,
			parameter DATA_LEN = 8,
			parameter STOP_BIT = 1,
			parameter CLK_FREQ = 50_000_000)
(
    input clk,
    input rst,
    input rx,
	input data_readed,
    output [DATA_LEN - 1 : 0] out_data,
    output data_ready,
	output overwritten,
	output parity_error
);

wire baud_tick;
reg prev_baud_tick = 0; // previous baud tick
reg rx_enable = 0;

baud_rate #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) rx_baud
(
	.clk(clk),
	.enable(rx_enable),
	.baud_rate(baud_tick)
);


localparam 	STATE_READY 		= 3'd0,
			STATE_START_BIT 	= 3'd1,
			STATE_DATA_BITS 	= 3'd2,
			STATE_PARITY_BIT 	= 3'd3,
			STATE_STOP_BIT 		= 3'd4,
			STATE_FINISH	 	= 3'd5;

localparam START_BIT_TICKS = 2;
localparam PARITY_BIT_TICKS = ((PARITY_BIT == 1) || (PARITY_BIT == 2)) ? 2 : 0;
localparam DATA_BITS_TICKS = DATA_LEN * 2;
localparam STOP_BIT_TICKS = (STOP_BIT == 1) ? 2 : ((STOP_BIT == 2) ? 4 : ((STOP_BIT == 3) ? 3 : 0));
				
reg [2:0] state = STATE_READY;
reg [2:0] next_state = STATE_READY;

reg [DATA_LEN - 1 : 0] data_reg = 0;
reg [4:0] baud_tick_count = 5'b0;
reg parity = 1'b0;
reg stop_flag = 1'b1;

// Output registers
reg [DATA_LEN - 1 : 0] r_out_data = 0;
reg r_data_ready = 1'b0;
reg r_overwritten = 1'b0;
reg r_parity_error = 1'b0;

always @(posedge clk or negedge rst)
begin
	if(!rst) begin
		state <= STATE_READY;
		next_state <= STATE_READY;
	end
	else begin
		state <= next_state;
	end
end

// State machine
always @(*)
begin
	next_state = STATE_READY;
	rx_enable = 1'b1;
	case (state)
		STATE_READY : begin
			if(~rx) begin
				rx_enable = 1'b1;
				next_state = STATE_START_BIT;
			end
			else begin
				rx_enable = 1'b0;
			end
		end
		STATE_START_BIT : begin
			if(baud_tick_count == 3'd1) begin
				if(rx == 1'b0) begin
					next_state = STATE_DATA_BITS;
				end
				else begin
					next_state = STATE_READY;
				end
			end
			else begin
				next_state = STATE_START_BIT;
			end
		end
		STATE_DATA_BITS : begin
			if(baud_tick_count == (DATA_BITS_TICKS + START_BIT_TICKS)) begin
				if((PARITY_BIT == 1) || (PARITY_BIT == 2)) begin
					next_state = STATE_PARITY_BIT;
				end
				else begin
					next_state = STATE_STOP_BIT;
				end
			end
			else begin
				next_state = STATE_DATA_BITS;
			end
		end
		STATE_PARITY_BIT : begin
			if(baud_tick_count == (DATA_BITS_TICKS + START_BIT_TICKS + PARITY_BIT_TICKS)) begin
				next_state = STATE_STOP_BIT;
			end
			else begin
				next_state = STATE_PARITY_BIT;
			end
		end
		STATE_STOP_BIT : begin
			if(baud_tick_count == (DATA_BITS_TICKS + START_BIT_TICKS + PARITY_BIT_TICKS + STOP_BIT_TICKS)) begin
				next_state = STATE_FINISH;
			end
			else begin
				next_state = STATE_STOP_BIT;
			end
		end
		STATE_FINISH : begin
			next_state = STATE_READY;
			rx_enable = 1'b0;
		end
		default : begin
			next_state = STATE_READY;
		end
	endcase
end

// Baud tick pevious state keep for rising edge determinig
always @(posedge clk or negedge rst) begin
	if(~rst) begin 
		prev_baud_tick <= 1'b0;
	end
	else begin
		prev_baud_tick <= baud_tick;
	end
end

// Baud ticks count increment
always @(posedge clk or negedge rx_enable)
begin
	if(~rx_enable) begin
		baud_tick_count <= 0;
	end
	else if((baud_tick != prev_baud_tick) && baud_tick) begin	//posedge of baud_tick
		baud_tick_count <= baud_tick_count + 5'b1;
	end
	else begin
		baud_tick_count <= baud_tick_count;
	end
end

// Shift register for data
always @(posedge clk) begin
	if((baud_tick != prev_baud_tick) && baud_tick) begin		//posedge of baud_tick
		if(state == STATE_DATA_BITS) begin
			if(baud_tick_count[0] == 1'b0) begin 	//detect even baud ticks
				data_reg <= {rx, data_reg[DATA_LEN - 1 : 1]};
			end
			else begin
				data_reg <= data_reg;
			end
		end
		else if(state != STATE_READY) begin
			data_reg <= data_reg;
		end
		else begin
			data_reg <= 0;
		end
	end
	else begin
		data_reg <= data_reg;
	end
end

// Parity bit keep
always @(posedge clk) begin
	if((state == STATE_PARITY_BIT) 
		&& (baud_tick_count == DATA_BITS_TICKS + START_BIT_TICKS)
		&& ((baud_tick != prev_baud_tick) && baud_tick)) begin
		parity <= rx;
	end
	else begin
		parity <= parity;
	end
end

// Stop bit keep
always @(posedge clk) begin
	if((state == STATE_STOP_BIT)
		&& ((baud_tick != prev_baud_tick) && baud_tick)) begin
		stop_flag <= stop_flag & rx;
	end
	else if(state != STATE_READY) begin
		stop_flag <= stop_flag;
	end
	else begin
		stop_flag <= 1'b1;
	end
end

// Output registers update
always @(posedge clk or negedge rst or data_readed) begin
	if(~rst || data_readed) begin
		r_out_data <= 0;
		r_overwritten <= 1'b0;
		r_parity_error <= 1'b0;
		r_data_ready <= 1'b0;
	end
	else if((state == STATE_FINISH) && (stop_flag)) begin
		if((PARITY_BIT == 1) && (parity & ^data_reg)) begin
			r_parity_error <= 1'b1;
		end
		else if((PARITY_BIT == 2) && ~(parity & ^data_reg)) begin
			r_parity_error <= 1'b1;
		end
		else begin
			r_parity_error <= 1'b0;
		end
		if(r_data_ready) begin
			r_overwritten <= 1'b1;
		end
		else begin
			r_overwritten <= 1'b0;
		end
		r_out_data <= data_reg;
		r_data_ready <= 1'b1;
	end
	else begin
		r_parity_error <= parity_error;
		r_overwritten <= r_overwritten;
		r_data_ready <= r_data_ready;
		r_out_data <= r_out_data;
	end
end

assign parity_error = r_parity_error;
assign overwritten = r_overwritten;
assign data_ready = r_data_ready;
assign out_data = r_out_data;

endmodule
