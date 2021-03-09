

module uartTransmiter 
    #(parameter CLKS_PER_BIT)
    (
        input       clk, //  clock
        input       dataValid, // data valid
        input [7:0] P_BYTE, // Byte to converto to serial stream 
        output      active, // willlight in the start transmition stage
        output reg  serialStream, // outout of serial verion of byte
        output      done // if it is done with this krap
    );
    

    // STARES
    parameter IDDLE         = 3'b000; // BASIC STATE
    parameter STARTTRANS = 3'b001; // START TRANSMITION IN THE DOWN EDGE OF THE CLOCK
    parameter DATABITS = 3'b010; // SEND STUFF
    parameter STOPTRANS  = 3'b011; // SEND STOPBIT & STOP
    parameter CLEANUP      = 3'b100; // WRAP UP
    
    reg [2:0]    STATE     = 0;
    reg [7:0]    CLOCK_COUNT = 0;
    reg [2:0]    BIT_INDEX   = 0;
    reg [7:0]    DATA_BACKUP     = 0;
    reg          DONE_WIRE     = 0;
    reg          ACTIVE_WIRE   = 0;
        
    always @(posedge clk)
        begin
            case (STATE)
                // INITIALIZE VARIABLES
                IDDLE :
                    begin
                        serialStream   <= 1'b1;         // Drive Line High for Idle
                        DONE_WIRE     <= 1'b0;
                        CLOCK_COUNT <= 0;
                        BIT_INDEX   <= 0;
                        
                        if (dataValid == 1'b1)
                            begin
                                ACTIVE_WIRE <= 1'b1;  // the active will remain on througput the transmition
                                DATA_BACKUP   <= P_BYTE; // we pass in here the input byte as a backup 
                                STATE   <= STARTTRANS; // we pass the start transmition state
                            end
                        else
                            STATE <= IDDLE;
                    end 
                
                // Send out Start Bit. Start bit = 0
                STARTTRANS :
                    begin
                        serialStream <= 1'b0;
                        
                            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
                            if (CLOCK_COUNT < CLKS_PER_BIT-1)
                            begin
                                CLOCK_COUNT <= CLOCK_COUNT + 1;
                                STATE     <= STARTTRANS;
                            end
                        else
                            begin
                                CLOCK_COUNT <= 0;
                                STATE     <= DATABITS;
                            end
                    end 
                
                
                // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
                DATABITS :
                    begin
                        serialStream <= DATA_BACKUP[BIT_INDEX];
                        
                        if (CLOCK_COUNT < CLKS_PER_BIT-1)
                            begin
                                CLOCK_COUNT <= CLOCK_COUNT + 1;
                                STATE     <= DATABITS;
                            end
                        else
                            begin
                                CLOCK_COUNT <= 0;
                                
                                if (BIT_INDEX < 7)
                                    begin
                                        BIT_INDEX <= BIT_INDEX + 1;
                                        STATE   <= DATABITS;
                                    end
                                else
                                    begin
                                        BIT_INDEX <= 0;
                                        STATE   <= STOPTRANS;
                                    end
                            end
                    end 
                
                
                STOPTRANS :
                begin
                    serialStream <= 1'b1;
                    
                    // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                    if (CLOCK_COUNT < CLKS_PER_BIT-1)
                        begin
                            CLOCK_COUNT <= CLOCK_COUNT + 1;
                            STATE     <= STOPTRANS;
                        end
                    else
                        begin
                            DONE_WIRE     <= 1'b1;
                            CLOCK_COUNT <= 0;
                            STATE     <= CLEANUP;
                            ACTIVE_WIRE   <= 1'b0;
                        end
                end 
                
                

                CLEANUP :
                begin
                    DONE_WIRE <= 1'b1;
                    STATE <= IDDLE;
                end
                
                
                default :
                    STATE <= IDDLE;
                
            endcase
        end
    
    assign active = ACTIVE_WIRE;
    assign done   = DONE_WIRE;

endmodule