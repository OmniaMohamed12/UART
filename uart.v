
module uart(
 input baud_out /*clock,*/ ,rst,send,
 input [1:0] baud_rate,
 input [7:0] data_in, 
 input [1:0] parity_type,
 input stop_bits, //low when using 1 stop bit, high when using two stop bits
 output data_out , //Serial data_out
 output p_parity_out, //parallel odd parity output, low when using the frame parity.
 output tx_active, //high when Tx is transmitting, low when idle.
 output tx_done ); //high when transmission is done, low when not.
 
 wire parity_out; //,baud_out;
 wire [11:0] frame_out;

 //sub_modules
 parity_gen1 parity(rst, data_in, parity_type, parity_out);
 frame_gen frame_gen1 (rst ,data_in, parity_out, parity_type, stop_bits,data_length,frame_out);
 //baud_gen baud_gen (clock, baud_rate, baud_out);// we will force the baud_out as a clock in the simulation
  piso shift_reg (rst,frame_out,parity_type,stop_bits,send,baud_out,data_out,parity_out,p_parity_out,tx_active,tx_done);
endmodule

module parity_gen1(rst,data_in,parity_type,parity_out);
  input rst;
  input [7:0] data_in;
 input [1:0] parity_type;
 output reg parity_out;
 reg temp;
 always@(rst,parity_type,data_in)
   begin
     if(rst)
       parity_out<=1'b0;
     else
       begin
         temp=(data_in[0] ^data_in[1] ^data_in[2] ^data_in[3]);// we should replace it by *temp= ^data_in;
         temp=(temp ^data_in[4] ^data_in[5]);
         temp=(temp^ data_in[6]^ data_in[7]);
         
         case(parity_type)
           2'b01: parity_out<=temp;
           2'b10:parity_out<=~temp;
           2'b11:parity_out<=~temp;
         endcase
       end
   end
endmodule
// frame
module frame_gen (rst, data_in, parity_out, parity_type, stop_bits, data_length, frame_out);
input rst,data_length,stop_bits,parity_out;
input [7:0] data_in;input [1:0] parity_type;
output reg [11:0] frame_out;
wire stop=1;
wire start_bit=0;
reg [7:0]data_in_internal;
always @(*) begin
  data_in_internal<={data_in[0],data_in[1],data_in[2],data_in[3]// reversing the data_in
                     ,data_in[4],data_in[5],data_in[6],data_in[7]};
  if(rst) begin
    frame_out <=11'd2047;//idle all bits are one
  end
  else begin
    if(stop_bits)begin// adding 2 stop bits
      if(data_length)begin// check the length
        if(parity_type==2'b00 || parity_type==2'b11)// check parity
          frame_out <= {start_bit,data_in_internal,stop,stop};
        else frame_out <= {start_bit,data_in_internal,parity_out,stop,stop};
      end
      else begin
        if(parity_type==2'b00 || parity_type==2'b11)
          frame_out <= {start_bit,data_in_internal[7:1],stop,stop};
        else frame_out <= {start_bit,data_in_internal[7:1],parity_out,stop,stop};
      end
    end
  else begin
    if(data_length)begin
        if(parity_type==2'b00 || parity_type==2'b11)
          frame_out <= {start_bit,data_in_internal,stop};
        else frame_out <= {start_bit,data_in_internal,parity_out,stop};
      end
      else begin
        if(parity_type==2'b00 || parity_type==2'b11)
          frame_out <= {start_bit,data_in_internal[7:1],stop};
        else frame_out <= {start_bit,data_in_internal[7:1],parity_out,stop};
      end
  end
  end
end
endmodule
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
// baud_gen
module baud_gen(clock,baud_rate,baud_out);
  input clock;
  output reg baud_out;
  input [1:0] baud_rate;

reg [14:0] counter;
  integer div;
  always@(posedge clock )
  begin
    case(baud_rate)
      2'b00:begin
        div<=20833;// divide by 16 in receiver only
      end
      2'b01:begin
        div<=10416;
      end
      2'b10:begin
        div<=5208;
      end
      2'b11:begin
        div<=2604;
      end
    endcase
    if(counter==div)
      begin
        baud_out=~baud_out;
        counter<=0;
      end
    else counter<=counter+1;
  end
endmodule