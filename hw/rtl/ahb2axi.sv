// Copyright AccurateRTL contributors.
// Licensed under the MIT License, see LICENSE for details.
// SPDX-License-Identifier: MIT

module ahb2axi #(parameter A_WIDTH = 32, D_WIDTH = 32, ID_WIDTH = 4, USER_WIDTH=4)
(
  input   clk,
  input   rst_n,
  
  output logic   [ ID_WIDTH-1:0]       awid,
  output logic   [  A_WIDTH-1:0]       awaddr,
  output logic   [ 7:0]                awlen,
  output logic   [ 2:0]                awsize,
  output logic   [ 1:0]                awburst,
  output logic                         awlock,
  output logic   [ 3:0]                awcache,
  output logic   [ 2:0]                awprot,
  output logic   [ 3:0]                awregion,
  output logic   [ USER_WIDTH-1:0]     awuser,
  output logic   [ 3:0]                awqos,
  output logic                         awvalid,
  input                                awready,
  
  output logic   [    D_WIDTH-1:0]     wdata,
  output logic   [(D_WIDTH/8)-1:0]     wstrb,
  output logic                         wlast,
  output logic   [ USER_WIDTH-1:0]     wuser,
  output logic                         wvalid,
  input                                wready,
  
  input          [ ID_WIDTH-1:0]       bid,
  input          [ 1:0]                bresp,
  input                                bvalid,
  input          [ USER_WIDTH-1:0]     buser,
  output logic                         bready,
  
  output logic   [ ID_WIDTH-1:0]       arid,
  output logic   [ A_WIDTH-1:0]        araddr,
  output logic   [ 7:0]                arlen,
  output logic   [ 2:0]                arsize,
  output logic   [ 1:0]                arburst,
  output logic                         arlock,
  output logic   [ 3:0]                arcache,
  output logic   [ 2:0]                arprot,
  output logic   [ 3:0]                arregion,
  output logic   [ USER_WIDTH-1:0]     aruser,
  output logic   [ 3:0]                arqos,
  output logic                         arvalid,
  input                                arready,
  
  input          [ ID_WIDTH-1:0]       rid,
  input          [ D_WIDTH-1:0]        rdata,
  input          [ 1:0]                rresp,
  input                                rlast,
  input                                rvalid,
  input          [ USER_WIDTH-1:0]     ruser,
  output logic                         rready,
  
  input               hbusreq,
  output logic        hgrant, 
  
  input        [31:0] haddr, 
  input        [1:0]  htrans,
  input        [1:0]  hsize,
  output logic        hready,
  input               hwrite,
  input        [31:0] hwdata,
  output logic [1:0]  hresp, 
  output logic [31:0] hrdata 
);

typedef enum {
    WAITING_AHB_TRANS,
    REQUESTING_AW_TRANS,
    REQUESTING_W_TRANS,
    WAITING_B_RESP,
    REQUESTING_AR_TRANS,
    WAITING_R_RESP
} ahb2axi_sm_states;

ahb2axi_sm_states stt;



//assign 
assign awlen    = 8'h0;
assign awsize   = 2'b10;   // 4 byte
assign awburst  = 2'b00;   // Fixed
assign awlock   = 1'b0; 
assign awcache  = 3'b000;  // Device Non-bufferable
assign awprot   = 3'b011;
assign awregion = '0;
assign awuser   = '0;
assign awqos    = '0; 

assign wdata  = hwdata;
assign wstrb  = '1;
assign wlast  = 1'b1;
assign wuser  = '0;

assign arlen    = 8'h0;
assign arsize   = 2'b10;   // 4 byte
assign arburst  = 2'b00;   // Fixed
assign arlock   = 1'b0; 
assign arcache  = 3'b000;  // Device Non-bufferable
assign arprot   = 3'b011;
assign arregion = '0;
assign aruser   = '0;
assign arqos    = '0; 


//assign  hrdata = 32'h0;    // STUB!!
assign  hresp = 2'h0;

always_comb begin
  if (stt==WAITING_R_RESP)
     hrdata = rdata;
  else
     hrdata = '0;
end  

always_comb begin
  case (stt)
    WAITING_AHB_TRANS: 
      hready = 1'b1;
    REQUESTING_AW_TRANS:
      hready = 1'b0;
    REQUESTING_W_TRANS:
      hready = 1'b0;
    WAITING_B_RESP:
      hready = bvalid;
    REQUESTING_AR_TRANS:  
      hready = 1'b0;
    WAITING_R_RESP:
      hready = rvalid;
    default: begin
      hready = 1'b0;
    end
  endcase
end

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) 
    hgrant <= 1'b0;
  else
    hgrant <= hbusreq;  
end

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    stt          <= WAITING_AHB_TRANS;
    awvalid      <= 1'b0;
    arvalid      <= 1'b0;
    awid         <= '0;
    arid         <= '0;
    wvalid       <= 1'b0;
    bready       <= 1'b0;
    rready       <= 1'b0;
  end
  else begin
    case (stt)
      WAITING_AHB_TRANS: begin
        if (htrans==2'b10) begin
          if (hwrite) begin  
            stt          <= REQUESTING_AW_TRANS;
            awvalid      <= 1'b1;
            awaddr       <= haddr;
          end
          else begin
            stt          <= REQUESTING_AR_TRANS;
            arvalid      <= 1'b1;
            araddr       <= haddr; 
          end
        end
      end
      
      REQUESTING_AW_TRANS: begin
        if (awready) begin
          stt     <= REQUESTING_W_TRANS;
          awvalid <= 1'b0;
          wvalid  <= 1'b1;
        end
      end
            
      REQUESTING_W_TRANS: begin
        if (wready) begin
          wvalid  <= 1'b0;
          stt     <= WAITING_B_RESP;
          bready  <= 1'b1;
        end
      end
      
      WAITING_B_RESP: begin
        if (bvalid) begin
          if (htrans==2'b00) 
            stt    <= WAITING_AHB_TRANS;
          else begin
            if (hwrite) begin  
              stt          <= REQUESTING_AW_TRANS;
              awvalid      <= 1'b1;
              awaddr       <= haddr;
            end
            else begin
              stt          <= REQUESTING_AR_TRANS;
              arvalid      <= 1'b1;
              araddr       <= haddr;
            end 
          end
          bready <= 1'b0;
          awid   <= awid + 1;
        end
      end

      REQUESTING_AR_TRANS: begin
        if (arready) begin
          arvalid     <= 1'b0;
          stt         <= WAITING_R_RESP;
          rready      <= 1'b1;
        end
      end
      
      WAITING_R_RESP: begin
        if (rvalid) begin
          rready      <= 1'b0;
          arid        <= arid + 1;
          if (htrans==2'b00) 
            stt    <= WAITING_AHB_TRANS;
          else begin
            if (hwrite) begin  
              stt          <= REQUESTING_AW_TRANS;
              awvalid      <= 1'b1;
              awaddr       <= haddr;
            end
            else begin
              stt          <= REQUESTING_AR_TRANS;
              arvalid      <= 1'b1;
              araddr       <= haddr;
            end
          end
        end
      end

      default: begin
        stt <= WAITING_AHB_TRANS;
      end
    endcase  
  end    
end


endmodule


