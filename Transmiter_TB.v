


module Transmiter_TB ();

  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
    parameter c_CLOCK_PERIOD_NS = 100;
    parameter c_CLKS_PER_BIT    = 1042;
    parameter c_BIT_PERIOD      = 8600;
    

    /*
    100
    87
    8600
    */
    reg r_Clock = 0;
    reg r_Tx_DV = 0;
    wire w_Tx_Done;
    reg [7:0] r_Tx_Byte = 0;
    reg r_Rx_Serial = 1;
    wire [7:0] w_Rx_Byte;
    
    
    // Takes in input byte and serializes it 
    task UART_WRITE_BYTE;
        input [7:0] i_Data;
        integer     ii;
        begin
        
        // Send Start Bit
        r_Rx_Serial <= 1'b0;
        #(c_BIT_PERIOD);
        #1000;
        
        
        // Send Data Byte
        for (ii=0; ii<8; ii=ii+1)
            begin
            r_Rx_Serial <= i_Data[ii];
            #(c_BIT_PERIOD);
            end
        
        // Send Stop Bit
        r_Rx_Serial <= 1'b1;
        #(c_BIT_PERIOD);
        end
    endtask // UART_WRITE_BYTE
    
    
    uartReceiber #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
        (.clk(r_Clock),
        .serialStream(r_Rx_Serial),
        .dataValid(),
        .Bite(w_Rx_Byte)
        );
    
    uartTransmiter #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST
        (.clk(r_Clock),
        .dataValid(r_Tx_DV),
        .P_BYTE(r_Tx_Byte),
        .active(),
        .serialStream(),
        .done(w_Tx_Done)
        );
    
    
    always
        #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
    
    
    // Main Testing:
    initial
        begin
        
        // Tell UART to send a command (exercise Tx)
        @(posedge r_Clock);
        @(posedge r_Clock);
        r_Tx_DV <= 1'b1;
        r_Tx_Byte <= 8'hAB;
        @(posedge r_Clock);
        r_Tx_DV <= 1'b0;
        @(posedge w_Tx_Done);
        
        // Send a command to the UART (exercise Rx)
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h3F);
        @(posedge r_Clock);
                
        // Check that the correct command was received
        if (w_Rx_Byte == 8'h3F)
            $display("Test Passed - Correct Byte Received");
        else
            $display("Test Failed - Incorrect Byte Received");
        
        end
    
    endmodule

