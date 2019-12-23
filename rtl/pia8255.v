
module PIA8255 (
	input clk,
    input cs,
    input reset,
    input [1:0] address,
    input [7:0] Din,
    input we,
    output [7:0] PIAout,
    output [7:0] Port_A,
    input [7:0] Port_B,
    output [3:0] Port_C_low,
    input wire [3:0] Port_C_high
    );

	// ------------------------------------------------------------------------------------
	// 	25.5 Input/Output Port Allocations
	// 
	// The  8255  Programmable  Peripheral  Interface  Adapter  contains  three
	// 8-bit ports, and all but one of these lines is used by the ATOM.
	// 
	// Port A - #B000
	//        Output bits:      Function:
	//             O -- 3     Keyboard row
	//             4 -- 7     Graphics mode
	// 
	// Port B - #B001
	//        Input bits:       Function:
	//             O -- 5     Keyboard column
	//               6        CTRL key (low when pressed)
	//               7        SHIFT keys {low when pressed)
	// 
	// Port C - #B002
	//        Output bits:      Function:
	//             O          Tape output
	//             1          Enable 2.4 kHz to cassette output
	//             2          Loudspeaker
	//             3          Not used
	// 
	//        Input bits:       Function:
	//             4          2.4 kHz input
	//             5          Cassette input
	//             6          REPT key (low when pressed)
	//             7          60 Hz sync signal (low during flyback)
	// 
	// The port C output lines, bits O to 3, may be used for user
	// applications when the cassette interface is not being used.
	// ------------------------------------------------------------------------------------
  
  reg [7:0] Port_A_r, Port_B_r;
  reg [3:0] Port_C_L;
  reg [7:0] PIAout_r;

  always@(posedge clk) begin
    if (reset) begin
       Port_A_r <= 8'h0;
       Port_C_L <= 4'h0;
      end
    else 
      begin
        // latch writes to PIO
          case (address[1:0])
            2'b00: if (cs&we) Port_A_r <= Din;
            2'b10: if (cs&we) Port_C_L <= Din[3:0];
            2'b11: if (cs&we&!Din[7]) Port_C_L[Din[2:1]] <= Din[0];
			2'b01: ;
          endcase
      end
  end

  always @(*) begin
    Port_B_r = Port_B;
  end
  
  always @(*) begin 
    case(address[1:0])
      2'b00: PIAout_r = Port_A_r;
      2'b01: PIAout_r = Port_B_r;
      2'b10: PIAout_r = { Port_C_high ,Port_C_L};
      default:  PIAout_r = 0;
    endcase
  end
  
  assign PIAout = PIAout_r;
  assign Port_C_low = Port_C_L;
  assign Port_A = Port_A_r;
  

endmodule

