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