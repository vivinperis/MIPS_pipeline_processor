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
	pipelined_mips_32 mips(clk1, clk2);
	initial begin
		$dumpfile("mips.vcd");
		$dumpvars(0,test_mips32);
		#600 $finish;
	end
	initial begin
		clk1 = 0; clk2 = 0;
		repeat(20) begin
			#10 clk1 = 1; #10 clk1 = 0;
			#10 clk2 = 1; #10 clk2 = 0;
		end			
	end
	integer i;
	initial begin
		for(i = 0; i <= 31; i=i+1) 
		begin
			mips.register[i] = 0;
		end
		mips.register[1] = 3;
		mips.register[3] = 5;
		mips.register[5] = 18;
		mips.register[7] = 3;
		mips.mem[0] = 32'h04220006; //R2=R1+6
		mips.mem[1] = 32'h04640007; //R4=R3+7
		mips.mem[2] = 32'h08A60002;	//R6=R5-2
		mips.mem[3] = 32'h0CE80005; //R8=R7<5?  
		mips.mem[4] = 32'h0CE90002; //R9=R7<2?
		mips.mem[6] = 32'h00000002; //Store 2 at offset 6
		mips.mem[5] = 32'h1C2A0003; //R10=mem(R1+3) //Load word 6 from memory. Location = R1+3 = 3 +3 = 6, Mem[6]=2 stored in R10
		mips.ishalt = 0;
		mips.pc = 0;
		mips.isbranch_taken = 0;
		#300
		for(i = 0; i < 32; i=i+1) 
		begin
		$display("R%1d - %2d", i, mips.register[i]);
		end
	end
endmodule