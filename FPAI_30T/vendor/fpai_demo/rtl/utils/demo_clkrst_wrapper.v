//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : demo_clkrst_wrapper.v
// Author        : Li Xiayu
// Project       : NB1917
// Create Date   : 2020.01.07
// Description   :
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
//==============================================================================


module demo_clkrst_wrapper(
    output                 ddr_clk_led       ,
    output                 ps_clk_led        ,

    input                  sys_rst           ,
    input                  soft_rst          ,

    input                  ddr_clk           ,
    input                  ps_clk_out        ,

    output                 gp_clk            ,
    output                 hp_clk            ,

    output                 gp_clk_rst        ,
    output                 hp_clk_rst        ,
    output                 ddr_clk_rst      
);

    reg   [ 26 : 0]   led_cnt           ;
    reg   [ 26 : 0]   led_cnt0          ;
    
    reg               rst_d1_ddr_clk    ;
    reg               rst_d2_ddr_clk    ;        // for hp0

    reg               rst_d1_gp_clk     ;
    reg               rst_d2_gp_clk     ;

    always@(posedge ddr_clk)begin
        led_cnt <= led_cnt+1        ;
    end
    assign ddr_clk_led = led_cnt[26];
    
    always@(posedge ps_clk_out)begin
        led_cnt0 <= led_cnt0+1      ;
    end
    
    assign ps_clk_led = led_cnt0[26];
    assign gp_clk     = ps_clk_out  ;
    assign hp_clk     = ddr_clk     ;

    always@(posedge ddr_clk) begin
        rst_d1_ddr_clk <= sys_rst|soft_rst;
        rst_d2_ddr_clk <= rst_d1_ddr_clk  ;
    end

    always@(posedge gp_clk) begin
        rst_d1_gp_clk <= sys_rst|soft_rst ;
        rst_d2_gp_clk <= rst_d1_gp_clk    ; 
    end

    assign hp_clk_rst  = rst_d2_ddr_clk;
	assign ddr_clk_rst  = sys_rst|soft_rst;
    assign gp_clk_rst  = rst_d2_gp_clk ;
    
endmodule
