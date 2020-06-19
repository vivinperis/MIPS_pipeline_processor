`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.05.2020 14:52:49
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_mips32;
	reg clk1, clk2;
	integer k;
	pipelined_mips_32 mips(clk1, clk2);
	initial begin
		clk1 = 0; clk2 = 0;
		repeat(20) begin
			#10 clk1 = 1; #10 clk1 = 0;
			#10 clk2 = 1; #10 clk2 = 0;
		end			
	end
	initial begin
		for(k = 0; k <= 31; k=k+1) mips.register[31-k] = k;
		mips.mem[0] = 32'h00221801;
		mips.mem[1] = 32'h28020014;
		mips.mem[2] = 32'h28030019;
		mips.mem[3] = 32'h0ce77800;
		mips.mem[4] = 32'h0ce77800;
		mips.mem[5] = 32'h00222000;
		mips.mem[6] = 32'h0ce77800;
		mips.mem[7] = 32'h00832800;
		mips.mem[8] = 32'hfc000000;
		mips.halt = 0;
		mips.pc = 0;
		mips.branch_taken = 0;
		#280
		for(k = 0; k < 6; k=k+1) $display("A%1d - %2d", k, mips.register[k]);
	end
	initial begin
		$dumpfile("mips.vcd");
		$dumpvars(0,test_mips32);
		#300 $finish;
	end
endmodule