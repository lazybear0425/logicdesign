module try_games(
	input CLK,
	input [3:0] pos,
	input ensure,reset,
	output reg [7:0]red,blue,green,
	output reg [3:0]COMM_88,
	output reg [1:0]COMM_seg,
	output reg [6:0]seg,
	output reg [2:0]life_p1,life_p2,
	output reg [1:0]wingames_p1,wingames_p2,
	output reg [1:0]beep
	//output reg [0:1]show_who
);


	divfreq_one F1(CLK,CLK_one);
	divfreq_change F2(CLK,CLK_show);
	divfreq_play F3(CLK,CLK_play);
	divfreq_beep F4(CLK,CLK_beep);
	


	reg [7:0] show_p1[0:7];
	reg [7:0] show_p2[0:7];
	reg [7:0] show_now[0:7];
	reg [2:0] where [1:0]; //[1](x): 0~7 ,[0](y): 0~7
	bit who; //player 1 or 2
	bit [2:0] show_88;
	bit win_p1,win_p2;
	bit not_win;
	bit timeout;
	bit skip;
	bit tmp_win_p1,tmp_win_p2;
	bit who_change;
	reg timer_reset;
	bit tmp_timer_reset_ten,tmp_timer_reset_one;
	reg flag;
	bit tmp_flag;
	logic [4:0] col[7:0];
	logic [4:0] row[7:0];
	logic [4:0] l_slope[14:0];
	logic [4:0] r_slope[14:0];
	logic [4:0]continus=0;
	int i,j;
	logic [3:0] floor;
	logic [3:0]  ceiling;

	assign show_who={1'b0,reset}; //{who_change,who};
	initial
		begin
			show_p1='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
			show_p2='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
			show_now='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b111111111};
			where='{3'b000,3'b000};
			who=0;
			win_p1=0;
			win_p2=0;
			not_win=1;
			timeout=0;
			flag=1'b0; tmp_flag=2'b00;
			skip=0;
			life_p1=3'b111;
			life_p2=3'b111;
			tmp_win_p1=0;tmp_win_p2=0;
			wingames_p1=2'b00;
			wingames_p2=2'b00;
			show_88=3'b000;
			tmp_who_change=0;
			tmp_skip=0;
			timer_reset=0; tmp_timer_reset_one=0; tmp_timer_reset_ten=0;
			tmp_skip_life=0;
		end

	//if timeout, life-1

	bit tmp_skip_life;
	always @(posedge CLK_play)
		if(reset==1)
		begin
			life_p1=3'b111;
			life_p2=3'b111;
		end
		else if(tmp_skip_life!=skip)
		begin
				tmp_skip_life=skip;
				if(~who) //player 1
				begin
					case(life_p1)
						3'b111: life_p1=3'b110;
						3'b110: life_p1=3'b100;
						3'b100: life_p1=3'b000;
						//3'b000: tmp_win_p2=1;
					endcase
				end
				else
					begin
					case(life_p2)
						3'b111: life_p2=3'b110;
						3'b110: life_p2=3'b100;
						3'b100: life_p2=3'b000;
						//3'b000: tmp_win_p1=1;
					endcase
					end
					
			end
	
	//place chess
	reg [2:0]last_x,last_y;
	always @(posedge CLK_play)
	begin
		if(pos[0]==1)
			begin
				if(where[0]>=7)
					where[0]=0;
				else
					where[0]=where[0]+1;
			end
		else if(pos[1]==1)
			begin
				if(where[0]==0)
					where[0]=7;
				else
					where[0]=where[0]-1;
			end
		else if(pos[2]==1)
			begin
				if(where[1]<=0)
					where[1]=7;
				else
					where[1]=where[1]-1;
			end
		else if(pos[3]==1)
			begin
				if(where[1]>=7)
					where[1]=0;
				else
					where[1]=where[1]+1;
			end
		
		show_now[last_x][last_y]<=1; //not show(blue)
		show_now[where[1]][where[0]]<=0; //show now position
		last_x=where[1];
		last_y=where[0];
	end
	//play chess
	//reg che;
	//assign che=ensure/*|reset*/;
	always @(posedge CLK_play)
	begin
		if(reset==1)
		begin
				show_p1='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
				show_p2='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
		end
		else if(ensure) begin
			if(who==0) //who
			begin
				if(show_p1[last_x][last_y]&&show_p2[last_x][last_y])
				begin
					show_p1[last_x][last_y]<=0;
				end
				who_change=~who_change; //change
			end
			else
			begin
				if(show_p2[last_x][last_y]&&show_p1[last_x][last_y])
				begin
					show_p2[last_x][last_y]<=0;
				end
				who_change=~who_change; //change
			end
		end
	end
	//exchange other player
	bit tmp_who_change,tmp_skip;
	always @(posedge CLK_play)
	begin
		if(reset==1)
		begin
			who=0;
			tmp_who_change=who_change;
			tmp_skip=skip;
			timer_reset=~timer_reset; //reset timer
		end
		else if(tmp_who_change!=who_change||tmp_skip!=skip)
		begin
			who=~who;
			tmp_who_change=who_change;
			tmp_skip=skip;
			timer_reset=~timer_reset; //reset timer
		end
	end

	// win condition
	logic x,y;
	always @(posedge CLK_play)
		if(reset==1)
		begin
			if(win_p1)
			begin
				case(wingames_p1)
					2'b00:wingames_p1=2'b01;
					2'b01:wingames_p1=2'b11;
				endcase
			end
			else if(win_p2)
			begin
				case(wingames_p2)
					2'b00:wingames_p2=2'b01;
					2'b01:wingames_p2=2'b11;
				endcase
			end
			win_p1=0;
			win_p2=0;
			not_win=1;
		end
		else
		begin
			if(who)//player1
				begin
					l_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					r_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					row='{0,0,0,0,0,0,0,0};
					col='{0,0,0,0,0,0,0,0};
					for(i=0;i<8;i=i+1)
					begin
						for(j=0;j<8;j=j+1)
						begin
							if(show_p1[i][j]==0) begin col[i]=col[i]+1; end
							if(show_p1[j][i]==0) begin row[i]=row[i]+1; end 
							if(show_p1[i][j]==0)
							begin
								r_slope[(7-j)+i]=r_slope[(7-j)+i]+1;
								l_slope[i+j]=l_slope[i+j]+1;
							end
						end
					end
					for(i=0;i<8;i=i+1)
					begin
						if(col[i]>=5)
						begin
							continus=0;
							for(j=0;j<8;j=j+1)
							begin
								if(continus>=5) begin win_p1=1; not_win=0; end //player 2 win
								else if(!show_p1[i][j])
								begin
									continus=continus+1; 
								end
								else
								begin
									continus=0; 
								end
							end
							if(continus>=5) begin win_p1=1; not_win=0; end
						end
					end
					for(i=0;i<8;i=i+1)
					begin
						if(row[i]>=5)
						begin
							continus=0;
							for(j=0;j<8&&not_win;j=j+1)
							begin
								if(continus>=5) begin win_p1=1; not_win=0; end //player 2 win
								else if(show_p1[j][i]==0)
								begin
									continus=continus+1; 
								end
								else
								begin
									continus=0; 
								end
							end
							if(continus>=5) begin win_p1=1; not_win=0; end
						end
					end
					//left slope
					for(int i=0;i<=14&&not_win;i=i+1)
					begin
						if(l_slope[i]>=5)
						begin
							continus=0;
							if(i>=7) begin floor=i-7; ceiling=8; end
							else begin floor=0; ceiling=7-i+1; end
							for(int j=floor;j<ceiling;j=j+1)
							begin
								if(i>=j)
								begin
									if(continus>=5) begin win_p1=1; not_win=0; end
									else if(!show_p1[j][i-j])
									begin
										continus=continus+1;
									end
									else
									begin
										continus=0;
									end
								end
							end
						end
						if(continus>=5) begin win_p2=1; not_win=0; end
					end
					for(int i=0;i<=14&&not_win;i=i+1)
					begin
						if(r_slope[i]>=5)
						begin
							continus=0;
							if(i>=7) begin floor=i-7; ceiling=8; end
							else begin floor=0; ceiling=i+1; end
							for(int j=floor;j<ceiling;j=j+1)
							begin
								if(j+7>=i)
								begin
									if(continus>=5) begin win_p1=1; not_win=0; end
									else if(!show_p1[j][j+7-i])
									begin
										continus=continus+1;
									end
									else
									begin
										continus=0;
									end
								end
							end
						end
						if(continus>=5) begin win_p1=1; not_win=0; end
					end
				end //end who_if
			else
				begin
					l_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					r_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					row='{0,0,0,0,0,0,0,0};
					col='{0,0,0,0,0,0,0,0};
					for(i=0;i<8;i=i+1)
					begin
						for(j=0;j<8;j=j+1)
						begin
							if(show_p2[i][j]==0) begin col[i]=col[i]+1; end
							if(show_p2[j][i]==0) begin row[i]=row[i]+1; end 
							if(show_p2[i][j]==0)
							begin
								r_slope[(7-j)+i]=r_slope[(7-j)+i]+1;
								l_slope[i+j]=l_slope[i+j]+1;
							end
						end
					end
					for(i=0;i<8;i=i+1)
					begin
						if(col[i]>=5)
						begin
							continus=0;
							for(j=0;j<8;j=j+1)
							begin
								if(continus>=5) begin win_p2=1; not_win=0; end //player 2 win
								else if(!show_p2[i][j])
								begin
									continus=continus+1; 
								end
								else
								begin
									continus=0; 
								end
							end
							if(continus>=5) begin win_p2=1; not_win=0; end
						end
					end
					for(i=0;i<8;i=i+1)
					begin
						if(row[i]>=5)
						begin
							continus=0;
							for(j=0;j<8&&not_win;j=j+1)
							begin
								if(continus>=5) begin win_p2=1; not_win=0; end //player 2 win
								else if(show_p2[j][i]==0)
								begin
									continus=continus+1; 
								end
								else
								begin
									continus=0; 
								end
							end
							if(continus>=5) begin win_p2=1; not_win=0; end
						end
					end
					//left slope
					for(int i=0;i<=14&&not_win;i=i+1)
					begin
						if(l_slope[i]>=5)
						begin
							continus=0;
							if(i>=7) begin floor=i-7; ceiling=8; end
							else begin floor=0; ceiling=7-i+1; end
							for(int j=floor;j<ceiling;j=j+1)
							begin
								if(i>=j)
								begin
									if(continus>=5) begin win_p2=1; not_win=0; end
									else if(!show_p2[j][i-j])
									begin
										continus=continus+1;
									end
									else
									begin
										continus=0;
									end
								end
							end
						end
						if(continus>=5) begin win_p2=1; not_win=0; end
					end
					for(int i=0;i<=14&&not_win;i=i+1)
					begin
						if(r_slope[i]>=5)
						begin
							continus=0;
							if(i>=7) begin floor=i-7; ceiling=8; end
							else begin floor=0; ceiling=i+1; end
							//con={6'b111111,show_p2[0][3],show_p2[1][4],show_p2[2][5],show_p2[3][6],show_p2[4][7]};
							for(int j=floor;j<ceiling;j=j+1)
							begin
								if(j+7>=i)
								begin
							//		if(j==0) con=3;
									if(continus>=5) begin win_p2=1; not_win=0; end
									else if(!show_p2[j][j+7-i])
									begin
										continus=continus+1;
									end
									else
									begin
										continus=0;
									end
								end
							end
						end
						if(continus>=5) begin win_p2=1; not_win=0; end
					end
				end //end who_else
		end
	//=============================================================================================================
	//	show player win
	parameter logic[7:0] win [7:0]='{
	8'b10000001,
	8'b01111110,
	8'b01101010,
	8'b01011110,
	8'b01011110,
	8'b01101010,
	8'b01111110,
	8'b10000001
	};

	//show 
	always @(posedge CLK_show)
		begin
			if(show_88>=7)
				show_88=0;
			else
				show_88=show_88+1;
			COMM_88={1'b1,show_88};
			if(not_win)
				begin
					red=show_p1[show_88];
					blue=show_now[show_88];
					green=show_p2[show_88];
				end
			else
				begin
					if(win_p1) //player1 win
						begin
							red=win[show_88];
							blue=8'b11111111;
							green=8'b11111111;
						end
					else if(win_p2) //player2 win
						begin
							red=8'b11111111;
							blue=8'b11111111;
							green=win[show_88];
						end
				end
		end
//timer========================================
	bit[3:0] ten,one;
	initial
		begin
			ten=4'b1001;
			one=4'b1000;
			COMM_seg=2'b01;
		end
	//beep
	always @(posedge CLK_beep)
	begin
		if(tmp_flag!=flag||beep!=0)
			begin
				beep=beep+1;
				tmp_flag=flag;
			end
	end
	//change ten digit
	always@(posedge CLK_one)
		begin
			if(ten!=4'b1001&&tmp_timer_reset_ten!=timer_reset)
			begin
				tmp_timer_reset_ten<=timer_reset;
				if(life_p1==0&&who==0) begin ten=4'b0101; end
				else if(life_p2==0&&who==1) begin ten=4'b0101; end
				else begin ten=4'b1001; end
				
			end
			else if(one==4'b1001)
			begin
				if(ten<1)
					begin
						flag=~flag;
						skip=~skip;
						if(life_p1==0&&who==0) begin ten=4'b0101; end
						else if(life_p2==0&&who==1) begin ten=4'b0101; end
						else begin ten=4'b1001; end
					end
				else
				begin
					ten=ten-1'b1;
				end
			end
		end
	//change one digit
	always@(posedge CLK_one)
		begin
			if(tmp_timer_reset_one!=timer_reset)
			begin
				one=4'b1001;
				tmp_timer_reset_one=timer_reset;
			end
			else
			begin
				if(one==4'b0000)
					one=4'b1001;
				else
					one=one-1'b1;
			end
		end
	//change 7-seg show
	always @(posedge CLK_show)
		//begin
			if(COMM_seg==2'b01)
				begin
					COMM_seg=2'b10;
					case(ten)
						4'b0000:seg=7'b0000001;
						4'b0001:seg=7'b1001111;
						4'b0010:seg=7'b0010010;
						4'b0011:seg=7'b0000110;
						4'b0100:seg=7'b1001100;
						4'b0101:seg=7'b0100100;
						4'b0110:seg=7'b0100000;
						4'b0111:seg=7'b0001111;
						4'b1000:seg=7'b00000000;
						4'b1001:seg=7'b0001100;
					endcase
				end
			else
				begin
					COMM_seg=2'b01;
					case(one)
						4'b0000:seg=7'b0000001;
						4'b0001:seg=7'b1001111;
						4'b0010:seg=7'b0010010;
						4'b0011:seg=7'b0000110;
						4'b0100:seg=7'b1001100;
						4'b0101:seg=7'b0100100;
						4'b0110:seg=7'b0100000;
						4'b0111:seg=7'b0001111;
						4'b1000:seg=7'b00000000;
						4'b1001:seg=7'b0001100;
					endcase
				end
//new games
endmodule

//===========================================================================
module divfreq_change(input CLK,output reg CLK_div);
	reg [24:0] Count=25'b0;
	always @(posedge CLK)
		begin
			if(Count>25000)
				begin
					Count <=25'b0;
					CLK_div<=~CLK_div;
				end
			else
				Count<=Count+1'b1;
		end
endmodule

module divfreq_one(input CLK,output reg CLK_div);
	reg [24:0] Count=25'b0;
	always @(posedge CLK)
		begin
			if(Count>25000000/*25000000*/) 
				begin
					Count <=25'b0;
					CLK_div<=~CLK_div;
				end
			else
				Count<=Count+1'b1;
		end
endmodule

module divfreq_play(input CLK,output reg CLK_div);
	reg [24:0] Count=25'b0;
	always @(posedge CLK)
		begin
			if(Count>25000000)
				begin
					Count <=25'b0;
					CLK_div<=~CLK_div;
				end
			else
				Count<=Count+1'b1;
		end
endmodule

module divfreq_beep(input CLK,output reg CLK_div);
	reg [24:0] Count=25'b0;
	always @(posedge CLK)
		begin
			if(Count>2500000) 
				begin
					Count <=25'b0;
					CLK_div<=~CLK_div;
				end
			else
				Count<=Count+1'b1;
		end
endmodule