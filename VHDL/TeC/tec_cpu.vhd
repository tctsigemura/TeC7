--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2024 by
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
-- TeC CPU VHDL Source Code
--
-- 2024.11.19 : 新バージョン
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity TEC_CPU is
  Port ( P_CLK     : in std_logic;                      -- Clock
         -- Control
         P_RESET   : in std_logic;                      -- Reset
         P_INTR    : in std_logic;                      -- Interrupt
         P_STOP    : in std_logic;                      -- Stop
         P_HL      : out std_logic;                     -- Halt Request
         P_ER      : out std_logic;                     -- Decode Error
         P_IR      : out std_logic;                     -- I/O Request
         P_MR      : out std_logic;                     -- Memory Request
         P_LI      : out std_logic;                     -- Instruction Fetch

         -- RAM
         P_ADDR    : out std_logic_vector (7 downto 0);  -- Addr Bus
         P_DIN     : in std_logic_vector (7 downto 0);   -- Data Bus
         P_DOUT    : out std_logic_vector (7 downto 0);  -- Data Bus
         P_RW      : out std_logic;

         -- Console
         P_SEL     : in std_logic_vector (2 downto 0);   -- Console Rotary Sw
         P_PND     : in std_logic_vector (7 downto 0);   -- Console Data
         DbgDout   : out std_logic_vector (7 downto 0);  -- Register Data
         P_WRITE   : in std_logic;                       -- Console Write
         P_C       : out std_logic;                      -- C
         P_S       : out std_logic;                      -- S
         P_Z       : out std_logic;                      -- Z

         P_G0D   : out std_logic_vector(7 downto 0);     -- G0 out
         P_G1D   : out std_logic_vector(7 downto 0);     -- G1 out
         P_G2D   : out std_logic_vector(7 downto 0);     -- G2 out
         P_SPD   : out std_logic_vector(7 downto 0);     -- SP out
         P_PCD   : out std_logic_vector(7 downto 0);     -- PC out
         P_FLD   : out std_logic_vector(7 downto 0);     -- FLAG out

         P_MODE  : in std_logic                         -- DEMO MODE
       );
end TEC_CPU;

architecture Behavioral of TEC_CPU is
  component TEC_CPU_SEQUENCER is
    Port ( Clk   : in std_logic;

           -- 入力
           Reset : in std_logic;
           OP    : in std_logic_vector (3 downto 0);
           Rd    : in std_logic_vector (1 downto 0);
           Rx    : in std_logic_vector (1 downto 0);
           FlagE : in std_logic;   -- E
           FlagC : in std_logic;   -- C
           FlagS : in std_logic;   -- S
           FlagZ : in std_logic;   -- Z
           Intr  : in std_logic;
           Stop  : in std_logic;

           -- CPU内部の制御用に出力
           IrLd  : out std_logic;
           DrLd  : out std_logic;
           FlgLdA: out std_logic;
           FlgLdM: out std_logic;
           FlgOn : out std_logic;
           FlgOff: out std_logic;
           GrLd  : out std_logic;
           SpM1  : out std_logic;
           SpP1  : out std_logic;
           PcP1  : out std_logic;
           PcJmp : out std_logic;
           PcRet : out std_logic;
           Ma    : out std_logic_vector (1 downto 0);
           Md    : out std_logic_vector (1 downto 0);

           -- CPU外部へ出力
           Ir    : out std_logic;
           Mr    : out std_logic;
           Err   : out std_logic;
           We    : out std_logic;
           Halt  : out std_logic
         );
  end component;

  -- CPU Register
  signal G0    : std_logic_vector(7 downto 0);
  signal G1    : std_logic_vector(7 downto 0);
  signal G2    : std_logic_vector(7 downto 0);
  signal SP    : std_logic_vector(7 downto 0);

  -- PSW
  signal PC   : std_logic_vector(7 downto 0);
  signal FlgE : std_logic;            -- E
  signal FlgC : std_logic;            -- C
  signal FlgS : std_logic;            -- S
  signal FlgZ : std_logic;            -- Z

  -- IR
  signal OP    : std_logic_vector(3 downto 0);
  signal Rd    : std_logic_vector(1 downto 0);
  signal Rx    : std_logic_vector(1 downto 0);

  -- DR
  signal DR    : std_logic_vector(7 downto 0);

  -- 内部バス
  signal Ea    : std_logic_vector(7 downto 0); -- Effective Address
  signal RegRd : std_logic_vector(7 downto 0); -- Reg[Rd]
  signal RegRx : std_logic_vector(7 downto 0); -- Reg[Rx]
  signal Alu   : std_logic_vector(8 downto 0); -- ALU出力（キャリー付)
  signal Zero  : std_logic;                    -- ALUが0か？
  signal SftRd : std_logic_vector(8 downto 0); -- Reg[Rd]をシフトしたもの

  -- 内部制御線（ステートマシンの出力)
  signal IrLd  : std_logic;                    -- IR:Ld
  signal DrLd  : std_logic;                    -- DR:Ld
  signal FlgLdA: std_logic;                    -- Flag:LdA
  signal FlgLdM: std_logic;                    -- Flag:LdM
  signal FlgOn : std_logic;                    -- Flag:On
  signal FlgOff: std_logic;                    -- Flag:Off
  signal GrLd  : std_logic;                    -- GR:Ld
  signal SpM1  : std_logic;                    -- SP:M1
  signal SpP1  : std_logic;                    -- SP:P1
  signal PcP1  : std_logic;                    -- PC:P1
  signal PcJmp : std_logic;                    -- PC:JMP
  signal PcRet : std_logic;                    -- PC:RET

  -- マルチプレクッサの制御
  signal Ma    : std_logic_vector(1 downto 0); -- MA(PC=00,Ea=01,SP=10)
  signal Md    : std_logic_vector(1 downto 0); -- MD(PC=0,FLAG=,GR=1)

  begin
    -- コンソールへの接続
    P_C 　<= FlgC;
    P_S 　<= FlgS;
    P_Z 　<= FlgZ;
    P_LI　<= IrLd;
    P_G0D <= G0;
    P_G1D <= G1;
    P_G2D <= G2;
    P_SPD <= SP;
    P_PCD <= PC;
    P_FLD <= FlgE & "0000" & FlgC & FlgS & FlgZ;

    -- 制御部
    seq1: TEC_CPU_SEQUENCER
    port map (P_CLK, P_RESET, OP, Rd, Rx, FlgE, FlgC, FlgS, FlgZ,
              P_INTR, P_STOP, IrLd, DrLd, FlgLdA, FlgLdM, FlgOn,
              FlgOff, GrLd, SpM1, SpP1, PcP1, PcJmp, PcRet,
              Ma, Md, P_IR, P_MR, P_ER, P_RW, P_HL);

    -- Address Bus へ出力
    P_ADDR <= PC when Ma="00" else               -- PC
              Ea when Ma="01" else               -- Effective Address
              SP-1 when Ma="10" else             -- SP-1
              SP;                                -- SP

    -- Data Bus へ出力
    P_DOUT <= PC when Md="00" else
            (FlgE & "0000" & FlgC & FlgS & FlgZ) when Md="01" else
            RegRd;

    -- ALU
    SftRd <= (RegRd & '0') when Rx(1)='0' else                     -- SHLA/SHLL
          (RegRd(0) & RegRd(7) & RegRd(7 downto 1)) when Rx(0)='0' else -- SHRA
          (RegRd(0) & '0' & RegRd(7 downto 1));                      -- SHRL

    Alu <= ('0' & RegRd) + ('0' & DR) when OP="0011" else            -- Add
           ('0' & RegRd) - ('0' & DR) when OP(3 downto 1)="010" else --Sub/Cmp
           ('0' & RegRd)and('0' & DR) when OP="0110" else            -- And
           ('0' & RegRd)or ('0' & DR) when OP="0111" else            -- Or
           ('0' & RegRd)xor('0' & DR) when OP="1000" else            -- Xor
           SftRd when OP="1001" else                                 -- Shift
           ('0' & DR);                                               -- DR

    Zero <= '1' when ALU(7 downto 0)="00000000" else '0';

    -- IR の制御
    process(P_CLK)
    begin
      if (P_CLK'event and P_CLK='1') then
        if (IrLd='1') then
          OP <=P_DIN(7 downto 4);
          Rd <=P_DIN(3 downto 2);
          Rx <=P_DIN(1 downto 0);
        end if;
      end if;
    end process;

    -- DR の制御
    process(P_CLK)
    begin
      if (P_CLK'event and P_CLK='1') then
        if (DrLd='1') then
          DR <=P_DIN;
        end if;
      end if;
    end process;

    -- PC の制御
    process(P_CLK,P_RESET)
    begin
      if (P_RESET='0') then
        PC <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (PcJmp='1') then
          PC <= Ea;
        elsif (PcRet='1') then
          PC <=P_DIN;
        elsif (PcP1='1') then
          PC <= PC + 1;
        elsif (P_WRITE='1' and P_SEL="100") then   -- Console からの書き込み
          PC <= P_PND;
        end if;
      end if;
    end process;

    -- CPU レジスタの読み出し
    RegRd <= G0 when Rd="00" else G1 when Rd="01" else
             G2 when Rd="10" else SP;

    -- Effective Address の計算
    RegRx <= G1 when Rx="01" else G2 when Rx="10" else "00000000";
    Ea <= DR + RegRx;

    -- CPU レジスタの制御
    process(P_CLK,P_RESET)
    begin
      if (P_RESET='0') then
        G0  <= "00000000";
        G1  <= "00000000";
        G2  <= "00000000";
        SP  <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (GrLd='1') then
          case Rd is
            when "00"   => G0 <= Alu(7 downto 0);
            when "01"   => G1 <= Alu(7 downto 0);
            when "10"   => G2 <= Alu(7 downto 0);
            when others => SP <= Alu(7 downto 0);
          end case;
        elsif (SpP1='1') then
          SP <= SP + 1;
        elsif (SpM1='1') then
          SP <= Sp - 1;
        elsif (P_WRITE='1') then                    -- Console からの書き込み
          case P_SEL is
            when "000" => G0 <= P_PND;
            when "001" => G1 <= P_PND;
            when "010" => G2 <= P_PND;
            when "011" => SP <= P_PND;
            when others => null;
          end case;
        end if;
      end if;
    end process;

    -- フラグの制御
    process(P_CLK,P_RESET)
    begin
      if (P_RESET='0') then
        FlgE <= '0';
        FlgC <= '0';
        FlgS <= '0';
        FlgZ <= '0';
      elsif (P_CLK'event and P_CLK='1') then
        if (FlgLdA='1') then             -- 計算結果
          FlgC <= Alu(8);                --  Carry
          FlgS <= Alu(7);                --  Sign
          FlgZ <= Zero;                  --  Zero
        elsif (FlgLdM='1') then          -- RETI
          FlgE <=P_DIN(7);               --  Enable
          FlgC <=P_DIN(2);               --  Carry
          FlgS <=P_DIN(1);               --  Sign
          FlgZ <=P_DIN(0);               --  Zero
        elsif (FlgOn='1') then           -- EI
          FlgE <= '1';                   --  Enable
        elsif (FlgOff='1') then          -- DI
          FlgE <= '0';                   --  Disable
        elsif (P_WRITE='1') then         -- Console からの書き込み
          if (P_SEL="110") then          --  Flag
            FlgE <= P_PND(7);            --   Enable
            FlgC <= P_PND(2);            --   Carry
            FlgS <= P_PND(1);            --   Sign
            FlgZ <= P_PND(0);            --   Zero
          end if;
        end if;
      end if;
    end process;

    -- コンソール接続
    DbgDout <= G0 when P_SEL="000" else
               G1 when P_SEL="001" else
               G2 when P_SEL="010" else
               SP when P_SEL="011" else
               PC when P_SEL="100" else
               (FlgE & "0000" & FlgC & FlgS & FlgZ);

end Behavioral;
