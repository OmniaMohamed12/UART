//piso
module piso(rst,frame_out,parity_type,stop_bits,send,baud_out,data_out,parity_out,p_parity_out,tx_active,tx_done);
input rst;
input [11:0] frame_out;
input [1:0] parity_type;
input stop_bits;
input send; //to start loading the data into SR_reg and add start and stop bits
            //when it is one the frame_out is loaded in SR_register, then it should forced to zero to transmit
            // this concept isn't wrong but in real life it remains one untill the transmission is done
input baud_out;
input parity_out;

output reg data_out;
output reg p_parity_out;// odd parity in case '11', otherwise it's '0'
output reg tx_active;
output reg tx_done;
reg [11:0]SR_reg; //12 bits that will be serially transmitted
reg [3:0]counter;

always@(posedge baud_out)
if (rst)
begin
data_out<=1;
tx_active<=0;
tx_done<=0;
p_parity_out<=1'b0;
end

else begin 
if(parity_type==2'b11) p_parity_out<=parity_out; 
else p_parity_out<=1'b0;
  
  //loading the data
if(send)begin
SR_reg<=frame_out[11:0];
tx_active<=1;
counter<=0;
end
// starting transmission
else begin
data_out<=SR_reg[11];
SR_reg<={SR_reg[10:0],1'b0};// shifting

if (SR_reg==0) tx_done<=0;// resetting after transmission

else if (counter<11)begin
  tx_active<=1;
  counter<=counter+1;// countinting the bits
  tx_done<=0;
end
else begin// counter=12
  counter<=0;
  tx_done<=1;
  tx_active<=0;
end

end

end
endmodule