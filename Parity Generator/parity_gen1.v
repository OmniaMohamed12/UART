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
         temp=(data_in[0] ^data_in[1] ^data_in[2] ^data_in[3]);// we should replace it by *temp= ^data_in;*
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