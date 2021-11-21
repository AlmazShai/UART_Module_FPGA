`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Shaydullin Almaz almazshai@gmail.com
// 
// Create Date:    12:07:30 11/20/2021 
// Design Name: 
// Module Name:    uart_tx 
// Project Name: 
// Target Devices: 
// Tool versions: Xilinx ISE 14.7
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
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_tx 
	#(	parameter CLK_FREQ = 50_000_000,
		parameter BAUD_RATE = 9600,
		parameter PARITY_BIT = 0,
		parameter DATA_LEN = 8,
		parameter STOP_BIT = 1)
	(
    input rst,
    input clk,
    input [DATA_LEN - 1: 0] data,
    output tx_empty,
	output tx
    );


wire baud_tick;
reg tx_enable;

baud_rate #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) tx_baud
(
	.clk(clk),
	.enable(tx_enable),
	.baud_rate(baud_tick)
);

localparam 	STATE_READY = 3'd0,
			STATE_START_BIT = 3'd1,
			STATE_DATA_BITS = 3'd2,
			STATE_PARITY_BIT = 3'd3,
			STATE_STOP_BIT = 3'd4;

localparam START_BIT_TICKS = 2;
localparam DATA_BIT_TICKS = DATA_LEN * 2;
localparam PARITY_BIT_TICKS = (PARITY_BIT == 0) ? 0 : 2;
localparam STOP_BIT_TICKS = (STOP_BIT == 1) ? 2 : ((STOP_BIT == 2) ? 4 : 3);

reg [2:0] state = STATE_READY;
reg [2:0] next_state = STATE_READY;

reg [DATA_LEN - 1 : 0] r_data_old = 0;
reg new_data_present = 1'b0;
reg [4:0] baud_tick_count = 5'b0;
reg [4:0] prev_baud_tick_count = 5'd0;
reg prev_baud_tick = 1'b0;

//out register
reg r_tx = 1'b1;
reg r_tx_empty = 1'b1;

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		state <= STATE_READY;
	end
	else begin
		state <= next_state;
	end
end

always @(*) begin
	next_state = STATE_READY;
	tx_enable = 1'b1;
	r_tx = 1'b1;
	r_tx_empty = 1'b0;
	case(state)
		STATE_READY : begin
			if(new_data_present) begin
				next_state = STATE_START_BIT;
			end
			else begin
				next_state = STATE_READY;
			end
			tx_enable = 1'b0;
			r_tx_empty = 1'b1;
		end
		STATE_START_BIT : begin
			if(baud_tick_count == START_BIT_TICKS) begin
				next_state = STATE_DATA_BITS;
			end
			else begin
				next_state = STATE_START_BIT;
			end
			r_tx = 1'b0;
		end
		STATE_DATA_BITS : begin
			if(baud_tick_count == (START_BIT_TICKS + DATA_BIT_TICKS)) begin
				if(PARITY_BIT) begin
					next_state = STATE_PARITY_BIT;
				end
				else begin
					next_state = STATE_STOP_BIT;
				end
			end
			else begin
				next_state = STATE_DATA_BITS;
			end
			r_tx = r_data_old[0];
		end
		STATE_PARITY_BIT : begin
			if(baud_tick_count == (START_BIT_TICKS 
									+ DATA_BIT_TICKS
									+ PARITY_BIT_TICKS)) begin
				next_state = STATE_STOP_BIT;
			end
			else begin
				next_state = STATE_PARITY_BIT;
			end
			if(PARITY_BIT == 1) begin
				r_tx = ~^r_data_old;
			end
			else begin
				r_tx = ^r_data_old;
			end
		end
		STATE_STOP_BIT :begin
			if(baud_tick_count == (START_BIT_TICKS 
								+ DATA_BIT_TICKS
								+ PARITY_BIT_TICKS
								+ STOP_BIT_TICKS)) begin
				next_state = STATE_READY;
			end
			else begin
				next_state = STATE_STOP_BIT;
			end
		end
		default: begin
			next_state = STATE_READY;
			tx_enable = 0;
		end
		
	endcase
end


// Data load detection
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		r_data_old <= 0;
		new_data_present <= 1'b0;
	end
	else begin
		if(r_data_old != data) begin
			new_data_present <= 1'b1;
		end
		else begin
			new_data_present <= 1'b0;
		end
		if((state == STATE_READY) && (next_state != STATE_START_BIT)) begin
			r_data_old <= data;
		end
		else if(state == STATE_STOP_BIT) begin
			r_data_old <= 0;
		end
		else if((state == STATE_DATA_BITS)
			&& (baud_tick_count != 	prev_baud_tick_count)				// baud_tick posedge
			&& (baud_tick_count[0] == 1'b0)) begin						// every odd baud ticks							// bit_n not exceed data lenght
				r_data_old <= {1'b0, r_data_old[DATA_LEN - 1 : 1]};		//shift data out
		end
		else begin
			r_data_old <= r_data_old;
		end
	end
end

// Baud tick pevious state keep for rising edge determinig
always @(posedge clk or negedge rst) begin
	if(!rst) begin 
		prev_baud_tick <= 1'b0;
	end
	else begin
		prev_baud_tick <= baud_tick;
	end
end

// Baud ticks count increment
always @(posedge clk or negedge tx_enable)
begin
	if(!tx_enable) begin
		baud_tick_count <= 0;
	end
	else if((baud_tick != prev_baud_tick) && baud_tick) begin	//posedge of baud_tick
		baud_tick_count <= baud_tick_count + 5'b1;
	end
	else begin
		baud_tick_count <= baud_tick_count;
	end
end

always @(posedge clk or negedge rst) begin
	if(!rst) begin
		prev_baud_tick_count <= 0;
	end
	else begin
		prev_baud_tick_count <= baud_tick_count;
	end
end

assign tx = r_tx;
assign tx_empty = r_tx_empty;

endmodule
