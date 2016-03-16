--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2016 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
-- 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
-- コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
-- 布することを無償で許諾する．
--
--   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
-- 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
-- も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
-- る損害に関しても，その責任を負わない．
--
--

--
-- TaC/tac_cpu.vhd : TaC CPU VHDL Source Code
--
-- 2016.01.08           : "DR の制御" 部分 warning 対応
-- 2012.09.27           : TaC-CPU V2 対応完了
-- 2012.01.22           : entity 名、見直し
-- 2011.07.18           : レジスタ G12 を TMP に置き換える
-- 2011.07.18           : レジスタ指定 RxP を TMP に置き換える
-- 2011.06.10           : TeC7 用に書き換える
-- 2010.07.23           : インデントの調整
-- 2010.07.20           : Subversion による管理を開始
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;

entity TAC_CPU is
  port ( P_CLK0  : in  std_logic;                        -- Clock
         P_CLK90 : in  std_logic;
         P_RESET : in  std_logic;                        -- Reset

         P_ADDR  : out std_logic_vector(15 downto 0);    -- ADDRESS BUS
         P_DIN   : in  std_logic_vector(15 downto 0);    -- DATA    BUS
         P_DOUT  : out std_logic_vector(15 downto 0);    -- DATA    BUS

         P_RW    : out std_logic;                        -- Read/Write
         P_IR    : out std_logic;                        -- I/O Req.
         P_MR    : out std_logic;                        -- Memory Req.
         P_LI    : out std_logic;                        -- Instruction Fetch
         P_VR    : out std_logic;                        -- Instruction Fetch
         P_HL    : out std_logic;                        -- Halt Instruction
         P_BT    : out std_logic;                        -- Byte to
         P_PR    : out std_logic;                        -- privilege Mode
         P_INTR  : in  std_logic;                        -- Intrrupt
         P_STOP  : in  std_logic                         -- Panel RUN F/F
        );
end TAC_CPU;


architecture RTL of TAC_CPU is

constant ALU_ZERO : std_logic_vector(3 downto 0) := "0000";
constant ALU_A    : std_logic_vector(3 downto 0) := "0001";
constant ALU_B    : std_logic_vector(3 downto 0) := "0010";
constant ALU_ADD  : std_logic_vector(3 downto 0) := "0011";
constant ALU_SUB  : std_logic_vector(3 downto 0) := "0100";
constant ALU_AND  : std_logic_vector(3 downto 0) := "0101";
constant ALU_OR   : std_logic_vector(3 downto 0) := "0110";
constant ALU_XOR  : std_logic_vector(3 downto 0) := "0111";
constant ALU_INC2 : std_logic_vector(3 downto 0) := "1000";
constant ALU_DEC2 : std_logic_vector(3 downto 0) := "1001";
constant ALU_XADD : std_logic_vector(3 downto 0) := "1010";
constant ALU_XSUB : std_logic_vector(3 downto 0) := "1011";
constant ALU_RROT : std_logic_vector(3 downto 0) := "1100";
constant ALU_LROT : std_logic_vector(3 downto 0) := "1101";
constant ALU_SFT  : std_logic_vector(3 downto 0) := "1110";
constant ALU_SUBC : std_logic_vector(3 downto 0) := "1111";

-- レジスタの指定
constant REG_NO   : std_logic_vector(2 downto 0) := "000";
constant REG_FP   : std_logic_vector(2 downto 0) := "000";
constant REG_SP   : std_logic_vector(2 downto 0) := "001";
constant REG_PC   : std_logic_vector(2 downto 0) := "010";
constant REG_FLAG : std_logic_vector(2 downto 0) := "011";
constant REG_Rd   : std_logic_vector(2 downto 0) := "100";
constant REG_RdP  : std_logic_vector(2 downto 0) := "101";
constant REG_Rx   : std_logic_vector(2 downto 0) := "110";
constant REG_TMP  : std_logic_vector(2 downto 0) := "111";

-- フラグ操作の指定
constant FLG_NO   : std_logic_vector(2 downto 0) := "000";
constant FLG_LF   : std_logic_vector(2 downto 0) := "001";
constant FLG_STI  : std_logic_vector(2 downto 0) := "010";
constant FLG_CLI  : std_logic_vector(2 downto 0) := "011";
constant FLG_STP  : std_logic_vector(2 downto 0) := "100";
constant FLG_CLP  : std_logic_vector(2 downto 0) := "101";

-- BUS instruction
constant BUS_NO   : std_logic_vector(3 downto 0) := "0000";
constant BUS_MEMR : std_logic_vector(3 downto 0) := "0001";
constant BUS_MEMW : std_logic_vector(3 downto 0) := "0010";
constant BUS_IOR  : std_logic_vector(3 downto 0) := "0011";
constant BUS_IOW  : std_logic_vector(3 downto 0) := "0100";
constant BUS_FETCH: std_logic_vector(3 downto 0) := "0101";
constant BUS_VECT : std_logic_vector(3 downto 0) := "0110";
constant BUS_IOF  : std_logic_vector(3 downto 0) := "0111";
constant BUS_LDRX : std_logic_vector(3 downto 0) := "1000";
constant BUS_HALT : std_logic_vector(3 downto 0) := "1001";
constant BUS_MEMRB: std_logic_vector(3 downto 0) := "1010";
constant BUS_MEMWB: std_logic_vector(3 downto 0) := "1011";
constant BUS_IORB : std_logic_vector(3 downto 0) := "1100";
constant BUS_IOWB : std_logic_vector(3 downto 0) := "1101";

-- JP フィールドの値
-- ジャンプの条件
constant JMP_NO   : std_logic_vector(3 downto 0) := "0000";
constant JMP_ALL  : std_logic_vector(3 downto 0) := "0001";
constant JMP_OP   : std_logic_vector(3 downto 0) := "0010";
constant JMP_INT  : std_logic_vector(3 downto 0) := "0011";
constant JMP_CTDR : std_logic_vector(3 downto 0) := "0100";
constant JMP_NJ   : std_logic_vector(3 downto 0) := "0101";
constant JMP_CT16 : std_logic_vector(3 downto 0) := "0110";
constant JMP_STP  : std_logic_vector(3 downto 0) := "0111";
constant JMP_DI   : std_logic_vector(3 downto 0) := "1000";
constant JMP_SPR  : std_logic_vector(3 downto 0) := "1001";
constant JMP_PCR  : std_logic_vector(3 downto 0) := "1010";
constant JMP_IM   : std_logic_vector(3 downto 0) := "1011";
constant JMP_NPRV : std_logic_vector(3 downto 0) := "1100";
constant JMP_ZERO : std_logic_vector(3 downto 0) := "1101";

-- レジスタファイル
signal I_G0  : std_logic_vector(15 downto 0);  -- G0
signal I_G1  : std_logic_vector(15 downto 0);  -- G1
signal I_G2  : std_logic_vector(15 downto 0);  -- G2
signal I_G3  : std_logic_vector(15 downto 0);  -- G3
signal I_G4  : std_logic_vector(15 downto 0);  -- G4
signal I_G5  : std_logic_vector(15 downto 0);  -- G5
signal I_G6  : std_logic_vector(15 downto 0);  -- G6
signal I_G7  : std_logic_vector(15 downto 0);  -- G7
signal I_G8  : std_logic_vector(15 downto 0);  -- G8
signal I_G9  : std_logic_vector(15 downto 0);  -- G9
signal I_G10 : std_logic_vector(15 downto 0);  -- G10
signal I_G11 : std_logic_vector(15 downto 0);  -- G11
signal I_G12 : std_logic_vector(15 downto 0);  -- G12
signal I_SSP : std_logic_vector(15 downto 0);  -- SSP
signal I_USP : std_logic_vector(15 downto 0);  -- USP
signal I_PC  : std_logic_vector(15 downto 0);  -- PC
signal I_TMP : std_logic_vector(15 downto 0);  -- TMP

-- フラグ
signal I_E   : std_logic;                     -- Interrupt Enable
signal I_P   : std_logic;                     -- Privilege
signal I_V   : std_logic;                     -- Over Flow
signal I_C   : std_logic;                     -- Carry
signal I_S   : std_logic;                     -- Sign
signal I_Z   : std_logic;                     -- Zero

-- レジスタファイルの制御
signal I_WRA : std_logic_vector(5 downto 0);  -- Write Address(MSB = Enable)
signal I_RRA : std_logic_vector(4 downto 0);  -- Read  Address
signal I_RRD : std_logic_vector(15 downto 0); -- Read  Data
signal I_RRX : std_logic_vector(15 downto 0); -- IX 用の Read  Data

-- レジスタ
signal I_DR  : std_logic_vector(15 downto 0); -- DR
signal I_OPR : std_logic_vector(15 downto 0); -- OPR 
signal I_AR  : std_logic_vector(15 downto 0); -- AR
signal I_MPC : std_logic_vector(7 downto 0);  -- MPC
signal I_OP  : std_logic_vector(7 downto 0);  -- IR の OP
signal I_RD  : std_logic_vector(3 downto 0);  -- IR の Rd
signal I_RX  : std_logic_vector(3 downto 0);  -- IR の Rx
signal I_CT  : std_logic_vector(3 downto 0);  -- 繰り返し用カウンタ
-- 内部配線
signal I_ALUT : std_logic_vector(16 downto 0); -- ALU の内部で使用
signal I_ALU  : std_logic_vector(15 downto 0); -- ALU の出力
signal I_CTP1 : std_logic_vector(3  downto 0); -- I_CT + 1
signal I_AV   : std_logic;                     -- ALU の Over flow 出力
signal I_AC   : std_logic;                     -- ALU の Carry 出力
signal I_AZ   : std_logic;                     -- ALU の Zero  出力
signal I_AS   : std_logic;                     -- ALU の Sign  出力

signal I_JMP     : std_logic;                  -- 機械語のジャンプ条件が成立
signal I_MPCLDAB : std_logic_vector(1 downto 0);  -- MPC (LD & A/B)

-- instruction decode ROM output
signal I_DCODE : std_logic_vector(7 downto 0);

-- instruction decode ROM address
signal I_DECAD : std_logic_vector(8 downto 0);

-- micro code ROM output
signal I_MCODE : std_logic_vector(31 downto 0);

-- micro code
signal M_ALU : std_logic_vector(3 downto 0);
signal M_RR  : std_logic_vector(2 downto 0);
signal M_WR  : std_logic_vector(2 downto 0);
signal M_FLG : std_logic_vector(2 downto 0);
signal M_LA  : std_logic;
signal M_LO  : std_logic;
signal M_BUS : std_logic_vector(3 downto 0);
signal M_JP  : std_logic_vector(3 downto 0);
signal M_JA  : std_logic_vector(7 downto 0);

-- decoded bus micro instruction
signal M_IX  : std_logic;
signal M_LD  : std_logic;
signal M_HL  : std_logic;
signal M_LI  : std_logic;
signal M_RW  : std_logic;
signal M_MR  : std_logic;
signal M_IR  : std_logic;
signal M_VR  : std_logic;
signal M_BT  : std_logic;
signal M_DBUS: std_logic_vector(8 downto 0);  -- IX&LD&HL&LI&RW&MR&IR&VR&BT

-- decode ROM
component TAC_DROM
  port (
    P_CLK    : in  std_logic;
    P_RESET  : in  std_logic;
    P_AIN    : in  std_logic_vector(8 downto 0);
    P_DOUT   : out std_logic_vector(7 downto 0)
  );
end component;

-- micro code ROM
component TAC_MROM
  port (
    P_CLK    : in  std_logic;
    P_RESET  : in  std_logic;
    P_AIN    : in  std_logic_vector(7 downto 0);
    P_DOUT   : out std_logic_vector(31 downto 0)
  );
end component;

begin
  -- decode ROM
  I_DECAD <= I_OP & M_JA(0);
  drom1: TAC_DROM 
    port map (P_CLK=>P_CLK90, P_RESET=>P_RESET,
              P_AIN=>I_DECAD, P_DOUT=>I_DCODE);

  -- micro code ROM
  mrom1: TAC_MROM
    port map (P_CLK=>P_CLK0, P_RESET=>P_RESET,
              P_AIN=>I_MPC,  P_DOUT=>I_MCODE);

  -- micro code
  M_ALU <= I_MCODE(31 downto 28);
  M_RR  <= I_MCODE(27 downto 25);
  M_WR  <= I_MCODE(24 downto 22);
  M_FLG <= I_MCODE(21 downto 19);
  M_LA  <= I_MCODE(18);
  M_LO  <= I_MCODE(17);
  --M_NC  <= I_MCODE(16);
  M_BUS <= I_MCODE(15 downto 12);
  M_JP  <= I_MCODE(11 downto 8);
  M_JA  <= I_MCODE(7 downto 0);

  -- bus micro instruction decoder
  process(M_BUS)
  begin
    case M_BUS is               -- XDHLWMIVB
      when BUS_MEMR  => M_DBUS <= "010001000"; -- IX*LD HL LI RW*MR IR VR BT
      when BUS_MEMW  => M_DBUS <= "000011000"; -- IX LD HL LI*RW*MR IR VR BT
      when BUS_IOR   => M_DBUS <= "010000100"; -- IX*LD HL LI RW MR*IR VR BT
      when BUS_IOW   => M_DBUS <= "000010100"; -- IX LD HL LI*RW MR*IR VR BT
      when BUS_FETCH => M_DBUS <= "010101000"; -- IX*LD HL*LI RW*MR IR VR BT
      when BUS_VECT  => M_DBUS <= "010000010"; -- IX*LD HL LI RW MR IR*VR BT
      when BUS_IOF   => M_DBUS <= "000100100"; -- IX LD HL*LI RW MR*IR VR BT
      when BUS_LDRX  => M_DBUS <= "110000000"; --*IX*LD HL LI RW MR IR VR BT
      when BUS_HALT  => M_DBUS <= "001000000"; -- IX LD*HL LI RW MR IR VR BT
      when BUS_MEMRB => M_DBUS <= "010001001"; -- IX*LD HL LI RW*MR IR VR*BT
      when BUS_MEMWB => M_DBUS <= "000011001"; -- IX LD HL LI*RW*MR IR VR*BT
      when BUS_IORB  => M_DBUS <= "010000101"; -- IX*LD HL LI RW MR*IR VR*BT
      when BUS_IOWB  => M_DBUS <= "000010101"; -- IX LD HL LI*RW MR*IR VR*BT
      when others    => M_DBUS <= "000000000"; -- IX LD HL LI RW MR IR VR BT
    end case;
  end process;
  M_IX  <= M_DBUS(8);
  M_LD  <= M_DBUS(7);
  M_HL  <= M_DBUS(6);
  M_LI  <= M_DBUS(5);
  M_RW  <= M_DBUS(4);
  M_MR  <= M_DBUS(3);
  M_IR  <= M_DBUS(2);
  M_VR  <= M_DBUS(1);
  M_BT  <= M_DBUS(0);

  -- control bus
  P_LI     <= M_LI;
  P_RW     <= M_RW;
  P_MR     <= M_MR;
  P_IR     <= M_IR;
  P_VR     <= M_VR;
  P_HL     <= M_HL;
  P_BT     <= M_BT;
  P_PR     <= I_P;

  -- data bus
  P_DOUT(7 downto 0)  <= I_OPR( 7 downto 0);
  P_DOUT(15 downto 8) <= I_OPR(15 downto 8) when (M_BT='0')
                         else I_OPR(7 downto 0);

  -- MPC の制御
  process(I_RD, I_V, I_C, I_Z, I_S)     -- JMP_C 部分
  begin
    case I_RD is
      when "0000" => I_JMP <= I_Z;                        -- JZ
      when "0001" => I_JMP <= I_C;                        -- JC
      when "0010" => I_JMP <= I_S;                        -- JM
      when "0011" => I_JMP <= I_V;                        -- JO
      when "0100" => I_JMP <= not (I_Z or (I_S xor I_V)); -- JGT
      when "0101" => I_JMP <= not (I_S xor I_V);          -- JGE
      when "0110" => I_JMP <= I_Z or (I_S xor I_V);       -- JLE
      when "0111" => I_JMP <= I_S xor I_V;                -- JLT
      when "1000" => I_JMP <= not I_Z;                    -- JNZ
      when "1001" => I_JMP <= not I_C;                    -- JNC
      when "1010" => I_JMP <= not I_S;                    -- JNM
      when "1011" => I_JMP <= not I_V;                    -- JNO
      when "1100" => I_JMP <= not (I_Z or I_C);           -- JHI
      when "1101" => I_JMP <= '0';                        -- ERR
      when "1110" => I_JMP <= I_Z or I_C;                 -- JLS
      when others => I_JMP <= '1';                        -- JMP '1111'
    end case;
  end process;

  I_CTP1 <= I_CT + 1;
  process(P_CLK0, P_RESET)              -- CT 部分
  begin
    if (P_RESET='0') then
      I_CT <= "0000";
    elsif (P_CLK0' event and P_CLK0='1') then
      case M_JP is
        when JMP_CTDR =>
          if (I_CT=I_DR(3 downto 0)) then
            I_CT <= "0000";
          else
            I_CT <=I_CTP1;
          end if;
        when JMP_CT16 =>
          I_CT <= I_CTP1;
        when others   => NULL;                   -- no change
      end case;
    end if;
  end process;

  process(M_JP, I_RX, I_JMP, P_Intr, P_STOP, I_E,I_CT,I_P,I_Z, I_DR(3 downto 0))
  begin                                 -- JCC_C 部分
    case M_JP is
      when JMP_ALL  =>                                       -- JMP
        I_MPCLDAB <= "10";
      when JMP_OP   =>                                       -- JOP
        I_MPCLDAB <= "11";
      when JMP_INT  =>                                       -- Jcc(INT)
        I_MPCLDAB <= ((P_Intr and I_E) or P_STOP) & '0';
      when JMP_CTDR =>                                       -- Jcc(CTDR)
        if (I_CT=I_DR(3 downto 0))then                       --  if CT=DR(3:0)
          I_MPCLDAB <= "0X" ;                                --   no jump
        else                                                 --  else
          I_MPCLDAB <= "10";                                 --   jump
        end if;
      when JMP_NJ   =>                                       -- Jcc(NJ)
        I_MPCLDAB   <= (not I_JMP) & '0';                    --   Jmp==0
      when JMP_CT16 =>                                       -- Jcc(CT16)
        if (I_CT="1111") then                                --  if CT=15
          I_MPCLDAB <= "0X";                                 --   no jump
        else                                                 --  else
          I_MPCLDAB <= "10";                                 --   jump
        end if;
      when JMP_STP  =>                                       -- Jcc(STP)
        if (P_STOP='1') then
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
        end if;
      when JMP_DI   =>                                       -- Jcc(DI)
        if (I_RX="0000") then
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
	end if;
      when JMP_SPR  =>                                       -- Jcc(SPR) 
        if (I_RX="1101") then
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
        end if;
      when JMP_PCR  =>                                       -- Jcc(PCR)
        if(I_RX="1110") then
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
        end if;
      when JMP_IM   =>                                       -- Jcc(IM)
        if (I_RX="1111") then
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
        end if;
      when JMP_NPRV =>                                       -- Jcc(NPRV)
        if  (I_P='0') then		                     --   non Privilege
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
	end if;
      when JMP_ZERO =>                                       -- Jcc(ZERO)
        if  (I_Z='1') then
          I_MPCLDAB <= "10";
        else
          I_MPCLDAB <= "0X";
        end if;
      when others   =>                                       -- NO
        I_MPCLDAB <= "0X";
    end case;
  end process;

  process(P_CLK90, P_RESET)             -- MPC 部分
  begin
    if (P_RESET='0') then
      I_MPC <= "00000000";
    elsif (P_CLK90' event and P_CLK90='0') then
      case I_MPCLDAB is
        when "10"   => I_MPC <= M_JA;                -- JA("10")
        when "11"   => I_MPC <= I_DCODE;             -- Decode ROM DATA("11")
        when others => I_MPC <= I_MPC + 1;           -- ("00","01")
      end case;
    end if;
  end process;

  -- IR の制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      I_OP <= "00000000";
      I_RD <= "0000";
      I_RX <= "0000";
    elsif (P_CLK0' event and P_CLK0='1') then
      if (M_LI='1') then
        I_OP <= P_DIN(15 downto 8);
        I_RD <= P_DIN(7 downto 4);
        I_RX <= P_DIN(3 downto 0);
      end if;
    end if;
  end process;

  -- DR の制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      I_DR <= "0000000000000000";
    elsif (P_CLK0' event and P_CLK0='1') then
      if (M_LD='1') then
        if (M_IX='1') then
          I_DR <= I_RRX;
        elsif (M_LI='1') then                             --ショートイミデイト用
          if (P_DIN(3)='1') then
            I_DR <= "111111111111" & P_DIN(3 downto 0);
          else
            I_DR <= "000000000000" & P_DIN(3 downto 0);
          end if;
        elsif(M_BT='1') then --Byte access
          if (I_AR(0)='0') then
            I_DR <= "00000000" & P_DIN(15 downto 8);
          else
            I_DR <= "00000000" & P_DIN(7 downto 0);
          end if;
        else
          I_DR <= P_DIN;
        end if;
      end if;
    end if;
  end process;

  -- OPR の制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      I_OPR <= "0000000000000000";
    elsif (P_CLK0' event and P_CLK0='1') then
      if (M_LO='1') then
        I_OPR <= I_ALU;
      end if;
    end if;
  end process;

  -- AR の制御
  P_ADDR <= I_AR;
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      I_AR <= "0000000000000000";
    elsif (P_CLK0' event and P_CLK0='1') then
      if (M_LA='1') then
        I_AR <= I_ALU;
      end if;
    end if;
  end process;

  -- レジスタファイルの制御
  -- 書込みレジスタの決定
  process(M_WR, I_RD, I_RX)
  begin
    case M_WR is
      when REG_SP   => I_WRA <= "101101";
      when REG_PC   => I_WRA <= "101111";
      when REG_FLAG => I_WRA <= "110001";
      when REG_Rd   => I_WRA <= "10" & I_RD;
      when REG_RdP  => I_WRA <= "10" & I_RD(3 downto 1)  & '1';
      when REG_Rx   => I_WRA <= "10" & I_RX;
      when REG_TMP  => I_WRA <= "110000";
      when others   => I_WRA <= "0XXXXX";  -- REG_NO
    end case;
  end process;

  -- 書き込み制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      I_G0  <= "0000000000000000";
      I_G1  <= "0000000000000000";
      I_G2  <= "0000000000000000";
      I_G3  <= "0000000000000000";
      I_G4  <= "0000000000000000";
      I_G5  <= "0000000000000000";
      I_G6  <= "0000000000000000";
      I_G7  <= "0000000000000000";
      I_G8  <= "0000000000000000";
      I_G9  <= "0000000000000000";
      I_G10 <= "0000000000000000";
      I_G11 <= "0000000000000000";
      I_G12 <= "0000000000000000";
      I_SSP <= "0000000000000000";
      I_USP <= "0000000000000000";
      I_PC  <= "1111000000000000";
      I_TMP <= "0000000000000000";
    elsif (P_CLK0' event and P_CLK0='1') then
      case I_WRA is
        when "100000" => I_G0  <= I_ALU;
        when "100001" => I_G1  <= I_ALU;
        when "100010" => I_G2  <= I_ALU;
        when "100011" => I_G3  <= I_ALU;
        when "100100" => I_G4  <= I_ALU;
        when "100101" => I_G5  <= I_ALU;
        when "100110" => I_G6  <= I_ALU;
        when "100111" => I_G7  <= I_ALU;
        when "101000" => I_G8  <= I_ALU;
        when "101001" => I_G9  <= I_ALU;
        when "101010" => I_G10 <= I_ALU;
        when "101011" => I_G11 <= I_ALU;
        when "101100" => I_G12 <= I_ALU;
        when "101101" => if(I_P='1')then 
                           I_SSP  <= I_ALU;
                         else
                           I_USP  <= I_ALU;
                         end if;
        when "101110" => I_USP <= I_ALU;
        when "101111" => I_PC  <= I_ALU;
        when "110000" => I_TMP <= I_ALU;
          -- "110001" : FLAG の変化は下の process 文に集約
        when others => NULL;
      end case;
    end if;
  end process;

  -- FLAG の制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      I_E <= '0';
      I_P <= '1';                       -- 特権モードで始まる
      I_V <= '0';
      I_C <= '0';
      I_S <= '0';
      I_Z <= '0';
    elsif (P_CLK0' event and P_CLK0='1') then
      if (I_WRA="110001") then
        I_E <= I_ALU(7);
        I_P <= I_ALU(6);
        I_V <= I_ALU(3);
        I_C <= I_ALU(2);
        I_S <= I_ALU(1);
        I_Z <= I_ALU(0);
      else
        case M_FLG is
          when FLG_LF =>  I_V <= I_AV;
                          I_C <= I_AC;
                          I_S <= I_AS;
                          I_Z <= I_AZ;
          when FLG_STI => I_E <= '1';
          when FLG_CLI => I_E <= '0';
          when FLG_STP => I_P <= '1';
          when FLG_CLP => I_P <= '0';
          when others  => NULL; -- FLAG は変化しない
        end case;
      end if;
    end if;
  end process;

  -- 読みだしレジスタ番号
  process(M_RR, I_RD, I_RX)
  begin
    case M_RR is
      when REG_FP   => I_RRA <= "01100";
      when REG_SP   => I_RRA <= "01101";
      when REG_PC   => I_RRA <= "01111";
      when REG_FLAG => I_RRA <= "10001";
      when REG_Rd   => I_RRA <= '0' & I_RD;
      when REG_RdP  => I_RRA <= '0' & I_RD(3 downto 1)  & '1';
      when REG_RX   => I_RRA <= '0' & I_RX;
      when REG_TMP  => I_RRA <= "10000";
      when others   => I_RRA <= "XXXXX";
    end case;
  end process;

  -- 読みだし制御
  process(I_G0, I_G1, I_G2, I_G3, I_G4, I_G5, I_G6, I_G7, I_G8, I_G9, I_G10,
          I_G11, I_G12, I_SSP, I_USP, I_PC, I_TMP,
          I_E, I_P, I_V, I_C, I_S, I_Z, I_RRA)
  begin
    case I_RRA is
      when "00000" => I_RRD <= I_G0;
      when "00001" => I_RRD <= I_G1;
      when "00010" => I_RRD <= I_G2;
      when "00011" => I_RRD <= I_G3;
      when "00100" => I_RRD <= I_G4;
      when "00101" => I_RRD <= I_G5;
      when "00110" => I_RRD <= I_G6;
      when "00111" => I_RRD <= I_G7;
      when "01000" => I_RRD <= I_G8;
      when "01001" => I_RRD <= I_G9;
      when "01010" => I_RRD <= I_G10;
      when "01011" => I_RRD <= I_G11;
      when "01100" => I_RRD <= I_G12;
      when "01101" => if (I_P='1') then
                        I_RRD <= I_SSP;
                      else
                        I_RRD <=I_USP;
                      end if;
      when "01110" => I_RRD <= I_USP;
      when "01111" => I_RRD <= I_PC;
      when "10001" => I_RRD <= "00000000"&I_E&I_P&"00"&I_V&I_C&I_S&I_Z;
      when others  => I_RRD <= I_TMP;
    end case;
  end process;

  -- IX用の読みだし制御
  process(I_G0, I_G1, I_G2, I_G3, I_G4, I_G5, I_G6, I_G7, I_G8, I_G9, I_G10,
          I_G11, I_G12, I_SSP, I_USP, I_PC, I_E, I_P, I_V, I_C, I_S, I_Z, I_RX)
  begin
    case I_RX is
      when "0000" => I_RRX <= I_G0;
      when "0001" => I_RRX <= I_G1;
      when "0010" => I_RRX <= I_G2;
      when "0011" => I_RRX <= I_G3;
      when "0100" => I_RRX <= I_G4;
      when "0101" => I_RRX <= I_G5;
      when "0110" => I_RRX <= I_G6;
      when "0111" => I_RRX <= I_G7;
      when "1000" => I_RRX <= I_G8;
      when "1001" => I_RRX <= I_G9;
      when "1010" => I_RRX <= I_G10;
      when "1011" => I_RRX <= I_G11;
      when "1100" => I_RRX <= I_G12;
      when "1101" => if (I_P='1') then
                       I_RRX <= I_SSP;
                     else
                       I_RRX <=I_USP;
                     end if;
      when "1110" => I_RRX <= I_USP;
      when others => I_RRX <= I_PC;
    end case;
  end process;

  -- ALU の制御
  I_ALU <= I_ALUT(15 downto 0);
  process(I_RRD,I_DR,M_ALU,I_C,I_S,I_Z,I_RX,I_OP(4 downto 3))
  begin
    case M_ALU is
      when ALU_ZERO => I_ALUT <= "00000000000000000";                 -- ZERO
      when ALU_A    => I_ALUT <= ('0' & I_RRD);                       -- A
      when ALU_B    => I_ALUT <= ('0' & I_DR);                        -- B
      when ALU_ADD  => I_ALUT <= ('0' & I_RRD) + I_DR;                -- ADD
      when ALU_SUB  => I_ALUT <= ('0' & I_RRD) - I_DR;                -- SUB
      when ALU_AND  => I_ALUT <=  '0' & (I_RRD and I_DR);             -- AND
      when ALU_OR   => I_ALUT <=  '0' & (I_RRD or  I_DR);             -- OR
      when ALU_XOR  => I_ALUT <=  '0' & (I_RRD xor I_DR);             -- XOR
      when ALU_INC2 => I_ALUT <= ('0' & I_RRD) + 2;                   -- INC2
      when ALU_DEC2 => I_ALUT <= ('0' & I_RRD) - 2;                   -- DEC2
      when ALU_RROT => I_ALUT <= I_RRD(0) & I_C & I_RRD(15 downto 1); -- RROT
      when ALU_LROT => I_ALUT <= I_RRD(15 downto 0) & I_C;            -- LROT
      when ALU_XADD =>                                                -- XADD
        if (I_C='1') then
          I_ALUT <= ('0' & I_RRD) + I_DR;
        else
          I_ALUT <=('0' & I_RRD);
        end if;
      when ALU_XSUB =>                                                -- XSUB
        if (I_C='0')then
          I_ALUT <= '1' & (I_RRD - I_DR);
        else
          I_ALUT <=('0' & I_RRD);
        end if;
      when ALU_SFT  =>                                                -- SHIFT
        case I_OP(4 downto 3) is
          when "10" =>                                                --  SHRA
            I_ALUT <= I_RRD(0) & I_RRD(15) & I_RRD(15 downto 1);
          when "11" =>                                                --  SHRL
            I_ALUT <= I_RRD(0) & '0' & I_RRD(15 downto 1);
          when others =>                                              --  SHL*
            I_ALUT <= I_RRD & '0';
        end case;
      when others   => I_ALUT <= (I_C & I_RRD) - I_DR;                -- SUBC
    end case;
  end process;

  -- ALU のフラグ出力
  I_AS <= I_ALUT(15);
  I_AC <= I_ALUT(16);
  I_AZ <= '1' when (I_ALU(15 downto 0)="0000000000000000") else '0';
  -- Vフラグの決定
  process(M_ALU, I_RRD(15), I_DR(15), I_ALUT(15), I_OP, I_V)
  begin
    case M_ALU is
      when ALU_ADD  =>
        I_AV <= not(I_RRD(15) xor I_DR(15)) and (I_ALUT(15) xor I_RRD(15));
      when ALU_SUB | ALU_SUBC =>
        I_AV <= (I_RRD(15) xor I_DR(15)) and (I_ALUT(15) xor I_RRD(15));
      when ALU_INC2 => I_AV <= (I_ALUT(15) and not I_RRD(15));
      when ALU_DEC2 => I_AV <= (not I_ALUT(15) and I_RRD(15));
      when ALU_SFT  =>
        if (I_OP(3)='1') then
          I_AV <= '0';                                   -- Logical
        else             
          I_AV <=(I_RRD(15) xor I_ALUT(15)) or I_V;      -- Arithmetic
        end if;
      when others   => I_AV <= '0';
    end case;
  end process;

end RTL;
