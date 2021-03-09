
module uartReceiber 
    #(parameter CLKS_PER_BIT)
    (
        input        clk,
        input        serialStream,
        output       dataValid,
        output [7:0] Bite
    );
    
    // pretty much the same fsm of the transmiter, but this one does the reversal (serial to paralele byte)
    parameter IDDLE         = 3'b000;
    parameter START_TRANS = 3'b001;
    parameter DATA_BITS = 3'b010;
    parameter STOP_BITS  = 3'b011;
    parameter CLEANUP      = 3'b100;
    

    // I Have not figure out what do this variables do, so i will write them as they were
    reg           r_Rx_Data_R = 1'b1;
    reg           r_Rx_Data   = 1'b1;
    

    reg [7:0]     CLOCK_COUNT = 0;
    reg [2:0]     BIT_INDEX   = 0; //8 bits total
    reg [7:0]     BYTE_BACKUP   = 0;
    reg           DATAV_FLAG   = 0;
    reg [2:0]     STATE     = 0;
    

    always @(posedge clk)
        begin
            r_Rx_Data_R <= serialStream;
            r_Rx_Data   <= r_Rx_Data_R;
        end
    
    
    // Purpose: Control RX state machine
    always @(posedge clk)
        begin
        
            case (STATE)
                IDDLE :
                begin
                    // initialize iterators
                    DATAV_FLAG       <= 1'b0; // on downedge
                    CLOCK_COUNT <= 0; // reset clockcount
                    BIT_INDEX   <= 0; 
                    
                    if (r_Rx_Data == 1'b0)          // Start bit detected
                        STATE <= START_TRANS;
                    else
                        STATE <= IDDLE;
                end
                
                // Check middle of start bit to make sure it's still low
                START_TRANS :
                begin
                    if (CLOCK_COUNT == (CLKS_PER_BIT-1)/2)
                        begin
                            if (r_Rx_Data == 1'b0)
                                begin
                                    CLOCK_COUNT <= 0;  // reset counter, found the middle
                                    STATE     <= DATA_BITS;
                                end
                            else
                                STATE <= IDDLE;
                        end
                    else
                        begin
                            CLOCK_COUNT <= CLOCK_COUNT + 1;
                            STATE     <= START_TRANS;
                        end
                end // case: START_TRANS
                
                
                // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
                DATA_BITS :
                begin
                    if (CLOCK_COUNT < CLKS_PER_BIT-1)
                        begin
                            CLOCK_COUNT <= CLOCK_COUNT + 1;
                            STATE     <= DATA_BITS;
                        end
                    else
                        begin
                            CLOCK_COUNT          <= 0;
                            BYTE_BACKUP[BIT_INDEX] <= r_Rx_Data;
                            
                            // Check if we have received all bits
                            if (BIT_INDEX < 7)
                                begin
                                    BIT_INDEX <= BIT_INDEX + 1;
                                    STATE   <= DATA_BITS;
                                end
                            else
                                begin
                                    BIT_INDEX <= 0;
                                    STATE   <= STOP_BITS;
                                end
                        end
                end 

                // Receive Stop bit.  Stop bit = 1
                STOP_BITS :
                    begin
                        // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                        if (CLOCK_COUNT < CLKS_PER_BIT-1)
                            begin
                                CLOCK_COUNT <= CLOCK_COUNT + 1;
                                STATE     <= STOP_BITS;
                            end
                        else
                            begin
                                DATAV_FLAG       <= 1'b1;
                                CLOCK_COUNT <= 0;
                                STATE     <= CLEANUP;
                            end
                    end // case: STOP_BITS
            
                
                // Stay here 1 clock
                CLEANUP :
                    begin
                        STATE <= IDDLE;
                        DATAV_FLAG   <= 1'b0;
                    end
                
                
                default :
                    STATE <= IDDLE;
                
            endcase
        end   
    
    assign dataValid   = DATAV_FLAG;
    assign Bite = BYTE_BACKUP;
    
    endmodule // uart_rx