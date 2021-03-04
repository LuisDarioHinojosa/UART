module uartTransmiter
#(parameter clocksPerBit = 5208) // 50,000,000/9600 baud rate
(
    input clk,
    input dataValid,
    input [7:0] inputByte,
    output oActive, // hight while transmiter is active
    output reg serial, // this one is the current bit we are in during the transmision
    output oDone // it tells other modules the transmiter is done with the current byte
);


// states 
parameter IDLE = 3'b000;
parameter START_T = 3'b000;
parameter DATA_BITS = 3'b000;
parameter STOP_T = 3'b000;
parameter CLEANUP = 3'b000;



// Usefull stuff 
  reg [2:0]    STATE     = 0; // current state
  reg [7:0]    Clock_Count = 0; // clock count for sampling bits
  reg [2:0]    Bit_Index   = 0; // bit index for keping track of when to start the stop state
  reg [7:0]    Data     = 0; // store the byte for transition at the beggining
  reg          Done     = 0; // to indicate another module the transmition is over
  reg          Active   = 0; 



always @(posedge clk)
    begin
        case(STATE)

            IDLE:
                begin
                    // initialize variables
                    serial <= 1'b1;
                    Done <= 1'b0;
                    Clock_Count <= 0;
                    Bit_Index <= 0;
                    if(dataValid == 1)
                        begin
                            Active <= 1'b1; // the active will remain on througput the transmition
                            Data <= inputByte; // we pass in here the input byte as a backup 
                            STATE <= START_T; // we pass the start transmition state
                        end
                    else 
                        STATE <= IDLE;
                end

            START_T:
                begin
                    serial <= 1'b0; // set the start bit to 0
                    if(Clock_Count < clocksPerBit -1)
                        begin
                            Clock_Count <= Clock_Count + 1;
                            STATE <= START_T;
                        end
                    else 
                        begin
                            Clock_Count <= 0;
                            STATE <= DATA_BITS;
                        end
                end

            DATA_BITS:
                begin
                    serial <= Data[Bit_Index];
                    if(Clock_Count < clocksPerBit -1)
                        begin
                            Clock_Count <= Clock_Count + 1;
                            STATE <= DATA_BITS;
                        end
                    else 
                        begin
                            Clock_Count <= 0;
                            if(Bit_Index < 7)
                                begin
                                    Bit_Index <= Bit_Index +1;
                                    STATE <= DATA_BITS;
                                    
                                end
                            else 
                                begin
                                    Bit_Index <= 0;
                                    STATE <= STOP_T;
                                end
                        end 
                end

            STOP_T:
                begin
                    serial = 1'b1;
                    if(Clock_Count < clocksPerBit -1)
                        begin
                            Clock_Count <= Clock_Count +1;
                            STATE <= STOP_T;
                        end
                    else
                        begin
                            Done <= 1'b1;
                            Clock_Count <= 0;
                            STATE <= CLEANUP;
                            Active <= 0;
                        end
                end

            CLEANUP:
                begin
                    Done = 1'b1;
                    STATE = IDLE;
                end           

            default: STATE <= IDLE;

        endcase
    end

assign oActive =  Active;
assign oDone = Done;

endmodule
