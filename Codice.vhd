library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture A of project_reti_logiche is
    type stato is (INIZIO, RICHIEDI_COL_RIGA, ATTESA_RAM, RICEVI_COL_RIGA, RICHIEDI_PIXEL, RICEVI_PIXEL, CALCOLA_DIM, MIN_MAX, DELTA_VALUE, SHIFT, NUOVO_PIXEL, CHECK_PIXEL, SCRITTURA, FINE, SET_DONE_DOWN);

    signal currState, nextState: stato;
    signal o_addressNext : std_logic_vector (15 downto 0) :="0000000000000000";
    signal o_doneNext, o_enNext, o_weNext: std_logic := '0';
    signal o_dataNext: std_logic_vector (7 downto 0) := "00000000";

    signal row, col, rowNext, colNext : integer range 0 to 128 := 0;
    signal foundRow, foundColumn, foundRowNext, foundColumnNext, secondRead, secondReadNext : boolean := false;
    signal dimImg, dimImgNext : integer range 0 to 16384 := 0;
    signal byteRead, byteReadNext : integer range 0 to 16384 := 0;
    signal address, addressNext : std_logic_vector(15 downto 0) := "0000000000000010";
    signal writeAddress, writeAddressNext, tempPixel, tempPixelNext : std_logic_vector(15 downto 0) := "0000000000000000";
    signal currPixel, currPixelNext, max, min, maxNext, minNext : integer range 0 to 255 := 0;
    signal newPixel, newPixelNext : std_logic_vector (7 downto 0) := "00000000";
    signal deltaValue, deltaValueNext : integer range 0 to 255 := 0;
    signal shiftLevel, shiftLevelNext : integer range 0 to 8 := 0;

begin
    process (i_clk, i_rst)
    begin
        if (i_rst = '1') then
            foundRow <= false;
            foundColumn <= false;
            secondRead <= false;
            row <= 0;
            col <= 0;
            min <= 0;
            max <= 0;
            dimImg <= 0;
            byteRead <= 0;
            newPixel <= "00000000";
            currPixel <= 0;
            address <= "0000000000000010";
            writeAddress <= "0000000000000000";
            tempPixel <= "0000000000000000";
            shiftLevel <= 0;
            deltaValue <= 0;
            currState <= INIZIO;

        elsif (i_clk'event and i_clk='1') then
            o_done <= o_doneNext;
            o_en <= o_enNext;
            o_we <= o_weNext;
            o_data <= o_dataNext;
            o_address <= o_addressNext;
            row <= rowNext;
            col <= colNext;
            foundRow <= foundRowNext;
            foundColumn <= foundColumnNext;
            min <= minNext;
            max <= maxNext;
            dimImg <=dimImgNext;
            address <= addressNext;
            writeAddress <= writeAddressNext;
            currPixel <= currPixelNext;
            newPixel <= newPixelNext;
            secondRead <= secondReadNext;
            byteRead <=byteReadNext;
            deltaValue <= deltaValueNext;
            shiftLevel<= shiftLevelNext;
            tempPixel <= tempPixelNext;
            currState <= nextState;
        end if;
    end process;

    process (currState, i_data, i_start, row, col, newPixel, currPixel, address, foundColumn, foundRow, dimImg, secondRead, min, max, deltaValue, shiftLevel, byteRead, writeAddress, tempPixel)
    begin
        o_doneNext <= '0';
        o_enNext <= '0';
        o_dataNext <= "00000000";
        o_addressNext <= "0000000000000000";
        o_weNext <= '0';

        foundRowNext <= foundRow;
        foundColumnNext <= foundColumn;
        minNext <= min;
        maxNext <= max;
        dimImgNext <= dimImg;
        addressNext <= address;
        writeAddressNext <= writeAddress;
        rowNext <= row;
        colNext <= col;
        secondReadNext <= secondRead;
        byteReadNext <= byteRead;
        currPixelNext <= currPixel;
        shiftLevelNext <= shiftLevel;
        tempPixelNext <= tempPixel;
        newPixelNext <= newPixel;
        deltaValueNext <= deltaValue;
        nextState <= currState;

        case currState is
            when INIZIO =>
                if (i_start='1') then
                    nextState <= RICHIEDI_COL_RIGA;
                end if;

            when RICHIEDI_COL_RIGA =>
                o_enNext <= '1';
                o_weNext <= '0';
                if (not foundColumn) then
                    o_addressNext <= "0000000000000000";
                elsif (not foundRow) then
                    o_addressNext <= "0000000000000001";
                end if;
                nextState <= ATTESA_RAM;

            when ATTESA_RAM =>
                if ((not foundRow) or (not foundColumn)) then
                    nextState <= RICEVI_COL_RIGA;
                else
                    nextState <= RICEVI_PIXEL;
                end if;
            
            when RICEVI_COL_RIGA =>
                
                if (not foundColumn) then
                    colNext <= to_integer(unsigned(i_data));
                    foundColumnNext <= true;
                    nextState <= RICHIEDI_COL_RIGA;
                
                elsif (not foundRow) then
                    rowNext <= to_integer(unsigned(i_data));
                    foundRowNext <= true;
                    nextState <= CALCOLA_DIM;
                end if;

            when CALCOLA_DIM =>
                    if(row = 0 or col = 0)then
                        nextState<=FINE;
                    else
                    dimImgNext <= row*col;
                    writeAddressNext <= std_logic_vector(to_unsigned(row*col+2, 16));
                    nextState <= RICHIEDI_PIXEL;
                    end if;
            
            when RICHIEDI_PIXEL =>
                o_enNext <= '1';
                o_weNext <= '0';
                o_addressNext <= address;
                nextState <= ATTESA_RAM;
               

            when RICEVI_PIXEL =>
                currPixelNext <= to_integer(unsigned (i_data));
                byteReadNext <= byteRead + 1;
                addressNext <= address + "0000000000000001";
                if (secondRead) then
                    nextState <= NUOVO_PIXEL;
                else
                    nextState <= MIN_MAX;
                end if;

            when MIN_MAX =>
                if (byteRead = 1) then --se ho letto solo un byte, quello  sia massimo sia minimo--
                    minNext <= currPixel;
                    maxNext <= currPixel;
                end if;    
                if (byteRead > 1) then
                    if (currPixel < min) then
                        minNext <= currPixel;
                    end if;
                    if (currPixel > max) then
                        maxNext <= currPixel;
                    end if;
                end if;    
                if (byteRead < dimImg) then
                    nextState <= RICHIEDI_PIXEL;
                end if;
                if (byteRead = dimImg) then
                    nextState <= DELTA_VALUE;
                end if;

            when DELTA_VALUE =>
                deltaValueNext <= max - min;
                nextState <= SHIFT;

            when SHIFT =>
                if (deltaValue = 0) then
                    shiftLevelNext <= 8;
                elsif (deltaValue >= 1 and deltaValue <= 2) then
                    shiftLevelNext <= 7;
                elsif (deltavalue >= 3 and deltaValue <= 6) then
                    shiftLevelNext <= 6;
                elsif (deltaValue >= 7 and deltaValue <= 14) then
                    shiftLevelNext <= 5;
                elsif (deltaValue >= 15 and deltaValue <= 30) then
                    shiftLevelNext <= 4;
                elsif (deltaValue >= 31 and deltaValue <= 62) then
                    shiftLevelNext <= 3;
                elsif (deltaValue >= 63 and deltaValue <= 126) then
                    shiftLevelNext <= 2;
                elsif (deltaValue >= 127 and deltaValue <= 254) then
                    shiftLevelNext <= 1;
                else
                    shiftLevelNext <= 0;
                end if;

                secondReadNext <= true;
                byteReadNext <= 0;
                addressNext <= "0000000000000010";
                nextState <= RICHIEDI_PIXEL;
            
            when NUOVO_PIXEL => 
                tempPixelNext <= std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(currPixel-min, 16))), shiftLevel));
                nextState <= CHECK_PIXEL;

            when CHECK_PIXEL =>
                if (to_integer(unsigned(tempPixel)) < 255) then
                    newPixelNext <= std_logic_vector(to_unsigned(to_integer(unsigned(tempPixel)), 8));
                else 
                    newPixelNext <= "11111111";
                end if;
                nextState <= SCRITTURA;
                

            when SCRITTURA =>
                o_enNext <= '1';
                o_weNext <= '1';
                o_addressNext <= writeAddress;
                o_dataNext <= newPixel;
                if (byteRead = dimImg) then
                    nextState <= FINE;
                else
                    writeAddressNext <= writeAddress + "0000000000000001";
                    nextState <= RICHIEDI_PIXEL;
                end if;
                      
            when FINE =>
                o_doneNext <= '1';
                if (i_start = '0') then
                    foundRowNext <= false;
                    foundColumnNext <= false;
                    secondReadNext <= false;
                    rowNext <= 0;
                    colNext <= 0;
                    minNext <= 0;
                    maxNext <= 0;
                    dimImgNext <= 0;
                    byteReadNext <= 0;
                    newPixelNext <= "00000000";
                    currPixelNext <= 0;
                    addressNext <= "0000000000000010";
                    writeAddressNext <= "0000000000000000";
                    shiftLevelNext <= 0;
                    deltaValueNext <= 0;
                    tempPixelNext <= "0000000000000000";           
                    nextState <= SET_DONE_DOWN;
                else
                    nextState <= FINE;
                end if;
                    
                when SET_DONE_DOWN =>
                    o_doneNext <= '0';
                    nextState<=INIZIO;               
        end case;
    end process;
end A;





                

            
            




    