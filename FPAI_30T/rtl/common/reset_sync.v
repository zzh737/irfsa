`timescale 1ns/1ps
module reset_sync #(parameter SYNCHRONOUS=0)(input wire clk, input wire arst, output wire rst);
  (* ASYNC_REG="TRUE" *) reg [2:0] pipe = 3'b111;
  generate if (SYNCHRONOUS == 2) begin : sampled_reset
    wire [2:0] sampled_pipe;
    // Three-stage level synchronizer: only stage 0 samples the foreign domain.
    // No asynchronous preset or foreign-domain synchronous reset control.
    // Assertion and release take three running destination-clock edges.
    // Keep the first-stage OR at D: synthesis otherwise moves gp_rst onto
    // an FDSE S control, defeating the intended single CDC data entry.
    (* DONT_TOUCH="TRUE", ASYNC_REG="TRUE" *)
    FDRE #(.INIT(1'b1)) entry_ff(.C(clk),.CE(1'b1),.R(1'b0),.D(arst),.Q(sampled_pipe[0]));
    (* DONT_TOUCH="TRUE", ASYNC_REG="TRUE" *)
    FDRE #(.INIT(1'b1)) middle_ff(.C(clk),.CE(1'b1),.R(1'b0),.D(sampled_pipe[0]),.Q(sampled_pipe[1]));
    (* DONT_TOUCH="TRUE", ASYNC_REG="TRUE" *)
    FDRE #(.INIT(1'b1)) output_ff(.C(clk),.CE(1'b1),.R(1'b0),.D(sampled_pipe[1]),.Q(sampled_pipe[2]));
    assign rst = sampled_pipe[2];
  end else if (SYNCHRONOUS == 1) begin : synchronous_reset
    // Video-only candidate: retain reset/lock protection using FDREs.
    // Assertion requires a running clock; INIT holds reset during startup.
    always @(posedge clk)
      if (arst) pipe <= 3'b111;
      else pipe <= {pipe[1:0],1'b0};
    assign rst = pipe[2];
  end else begin : asynchronous_reset
    always @(posedge clk or posedge arst)
      if (arst) pipe <= 3'b111;
      else pipe <= {pipe[1:0],1'b0};
    assign rst = pipe[2];
  end endgenerate
endmodule
