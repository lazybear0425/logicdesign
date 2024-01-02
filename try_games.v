module try_games(
	input CLK,
	input [3:0] pos, //button，控制上下左右
	input ensure,reset,
	output reg [7:0]red,blue,green, //8*8圖形輸出
	output reg [3:0]COMM_88,
	output reg [1:0]COMM_seg,
	output reg [6:0]seg,
	output reg [2:0]life_p1,life_p2,
	output reg [1:0]wingames_p1,wingames_p2,
	output reg [1:0]beep, //蜂鳴器
	//output reg [0:1]show_who //測試用變數
	//input            CLOCK_50,                //    50 MHz
	inout    [7:0]    LCD_DATA,                //    LCD Data bus 8 bits
 //output            LCD_ON;                    //    LCD Power ON/OFF
 //output            LCD_BLON;                //    LCD Back Light ON/OFF
	output            LCD_RW,                    //    LCD Read/Write Select, 0 = Write, 1 = Read6 
	output            LCD_EN,                    //    LCD Enable
	output            LCD_RS                    //    LCD Command/Data Select, 0 = Command, 1 = Data
);


	divfreq_one F1(CLK,CLK_one); //7seg 個位數
	divfreq_change F2(CLK,CLK_show); //顯示圖案
	divfreq_play F3(CLK,CLK_play); //玩的時鐘
	divfreq_beep F4(CLK,CLK_beep); //蜂鳴器
	

	 //player下棋位置
	//reg [0:7] show_p1[0:7]; //從左上 變 左下
	reg [7:0] show_p1[0:7]; //左上
	reg [7:0] show_p2[0:7];
	//游標在哪
	reg [7:0] show_now[0:7]; //圖(blue)
	reg [2:0] where [1:0]; //[1](x): 0~7 ,[0](y): 0~7
	bit who; //目前是player 1 or 2
	bit [2:0] show_88; //切換顯示8*8
	bit win_p1,win_p2; //誰贏了
	bit not_win; //目前沒人贏
	bit timeout; //沒用
	bit skip; //timer timeout用
	bit tmp_win_p1,tmp_win_p2; //配合always和win_p1,win_p2用
	bit who_change;//配合always和who用
	reg timer_reset; //reset timer
	bit tmp_timer_reset_ten,tmp_timer_reset_one;
	reg flag; //讓蜂鳴器叫
	bit tmp_flag; //配合always和flag用
   //判斷輸贏用變數------------------
	logic [4:0] col[7:0];
	logic [4:0] row[7:0];
	logic [4:0] l_slope[14:0];
	logic [4:0] r_slope[14:0];
	logic [4:0]continus=0;
	int i,j;
	logic [3:0] floor;
	logic [3:0]  ceiling;

	//assign show_who={1'b0,reset}; //{who_change,who};
	//初始化
	initial
		begin
			show_p1='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
			show_p2='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
			show_now='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b111111111};
			where='{3'b000,3'b000};
			//where='{3'b111,3'b111}; //游標最初開始的位置
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

	//若timer time-out，剩餘可犯規次數扣一
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
	
	//移動游標用
	reg [2:0]last_x,last_y;
	always @(posedge CLK_play)
	begin
		if(reset==1)
		begin
			show_now='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
			where='{3'b000,3'b000};
			show_now[last_x][last_y]<=1; //not show(blue)
			show_now[0][0]<=0; //show now position
			last_x=0;
			last_y=0;
		end
		else 
		begin
			if(pos[0]==1) //上 //flag
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
			
			show_now[last_x][last_y]<=1; //將之前的不顯示
			show_now[where[1]][where[0]]<=0; //顯示現在位置
			last_x=where[1];
			last_y=where[0];
		end
	end
	//play chess
	//若確定要下棋(按ensure)
	always @(posedge CLK_play)
	begin
		if(reset==1)
		begin
				show_p1<='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
				show_p2<='{8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
		end
		else if(ensure) begin
			if(who==0) //player 1
			begin
				//若之前沒人佔領過此位置，才能下棋   
				if(show_p1[last_x][last_y]&&show_p2[last_x][last_y])
				begin
					show_p1[last_x][last_y]<=0;//下棋
					who_change=~who_change;//換人
					//flag=~flag;
				end
			end
			else
			begin
				if(show_p2[last_x][last_y]&&show_p1[last_x][last_y])
				begin
					show_p2[last_x][last_y]<=0;//下棋
					who_change=~who_change;//換人
					//flag=~flag;
				end
			end
		end
	end
	//換到下一位選手
	bit tmp_who_change,tmp_skip;
	always @(posedge CLK_play)
	begin
		if(reset==1)
		begin
         //條件
         //下棋 or 犯規(timeout)
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

	//判斷贏的條件
	logic x,y;
	always @(posedge CLK_play)
		if(reset==1)
		begin
			if(win_p1) //player 1贏數加一
			begin
				case(wingames_p1) 
					2'b00:wingames_p1=2'b01;
					2'b01:wingames_p1=2'b11;
				endcase
			end
			else if(win_p2) //player 2贏數加一
			begin
				case(wingames_p2)
					2'b00:wingames_p2=2'b01;
					2'b01:wingames_p2=2'b11;
				endcase
			end
			win_p2<=0;
			win_p1<=0;
			not_win<=1;
		end
		else
		begin
			if(~who)//判斷player1是否贏
				begin
					l_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					r_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					row='{0,0,0,0,0,0,0,0};
					col='{0,0,0,0,0,0,0,0};
					continus=0;
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
					continus=0;
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
					continus=0;
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
					continus=0;
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
						if(continus>=5) begin win_p1=1; not_win=0; end //flag
					end
					continus=0;
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
			else//判斷player 2是否贏
				begin
					l_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					r_slope='{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
					row='{0,0,0,0,0,0,0,0};
					col='{0,0,0,0,0,0,0,0};
					continus=0;
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
					continus=0;
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
					continus=0;
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
					continus=0;
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
					continus=0;
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
	//顯示贏
	parameter logic[7:0] win [7:0]='{ //player 1
	8'b10000001,
	8'b01111110,
	8'b01101010,
	8'b01011110,
	8'b01011110,
	8'b01101010,
	8'b01111110,
	8'b10000001
	};
	
	parameter logic[7:0] win2 [7:0]='{ //player 2
	8'b10000001,
	8'b01111100,
	8'b01101010,
	8'b01011100,
	8'b01011100,
	8'b01101010,
	8'b01111100,
	8'b10000001
	};

	//show 
	always @(posedge CLK_show)
		begin
			//計算顯示哪條
			if(show_88>=7)
				show_88=0;
			else
				show_88=show_88+1;
			//8*8 EN+S0~2
			COMM_88={1'b1,show_88};
			if(not_win)
				begin
					red=show_p1[show_88];
					blue=show_now[show_88];
					green=show_p2[show_88];
				end
			else //有人贏
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
							green=win2[show_88];
						end
				end
		end
//timer========================================
		//十位數，個位數
	bit[3:0] ten,one;
	initial
		begin
			ten=4'b1001;
			one=4'b1001;
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
	//change 十位數
	always@(posedge CLK_one)
		begin
			if(reset==1||not_win==0) //reset 或 有人贏
			begin
				ten=4'b1001; //顯示9
			end
			//timer更新(下一位下棋)
			else if(ten!=4'b1001&&tmp_timer_reset_ten!=timer_reset)
			begin
				tmp_timer_reset_ten<=timer_reset;
				//犯規次數歸零 -> 時間減少
				if(life_p1==0&&who==0) begin ten=4'b0101; end 
				else if(life_p2==0&&who==1) begin ten=4'b0101; end
				//正常歸零
				else begin ten=4'b1001; end
			end
			else if(one==4'b0000)
			begin
				if(ten<1)
					begin
						flag=~flag; //beep
						skip=~skip;
						//犯規次數歸零 -> 時間減少
						if(life_p1==0&&who==0) begin ten=4'b0101; end
						else if(life_p2==0&&who==1) begin ten=4'b0101; end
						//正常歸零
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
			if(reset==1||not_win==0) //reset 或 有人贏
			begin
				//犯規次數歸零 -> 時間減少
				//if(life_p1==0&&who==0) begin one=4'b1001; end
				//else if(life_p2==0&&who==1) begin one=4'b1001; end
				//正常歸零
				//else begin one=4'b1001; end
				one=4'b1001;
			end
			//timer更新(下一位下棋)
			else if(tmp_timer_reset_one!=timer_reset)
			begin
				//犯規次數歸零 -> 時間減少
				//if(life_p1==0&&who==0) begin one=4'b1001; end
				//else if(life_p2==0&&who==1) begin one=4'b1001; end
				//正常歸零
				//else begin one=4'b1001; end
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
	//改變 7-seg 顯示
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
						4'b1000:seg=7'b0000000;
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
						4'b1000:seg=7'b0000000;
						4'b1001:seg=7'b0001100;
					endcase
				end
//===================================LCD=======================================================
 wire        DLY_RST;
 
 Reset_Delay            r0    (    .iCLK(CLK),.oRESET(DLY_RST)    );
 
 LCD_TEST             u5    (    //    Host Side
                             .iCLK(CLK),
                             .iRST_N(DLY_RST),
                             //    LCD Side
                             .LCD_DATA(LCD_DATA),
                             .LCD_RW(LCD_RW),
                             .LCD_EN(LCD_EN),
                             .LCD_RS(LCD_RS)    );
//===================================end=======================================================
endmodule

//===========================================================================
//除頻模組
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

//LCD module
 module    LCD_TEST (    //    Host Side
                     iCLK,iRST_N,
                     //    LCD Side
                     LCD_DATA,LCD_RW,LCD_EN,LCD_RS    );
 //    Host Side
 input            iCLK,iRST_N;
 //    LCD Side
 output    [7:0]    LCD_DATA;
 output            LCD_RW,LCD_EN,LCD_RS;
 //    Internal Wires/Registers
 reg    [5:0]    LUT_INDEX;
 reg    [8:0]    LUT_DATA;
 reg    [5:0]    mLCD_ST;
 reg    [17:0]    mDLY;
 reg            mLCD_Start;
 reg    [7:0]    mLCD_DATA;
 reg            mLCD_RS;
 wire        mLCD_Done;
 
 parameter    LCD_INTIAL    =    0;
 parameter    LCD_LINE1    =    5;
 parameter    LCD_CH_LINE    =    LCD_LINE1+20;//根據Lcd的大小來改
 parameter    LCD_LINE2    =    LCD_LINE1+20+1;//根據Lcd的大小來改 //第二行
 parameter    LUT_SIZE    =    LCD_LINE1+40+1;//根據Lcd的大小來改
 
 always@(posedge iCLK or negedge iRST_N)
 begin
     if(!iRST_N)
     begin
         LUT_INDEX    <=    0;
         mLCD_ST        <=    0;
         mDLY        <=    0;
         mLCD_Start    <=    0;
         mLCD_DATA    <=    0;
         mLCD_RS        <=    0;
     end
     else
     begin
         if(LUT_INDEX<LUT_SIZE)
         begin
             case(mLCD_ST)
             0:    begin
                     mLCD_DATA    <=    LUT_DATA[7:0];
                     mLCD_RS        <=    LUT_DATA[8];
                     mLCD_Start    <=    1;
                     mLCD_ST        <=    1;
                 end
             1:    begin
                     if(mLCD_Done)
                     begin
                         mLCD_Start    <=    0;
                         mLCD_ST        <=    2;                    
                     end
                 end
             2:    begin
                     if(mDLY<18'h3FFFE)    // 5.2ms
                     mDLY    <=    mDLY+1;
                     else
                     begin
                         mDLY    <=    0;
                         mLCD_ST    <=    3;
                     end
                 end
             3:    begin
                     LUT_INDEX    <=    LUT_INDEX+1;
                     mLCD_ST    <=    0;
                 end
             endcase
         end
     end
 end
 
 always
 begin
     case(LUT_INDEX)
     //    Initial
     LCD_INTIAL+0:    LUT_DATA    <=    9'h038; //Fun set
     LCD_INTIAL+1:    LUT_DATA    <=    9'h00C; //dis on
     LCD_INTIAL+2:    LUT_DATA    <=    9'h001; //clr dis
     LCD_INTIAL+3:    LUT_DATA    <=    9'h006; //Ent mode
     LCD_INTIAL+4:    LUT_DATA    <=    9'h080; //set ddram address
     //    Line 1
     LCD_LINE1+0:    LUT_DATA    <=    9'h146; // F
     LCD_LINE1+1:    LUT_DATA    <=    9'h169; // i
     LCD_LINE1+2:    LUT_DATA    <=    9'h176; // v
     LCD_LINE1+3:    LUT_DATA    <=    9'h165; // e
     LCD_LINE1+4:    LUT_DATA    <=    9'h1B0; // -
     LCD_LINE1+5:    LUT_DATA    <=    9'h149; // I
     LCD_LINE1+6:    LUT_DATA    <=    9'h16E; // n
     LCD_LINE1+7:    LUT_DATA    <=    9'h1B0; // -
     LCD_LINE1+8:    LUT_DATA    <=    9'h141; // A
     LCD_LINE1+9:    LUT_DATA    <=    9'h1B0; // -
     LCD_LINE1+10:    LUT_DATA    <=    9'h152; // R
     LCD_LINE1+11:    LUT_DATA    <=    9'h16F; // o
     LCD_LINE1+12:    LUT_DATA    <=    9'h177; // w
	  LCD_LINE1+13:    LUT_DATA    <=    9'h120;//
     LCD_LINE1+14:    LUT_DATA    <=    9'h128; // (
     LCD_LINE1+15:    LUT_DATA    <=    9'h1BD; // tsu
	  LCD_LINE1+16:    LUT_DATA    <=    9'h1B6;//ka
	  LCD_LINE1+17:    LUT_DATA    <=    9'h1DA;//re
	  LCD_LINE1+18:    LUT_DATA    <=    9'h1C0;//ta
	  LCD_LINE1+19:    LUT_DATA    <=    9'h129;//)
     //    Change Line
     LCD_CH_LINE:    LUT_DATA    <=    9'h0C0;
     //    Line 2
     LCD_LINE2+0:    LUT_DATA    <=    9'h1EF; // o
     LCD_LINE2+1:    LUT_DATA    <=    9'h150; // P
     LCD_LINE2+2:    LUT_DATA    <=    9'h131; // 1
     LCD_LINE2+3:    LUT_DATA    <=    9'h13D; // =
     LCD_LINE2+4:    LUT_DATA    <=    9'h152; // R
     LCD_LINE2+5:    LUT_DATA    <=    9'h120; // 
     LCD_LINE2+6:    LUT_DATA    <=    9'h150; // P
     LCD_LINE2+7:    LUT_DATA    <=    9'h132; // 2
     LCD_LINE2+8:    LUT_DATA    <=    9'h13D; // =
     LCD_LINE2+9:    LUT_DATA    <=    9'h147; // G
     LCD_LINE2+10:    LUT_DATA    <=    9'h120;// 
     LCD_LINE2+11:    LUT_DATA    <=    9'h143;// C
     LCD_LINE2+12:    LUT_DATA    <=    9'h175;// u
     LCD_LINE2+13:    LUT_DATA    <=    9'h172;// r
     LCD_LINE2+14:    LUT_DATA    <=    9'h173;// s
     LCD_LINE2+15:    LUT_DATA    <=    9'h16F;// o
	  LCD_LINE2+16:    LUT_DATA    <=    9'h172;// r
	  LCD_LINE2+17:    LUT_DATA    <=    9'h13D;// =
	  LCD_LINE2+18:    LUT_DATA    <=    9'h142;// B
	  LCD_LINE2+19:    LUT_DATA    <=    9'h1EF;// o
     default:        LUT_DATA    <=    9'h000;
     endcase
 end
 
 LCD_Controller         u0    (    //    Host Side
                             .iDATA(mLCD_DATA),
                            .iRS(mLCD_RS),
                             .iStart(mLCD_Start),
                             .oDone(mLCD_Done),
                             .iCLK(iCLK),
                             .iRST_N(iRST_N),
                             //    LCD Interface
                             .LCD_DATA(LCD_DATA),
                             .LCD_RW(LCD_RW),
                             .LCD_EN(LCD_EN),
                             .LCD_RS(LCD_RS)    );
 
 endmodule
 
 
 module LCD_Controller (    //    Host Side
                         iDATA,iRS,
                         iStart,oDone,
                         iCLK,iRST_N,
                         //    LCD Interface
                         LCD_DATA,
                         LCD_RW,
                         LCD_EN,
                         LCD_RS    );
 //    CLK
 parameter    CLK_Divide    =    16;
 
 //    Host Side
 input    [7:0]    iDATA;
 input    iRS,iStart;
 input    iCLK,iRST_N;
 output    reg        oDone;
 //    LCD Interface
 output    [7:0]    LCD_DATA;
 output    reg        LCD_EN;
 output            LCD_RW;
 output            LCD_RS;
 //    Internal Register
 reg        [4:0]    Cont;
 reg        [1:0]    ST;
 reg        preStart,mStart;
 
 /////////////////////////////////////////////
 //    Only write to LCD, bypass iRS to LCD_RS
 assign    LCD_DATA    =    iDATA; 
 assign    LCD_RW        =    1'b0;
 assign    LCD_RS        =    iRS;
 /////////////////////////////////////////////
 
 always@(posedge iCLK or negedge iRST_N)
 begin
     if(!iRST_N)
     begin
         oDone    <=    1'b0;
         LCD_EN    <=    1'b0;
         preStart<=    1'b0;
         mStart    <=    1'b0;
         Cont    <=    0;
         ST        <=    0;
     end
     else
     begin
         //////    Input Start Detect ///////
         preStart<=    iStart;
         if({preStart,iStart}==2'b01)  // latch ?
         begin
             mStart    <=    1'b1;
             oDone    <=    1'b0;
         end
         //////////////////////////////////
         if(mStart)  //generate LCD_EN
         begin
             case(ST)
             0:    ST    <=    1;    //    Wait Setup, tAS >= 40ns
             1:    begin
                     LCD_EN    <=    1'b1;
                     ST        <=    2;
                 end
             2:    begin                    
                     if(Cont<CLK_Divide)
                     Cont    <=    Cont+1;
                     else
                     ST        <=    3;
                 end
             3:    begin
                     LCD_EN    <=    1'b0;
                     mStart    <=    1'b0;
                     oDone    <=    1'b1;
                     Cont    <=    0;
                     ST        <=    0;
                 end
             endcase
         end
     end
 end
 
 endmodule
 
 

 module    Reset_Delay(iCLK,oRESET);
 input        iCLK;
 output reg    oRESET;
 reg    [19:0]    Cont;
 
 always@(posedge iCLK)
 begin
     if(Cont!=20'hFFFFF)   //21ms
     begin
         Cont    <=    Cont+1;
         oRESET    <=    1'b0;
     end
     else
     oRESET    <=    1'b1;
 end
 
 endmodule
 