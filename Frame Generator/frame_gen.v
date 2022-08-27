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
