`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// company: 
// engineer: 
// 
// create date: 2.05.2020 14:51:32
// design name: 
// module name: pipe_mips_32
// project name: 
// target devices: 
// tool versions: 
// description: 
// 
// dependencies: 
// 
// revision:
// revision 0.01 - file created
// additional comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipelined_mips_32(input clk1, input clk2);
	parameter zero=6'b000000, add=6'b000001, addi=6'b000001, sub=6'b000010, hlt=6'b111111, subi=6'b000010, lw=6'b000111, sw=6'b000100, slti=6'b000011, andr=6'b000101, orr=6'b000110, slt=6'b000111, mul=6'b001000, bneqz=6'b001101, beqz=6'b001110, jump=6'b001000, rr_alu=3'b000, rm_alu=3'b001, load=3'b010, store=3'b011, branch=3'b100, halt=3'b101;					
	reg [31:0] pc, if_id_npc, if_id_reg, id_ex_reg, id_ex_npc, id_ex_a, id_ex_b, id_ex_imm, ex_mem_reg, ex_mem_alu, ex_mem_b, mem_wb_reg, mem_wb_aluout, mem_wb_lmd, register [0:31], mem [0:1023];
	reg [2:0]  id_ex_type, ex_mem_type, mem_wb_type; 
	reg condition, ishalt, isbranch_taken;
	reg z=0;							
	always @ (posedge clk1) //Instruction fetch happens here
		if(ishalt == 0)
		begin
			if(ex_mem_reg[31:26] == jump ||((ex_mem_reg[31:26] == beqz) && (condition == 1)) || ((ex_mem_reg[31:26] == bneqz) && (condition == 0)))
			begin
				if_id_reg 	<= #5 mem[ex_mem_alu];
				isbranch_taken	<= #5 1'b1;
				if_id_npc	<= #5 ex_mem_alu + 1;
				pc		<= #5 ex_mem_alu + 1;
			end
			else begin
				if_id_reg	<= #5 mem[pc];
				if_id_npc	<= #5 pc + 1;
				pc		<= #5 pc + 1;
			end
		end
	always @ (posedge clk2) //Instruction decode happens here
		if(ishalt == 0)
		begin
			case(if_id_reg[31:26])
				zero: id_ex_type <= #5 rr_alu; //Here we set the type of instruction
				addi,subi,slti	      :	id_ex_type <= #5 rm_alu;
				bneqz, beqz,jump	      : id_ex_type <= #5 branch;
				lw		      : id_ex_type <= #5 load;
				sw		      :	id_ex_type <= #5 store;
				default		      : id_ex_type <= #5 hlt; 		
 			endcase
			if (if_id_reg[25:21] == 5'b00000) id_ex_a <= 0; //Check the Rs value and assign to 0 if its R0
			else id_ex_a <= #5 register[if_id_reg[25:21]];
			if (if_id_reg[20:16] == 5'b00000) id_ex_b <= 0; //Check the Rt value and assign to 0 if its R0
			else id_ex_b <= #5 register[if_id_reg[20:16]];
			id_ex_npc 		<= #5 if_id_npc;  //Transfer the next program counter value
			id_ex_reg		<= #5 if_id_reg;  //Transfer the instruction register value
			id_ex_imm		<= #5 {{16{if_id_reg[15]}},{if_id_reg[15:0]}}; //Extended the operand
			if(if_id_reg[31:26] == jump) 
			id_ex_imm <= #5 {{if_id_reg[31:28]},{if_id_reg[25:0]},{4{z}}};
		end
	always @ (posedge clk1)
		if(ishalt == 0)
		begin 
			ex_mem_type 	<= #5 id_ex_type;
			ex_mem_reg	<= #5 id_ex_reg;
			isbranch_taken	<= #5 0;
		case(id_ex_type)	
			rr_alu:		begin
					case(id_ex_reg[5:0])  //Alu instructions where Function parameter defines the value
						add: 	ex_mem_alu <= #5 id_ex_a + id_ex_b;
						sub: 	ex_mem_alu <= #5 id_ex_a - id_ex_b;
						mul: 	ex_mem_alu <= #5 id_ex_a * id_ex_b;
						andr: 	ex_mem_alu <= #5 id_ex_a & id_ex_b;
						orr: 	ex_mem_alu <= #5 id_ex_a | id_ex_b;
						slt: 	ex_mem_alu <= #5 id_ex_a < id_ex_b;
						default:ex_mem_alu <= #5 32'hxxxxxxxx;
					endcase
					end
			rm_alu:		begin
					case(id_ex_reg[31:26]) 
						addi: 	ex_mem_alu <= #5 id_ex_a + id_ex_imm;
						subi: 	ex_mem_alu <= #5 id_ex_a - id_ex_imm;
						slti: 	ex_mem_alu <= #5 id_ex_a < id_ex_imm;
						default:ex_mem_alu <= #5 32'hxxxxxxxx;
					endcase
					end
			load,store:	begin
						ex_mem_alu	<= #5 id_ex_a + id_ex_imm;
						ex_mem_b	<= #5 id_ex_b;
					end
			branch:		begin
						ex_mem_alu 	<= #5 id_ex_npc + id_ex_imm;
						condition 	<= #5 (id_ex_a == 0);
						if(id_ex_reg[31:26]==jump)
						ex_mem_alu <= id_ex_imm;
					end		
		endcase
		end
	always @ (posedge clk2)
		if(ishalt == 0)
		begin
			mem_wb_type	<= #5 ex_mem_type;
			mem_wb_reg	<= #5 ex_mem_reg;
		case(ex_mem_type)
			rr_alu, rm_alu:	mem_wb_aluout 	<= #5 ex_mem_alu;
			load:	mem_wb_lmd	<= #5 mem[ex_mem_alu];
			store:	if(isbranch_taken == 0) mem[ex_mem_alu] <= #5 ex_mem_b;
		endcase
		end
	always @ (posedge clk1)
		begin
		if(isbranch_taken == 0)				
		case(mem_wb_type)
			rr_alu:		register[mem_wb_reg[15:11]]	<= #5 mem_wb_aluout; 	//write back if branch is not taken
			rm_alu:		register[mem_wb_reg[20:16]]	<= #5 mem_wb_aluout; 
			load:		register[mem_wb_reg[20:16]]	<= #5 mem_wb_lmd; 	
			halt:		ishalt <= #5 1'b1;
		endcase
		end	
endmodule