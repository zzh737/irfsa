`timescale 1ns/1ps
// GP writes an inactive height bank, then COMMIT. Pixel domain swaps only at
// (0,0); ack releases GP writes. Metadata uses the same stable mailbox.
module spectrum_display #(parameter integer STALE_CYCLES=148500000)(
 input wire gp_clk,gp_rst,input wire [17:0] wr_addr,input wire [31:0] wr_data,
 input wire wr_en,input wire [17:0] rd_addr,output reg [31:0] rd_data,
 input wire pix_clk,pix_rst,input wire [11:0] x,y,input wire de,hs,vs,
 output reg out_de,out_hs,out_vs,output reg [23:0] rgb,
 output wire update_busy,commit_accepted);
 reg req=0,ack=0,seen=0,write_bank=1;
 (* ASYNC_REG="TRUE" *) reg [1:0] ack_sync=0,req_sync=0;
 reg [31:0] cap,seq,class_id,confidence,flags,peak;
 wire busy=req!=ack_sync[1];
 assign update_busy=busy||ack_sync[1]!=seen;
 assign commit_accepted=wr_en&&!update_busy&&wr_addr==18'h100&&wr_data[0]&&!gp_rst;
 (* ram_style="block" *) reg [8:0] heights[0:2047];
 always @(posedge gp_clk)begin
   if(gp_rst)begin
     req<=0;ack_sync<=0;seen<=0;write_bank<=1;
     cap<=0;seq<=0;class_id<=255;confidence<=0;flags<=0;peak<=0;
   end else begin
     ack_sync<={ack_sync[0],ack};
     if(ack_sync[1]!=seen)begin seen<=ack_sync[1];write_bank<=~write_bank;end
     // Acknowledgement and bank toggle must settle before accepting writes.
     if(wr_en&&!busy&&ack_sync[1]==seen)begin
       if(wr_addr>=18'h1000&&wr_addr<=18'h1ffc&&wr_addr[1:0]==0)
         heights[{write_bank,wr_addr[11:2]}]<=wr_data>400 ? 9'd400 : wr_data[8:0];
       case(wr_addr)
         18'h100:if(wr_data[0])req<=~req;
         18'h108:cap<=wr_data;
         18'h10c:seq<=wr_data;
         18'h110:class_id<=wr_data;
         18'h114:confidence<=wr_data>1000 ? 1000 : wr_data;
         18'h118:flags<=wr_data;
         18'h11c:peak<=wr_data;
       endcase
     end
   end
 end
 always @*begin
   case(rd_addr)
     18'h100:rd_data=0;18'h120:rd_data=32'h44534831;
     18'h104:rd_data={31'b0,(busy||ack_sync[1]!=seen)};
     18'h108:rd_data=cap;18'h10c:rd_data=seq;18'h110:rd_data=class_id;
     18'h114:rd_data=confidence;18'h118:rd_data=flags;18'h11c:rd_data=peak;
     default:rd_data=32'hdeadbeef;
   endcase
 end
 reg active_bank=0,valid_frame=0;
 localparam integer AGE_WIDTH=(STALE_CYCLES<2)?1:$clog2(STALE_CYCLES+1);
 reg [AGE_WIDTH-1:0] frame_age=0;
 reg [31:0] active_cap,active_seq,active_class,active_conf,active_flags;
 always @(posedge pix_clk)begin
   if(pix_rst)begin
     req_sync<=0;ack<=0;active_bank<=0;valid_frame<=0;frame_age<=0;
     active_cap<=0;active_seq<=0;active_class<=255;active_conf<=0;active_flags<=0;
   end else begin
     req_sync<={req_sync[0],req};
     if(x==0&&y==0&&req_sync[1]!=ack)begin
       active_bank<=write_bank;valid_frame<=1;frame_age<=0;
       active_cap<=cap;active_seq<=seq;active_class<=class_id;
       active_conf<=confidence;active_flags<=flags;ack<=req_sync[1];
     end else if(active_class==255)valid_frame<=0;
     else if(valid_frame)begin
       if(frame_age>=STALE_CYCLES-1)begin
         valid_frame<=0;active_class<=255;active_conf<=0;active_flags<=2;
       end else frame_age<=frame_age+1'b1;
     end
   end
 end

 // Dashboard text plane: 80 visible columns, 32 rows, stride 128 cells.
 // GP addresses 0x2000..0x5ffc; each cell carries palette[11:8], glyph[7:0].
 (* ram_style="block" *) reg [11:0] text_cells[0:8191];
 (* rom_style="block" *) reg [15:0] font_rom[0:8191];
 `include "dashboard_font.vh"
 integer init_cell;
 initial for(init_cell=0;init_cell<8192;init_cell=init_cell+1)text_cells[init_cell]=12'h020;
 always @(posedge gp_clk)
   if(wr_en&&!gp_rst&&!update_busy&&wr_addr>=18'h2000&&wr_addr<18'h6000&&wr_addr[1:0]==0)
     text_cells[{write_bank,wr_addr[13:2]-12'h800}]<=wr_data[11:0];
 function [7:0] class_char;
 input [31:0] cid;input [2:0] pos;
 reg [63:0] name;
 begin
 case(cid)
 0:name="16ASK   ";1:name="16FSK   ";2:name="16QAM   ";
 3:name="2ASK    ";4:name="2FSK    ";5:name="2PSK    ";
 6:name="4ASK    ";7:name="4FSK    ";8:name="4PSK    ";
 9:name="64QAM   ";10:name="8ASK    ";11:name="8FSK    ";
 12:name="8PSK    ";13:name="AM-DSBSC";14:name="AM-DSBWC";
 15:name="AM-SSBSC";16:name="AM-SSBWC";17:name="FM      ";default:name="UNKNOWN ";
 endcase
 class_char=name>>((7-pos)*8);
 end endfunction
 // Waterfall stores 128 committed spectra, 256 bins, 4-bit display intensity.
 (* ram_style="block" *) reg [3:0] waterfall[0:32767];
 reg [6:0] history_head=0;
 reg [7:0] history_count=0;
 reg history_pending=0;
 reg [31:0] history_cap=0;
 reg copy_row=0,copy_fetch=0;
 reg [7:0] copy_column;
 reg [8:0] height;
 reg [3:0] water0,water1;
 reg [11:0] tile0;
 reg [15:0] glyph1;
 reg [3:0] palette1;
 reg [8:0] height1;
 reg [11:0] px0,py0,px,py;
 reg de0,hs0,vs0,render_de,render_hs,render_vs;
 reg [23:0] render_rgb;
 wire [9:0] plot_index=((x>=64&&x<832)?((x-64)*4)/3:0);
 wire copy_now=copy_row&&y==0&&x>=2&&x<=257;
 wire [9:0] height_index=copy_now?{(x[7:0]-8'd2),2'b10}:plot_index;
 wire [6:0] history_age=(y-12'd360)>>1;
 wire [6:0] history_address=history_head-history_age;
 wire [7:0] water_column=(x>=64&&x<832)?(x-64)/3:0;
 wire [11:0] tile_address=((y/24)*128)+(x>>4);
 always @(posedge pix_clk)begin
   if(pix_rst)begin history_head<=0;history_count<=0;copy_row<=0;copy_fetch<=0;history_pending<=0;history_cap<=0;end
   else begin
     // Consume only pixel-domain metadata after the mailbox capture.
     history_pending<=x==0&&y==0&&req_sync[1]!=ack;
     if(history_pending)begin
       history_head<=(history_count==0||active_cap!=history_cap)?0:history_head+1'b1;
       history_count<=active_class==255?0:(history_count==0||active_cap!=history_cap)?1:(history_count<128?history_count+1'b1:128);
       history_cap<=active_cap;
       copy_row<=active_class!=255;
     end
     else if(!valid_frame)history_count<=0;
     if(y==1)copy_row<=0;
     copy_fetch<=copy_now;copy_column<=x[7:0]-8'd2;
     if(copy_fetch)waterfall[{history_head,copy_column}]<=height[8:5];
   end
   height<=heights[{active_bank,height_index}];
   water0<=waterfall[{history_address,water_column}];
   tile0<=text_cells[{active_bank,tile_address}];
   px0<=x;py0<=y;de0<=de&&!pix_rst;hs0<=hs;vs0<=vs;
   if(px0>=864&&px0<1120&&py0>=120&&py0<168)begin
     glyph1<=font_rom[{class_char(valid_frame?active_class:255,(px0-864)>>5),5'b0}+((py0-120)>>1)];
     palette1<=1;
   end else begin glyph1<=font_rom[{tile0[7:0],5'b0}+(py0%24)];palette1<=tile0[11:8];end
   height1<=height;water1<=water0;
   px<=px0;py<=py0;render_de<=de0;render_hs<=hs0;render_vs<=vs0;
   rgb<=pix_rst?24'd0:render_rgb;
   out_de<=render_de&&!pix_rst;out_hs<=render_hs;out_vs<=render_vs;
 end
 reg ink;reg [3:0] bit_column;
 always @*begin
   bit_column=(px>=864&&px<1120&&py>=120&&py<168)?((px-864)>>1):px[3:0];
   ink=glyph1[15-bit_column];
   render_rgb=24'h080c18;
   if(!render_de)render_rgb=0;
   else begin
     if(py==72||py==648||px==848)render_rgb=24'h26364a;
     if(px>=64&&px<832&&py>=112&&py<=320)begin
       if((px-64)%128==0||(py-120)%40==0)render_rgb=24'h1d2a3b;
       if(valid_frame&&height1!=0)begin
         if(py>=320-(height1>>1))render_rgb=24'h103941;
         if(py>=319-(height1>>1)&&py<=321-(height1>>1))render_rgb=24'h35e4d0;
       end
     end
     if(px>=64&&px<832&&py>=360&&py<616)begin
       render_rgb=24'h0c142b;
       if(valid_frame&&((py-360)>>1)<history_count)begin
         case(water1)
         0:render_rgb=24'h0b1024;1:render_rgb=24'h101e40;2:render_rgb=24'h15386b;
         3:render_rgb=24'h175b99;4:render_rgb=24'h147eaf;5:render_rgb=24'h12a6bb;
         6:render_rgb=24'h24c9b9;7:render_rgb=24'h64dd9a;8:render_rgb=24'ha4e06a;
         9:render_rgb=24'hd9dc48;10:render_rgb=24'hf4bd43;11:render_rgb=24'hf48b40;
         default:render_rgb=24'hf65d43;
         endcase
       end
     end
     // Stale data must never leave valid-looking labels or telemetry behind.
     if(!valid_frame&&px>=864&&py>=192)ink=0;
     if(!valid_frame&&py>=648)ink=0;
     if(ink)case(palette1)
       1:render_rgb=24'h48e1d0;2:render_rgb=24'h8cacc4;3:render_rgb=24'h61d58b;
       4:render_rgb=24'hf2bb57;default:render_rgb=24'he0eaf4;
     endcase
   end
 end
endmodule

