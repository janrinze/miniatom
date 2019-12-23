
module ps2m(input clk,input reset,
			inout ps2c, inout ps2d,
			output dummyc, output dummyd, 
			output reg x,output reg y);

reg [12:0] counter = 0;
reg flag = 0;
reg psd = 0;
reg selc = 0;
reg seld = 1'b0;
reg [8:0] dataout = 9'b011110100; // parity is put as one.
reg negold = 0,negnew = 0;
reg [3:0] dcount = 4'b0000 ;
reg [5:0] bcount=6'b000000;
reg initialised = 1'b0;
reg [32:0] data_in;
reg [5:0] init_count = 6'b000000;

always@(posedge clk) begin
	negnew <= ps2c; // for detecting -ve edge
	negold <= negnew;

	counter = counter + 1;
	if((flag == 1) && (counter == 13'b1001110001000))
	begin
		flag = 0;
		selc = 0; //give clk control to mouse
		seld = 1'b1; // this makes the ps2d as zero and after this we start to tx the word
	end
	if(reset == 1'b1)// one or zero
	begin
		flag = 1;
		selc = 1;
		counter = 0;
		psd = 0;
	end
	if((selc == 0) && (negold == 1) && (negnew == 0))
	begin
		if(dcount < 9) begin
			psd = dataout[dcount];
		end
		else 
		begin
			seld = 0; //give data control to mouse
		end
		dcount = dcount + 1;
	end
end // end always

// initiall y give control to moise. then make seld1 for fpga 
// when psd is 0 give control to mouse
assign ps2c = selc ? 1'b0 : 1'bz;
assign ps2d = seld ? psd : 1'bz;
assign dummyc = ps2c;
assign dummyd = ps2d;
always @ (negedge ps2c)
begin
	if(init_count == 46)
	begin
		initialised = 1;
	end
	
	init_count = init_count + 1;
	if(initialised == 1'b1)
	begin
		data_in[bcount] = ps2d;
		bcount = bcount + 1;
		if(bcount == 33)
		begin
			bcount=0;
			x=data_in[4];
			y=data_in[5];
		end
	end
end // end always
endmodule
