`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.05.2020 14:51:32
// Design Name: 
// Module Name: pipe_mips_32
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


module pipe_mips_32(clk1, clk2);
	parameter add=6'b000000, addi=6'b001010, sub=6'b000001, subi=6'b001011, lw=6'b001000, sw=6'b001001, slti=6'b001100, and=6'b000010, or=6'b000011, slt=6'b000100, mul=6'b000101, HLT=6'b111111, bneqz=6'b001101, beqz=6'b001110;
	parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100, HALT=3'b101;					
	reg [31:0] PC, IF_ID_NPC, IF_ID_IR, ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
	reg [2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;
	reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B, MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
	reg 	   EX_MEM_cond;
	reg [31:0] Reg [0:31];		
	reg [31:0] Mem [0:1023];	
	input clk1, clk2;				
	reg halt, branch_taken;							
	always @ (posedge clk1)
		if(halt == 0)
		begin
			if(((EX_MEM_IR[31:26] == beqz) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == bneqz) && (EX_MEM_cond == 0)))
			begin
				IF_ID_IR 	<= #2 Mem[EX_MEM_ALUOut];
				branch_taken	<= #2 1'b1;
				IF_ID_NPC	<= #2 EX_MEM_ALUOut + 1;
				PC		<= #2 EX_MEM_ALUOut + 1;
			end
			else begin
				IF_ID_IR	<= #2 Mem[PC];
				IF_ID_NPC	<= #2 PC + 1;
				PC		<= #2 PC + 1;
			end
		end
	//ID Stage
	always @ (posedge clk2)
		if(halt == 0)
		begin
			if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
			else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];
			if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;
			else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];
			ID_EX_NPC 		<= #2 IF_ID_NPC;
			ID_EX_IR		<= #2 IF_ID_IR;
			ID_EX_Imm		<= #2 {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
			
			case(IF_ID_IR[31:26])
				add,sub,and,or,slt,mul:	ID_EX_type <= #2 RR_ALU;
				addi,subi,slti	      :	ID_EX_type <= #2 RM_ALU;
				lw		      : ID_EX_type <= #2 LOAD;
				sw		      :	ID_EX_type <= #2 STORE;
				bneqz, beqz	      : ID_EX_type <= #2 BRANCH;
				HLT		      : ID_EX_type <= #2 HALT;
				default		      : ID_EX_type <= #2 HALT; 		//Invalid Opcode
 			endcase
		end
	//EX Stage
	always @ (posedge clk1)
		if(halt == 0)
		begin 
			EX_MEM_type 	<= #2 ID_EX_type;
			EX_MEM_IR	<= #2 ID_EX_IR;
			branch_taken	<= #2 0;

		case(ID_EX_type)	
			RR_ALU:		begin
					case(ID_EX_IR[31:26]) //OPCODE
						add: 	EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
						sub: 	EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
						mul: 	EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
						and: 	EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
						or: 	EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
						slt: 	EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
						default:EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
					endcase
					end
			RM_ALU:		begin
					case(ID_EX_IR[31:26]) //OPCODE
						addi: 	EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
						subi: 	EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
						slti: 	EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
						default:EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
					endcase
					end
			LOAD,STORE:	begin
						EX_MEM_ALUOut	<= #2 ID_EX_A + ID_EX_Imm;
						EX_MEM_B	<= #2 ID_EX_B;
					end
			BRANCH:		begin
						EX_MEM_ALUOut 	<= #2 ID_EX_NPC + ID_EX_Imm;
						EX_MEM_cond 	<= #2 (ID_EX_A == 0);
					end		
		endcase
		end
	always @ (posedge clk2)
		if(halt == 0)
		begin
			MEM_WB_type	<= #2 EX_MEM_type;
			MEM_WB_IR	<= #2 EX_MEM_IR;
		case(EX_MEM_type)
			RR_ALU, RM_ALU:	MEM_WB_ALUOut 	<= #2 EX_MEM_ALUOut;
			LOAD:		MEM_WB_LMD	<= #2 Mem[EX_MEM_ALUOut];
			STORE:		if(branch_taken == 0) Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
		endcase
		end
	always @ (posedge clk1)
		begin
		if(branch_taken == 0)				
		case(MEM_WB_type)
			RR_ALU:		Reg[MEM_WB_IR[15:11]]	<= #2 MEM_WB_ALUOut; 	
			RM_ALU:		Reg[MEM_WB_IR[20:16]]	<= #2 MEM_WB_ALUOut; 
			LOAD:		Reg[MEM_WB_IR[20:16]]	<= #2 MEM_WB_LMD; 	
			HALT:		halt			<= #2 1'b1;
		endcase
		end	
endmodule