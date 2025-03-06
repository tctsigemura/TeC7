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
-- TeC CPU VHDL Source Code
--
-- TEC_CPU_SEQUENCER.vhd
--
-- 2024.11.19 : 新バージョン
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity TEC_CPU_SEQUENCER is
  Port ( Clk   : in  STD_LOGIC;
         -- 入力
         Reset : in  STD_LOGIC;
         OP    : in  STD_LOGIC_VECTOR (3 downto 0);
         Rd    : in  STD_LOGIC_VECTOR (1 downto 0);
         Rx    : in  STD_LOGIC_VECTOR (1 downto 0);
         FlagE : in  STD_LOGIC;
         FlagC : in  STD_LOGIC;
         FlagS : in  STD_LOGIC;
         FlagZ : in  STD_LOGIC;
         Intr  : in  STD_LOGIC;
         Stop  : in  STD_LOGIC;

         -- CPU内部の制御用に出力
         IrLd  : out  STD_LOGIC;
         DrLd  : out  STD_LOGIC;
         FlgLdA: out  STD_LOGIC;
         FlgLdM: out  STD_LOGIC;
         FlgOn : out  STD_LOGIC;
         FlgOff: out  STD_LOGIC;
         GrLd  : out  STD_LOGIC;
         SpM1  : out  STD_LOGIC;
         SpP1  : out  STD_LOGIC;
         PcP1  : out  STD_LOGIC;
         PcJmp : out  STD_LOGIC;
         PcRet : out  STD_LOGIC;
         Ma    : out  STD_LOGIC_VECTOR (1 downto 0);
         Md    : out  STD_LOGIC_VECTOR (1 downto 0);

         -- CPU外部へ出力
         Ir    : out  STD_LOGIC;
         Mr    : out  STD_LOGIC;
         Err   : out  STD_LOGIC;
         We    : out  STD_LOGIC;
         Halt  : out  STD_LOGIC
       );
end TEC_CPU_SEQUENCER;

architecture Behavioral of TEC_CPU_SEQUENCER is

  -- デコードROM
  subtype stat is std_logic_vector(25 downto 0);
  signal DAddr : std_logic_vector(7 downto 0);
  signal Dcode : Stat;

  component TEC_DROM
    port ( P_CLK   : in  std_logic;
           P_RESET : in  std_logic;
           P_ADDR  : in  std_logic_vector(7 downto 0);
           P_DOUT  : out std_logic_vector(25 downto 0)
         );
  end component;

  -- 各状態を表す定数
  constant STAT00 : Stat := "00000000000000000000000001";
  constant STAT01 : Stat := "00000000000000000000000010";
  constant STAT02 : Stat := "00000000000000000000000100";
  constant STAT03 : Stat := "00000000000000000000001000";
  constant STAT04 : Stat := "00000000000000000000010000";
  constant STAT05 : Stat := "00000000000000000000100000";
  constant STAT06 : Stat := "00000000000000000001000000";
  constant STAT07 : Stat := "00000000000000000010000000";
  constant STAT08 : Stat := "00000000000000000100000000";
  constant STAT09 : Stat := "00000000000000001000000000";
  constant STAT10 : Stat := "00000000000000010000000000";
  constant STAT11 : Stat := "00000000000000100000000000";
  constant STAT12 : Stat := "00000000000001000000000000";
  constant STAT13 : Stat := "00000000000010000000000000";
  constant STAT14 : Stat := "00000000000100000000000000";
  constant STAT15 : Stat := "00000000001000000000000000";
  constant STAT16 : Stat := "00000000010000000000000000";
  constant STAT17 : Stat := "00000000100000000000000000";
  constant STAT18 : Stat := "00000001000000000000000000";
  constant STAT19 : Stat := "00000010000000000000000000";
  constant STAT20 : Stat := "00000100000000000000000000";
  constant STAT21 : Stat := "00001000000000000000000000";
  constant STAT22 : Stat := "00010000000000000000000000";
  constant STAT23 : Stat := "00100000000000000000000000";
  constant STAT24 : Stat := "01000000000000000000000000";
  constant STAT25 : Stat := "10000000000000000000000000";

  signal State : Stat; -- State
  signal NxtSt : Stat; -- Next State

  -- 現在の命令の特徴など
  signal Jmp   : STD_LOGIC;                     -- JMP
  signal Jz    : STD_LOGIC;                     -- JZ
  signal Jc    : STD_LOGIC;                     -- JC
  signal Jm    : STD_LOGIC;                     -- JM
  signal Jnz   : STD_LOGIC;                     -- JNZ
  signal Jnc   : STD_LOGIC;                     -- JNC
  signal Jnm   : STD_LOGIC;                     -- JNM
  signal JmpCnd: STD_LOGIC;                     -- Jmp Condition
  signal Immd  : STD_LOGIC;                     -- Immediate mode
  signal Cmp   : STD_LOGIC;                     -- CMP
  signal Ld    : STD_LOGIC;                     -- LD

  begin
    -- 命令でコードはROMを用いる
    DAddr <= OP & Rd & Rx;

    drom0: TEC_DROM
      port map( P_CLK   => Clk,
                P_RESET => Reset,
                P_ADDR  => DAddr,
                P_DOUT  => Dcode);

    -- State machine
    NxtSt <=  Dcode  when State(1)='1' else                 -- Inst. Decode
              STAT00 when (State(0)='1' and Stop='1') or    -- Stop
                          State(3)='1' or State(4)='1' or   -- LD/.../SHxx,ST
                          State(5)='1' or State(7)='1' or   -- JMP,IN
                          State(8)='1' or State(10)='1' or  -- OUT,CALL
                          State(11)='1' or State(12)='1' or -- EI, DI
                          State(13)='1' or State(15)='1' or -- PUSH, POP
                          State(16)='1' or State(18)='1' or -- RET, RETI
                          State(19)='1' or State(20)='1' or -- HALT, ERROR
                          State(25)='1' else                -- Intr
              STAT21 when State(0)='1' and
                           Intr='1' and FlagE='1' else      -- Intr
              STAT22 when State(21)='1' else                -- Intr
              STAT23 when State(22)='1' else                -- Intr
              STAT24 when State(23)='1' else                -- Intr
              STAT25 when State(24)='1' else                -- Intr
              STAT01 when State(0)='1'  else                -- Fetch
              STAT03 when State(2)='1'  else                -- LD/ADD/.../XOR
              STAT07 when State(6)='1'  else                -- IN
              STAT10 when State(9)='1'  else                -- CALL
              STAT13 when State(12)='1' else                -- PUSH
              STAT15 when State(14)='1' else                -- POP
              STAT18 when State(17)='1' else                -- RETI
              STAT20;                                       -- Error

    process(Clk, Reset)
    begin
      if (Reset='0') then
        State <= STAT00;
      elsif (Clk'event and Clk='1') then
        State <= NxtSt;
      end if;
    end process;

    -- 命令の種類
    Jmp  <= '1' when Rd="00" else '0';                -- JMP
    Jz   <= '1' when OP(0)='0' and Rd="01" else '0';  -- JZ
    Jc   <= '1' when OP(0)='0' and Rd="10" else '0';  -- JC
    Jm   <= '1' when OP(0)='0' and Rd="11" else '0';  -- JM
    Jnz  <= '1' when OP(0)='1' and Rd="01" else '0';  -- JNZ
    Jnc  <= '1' when OP(0)='1' and Rd="10" else '0';  -- JNC
    Jnm  <= '1' when OP(0)='1' and Rd="11" else '0';  -- JNM
    Immd <= '1' when Rx="11" else '0';  -- Immediate mode

    -- ジャンプ条件
    JmpCnd <= Jmp or (Jz and FlagZ) or (Jc and FlagC) or (Jm and FlagS) or
             (Jnz and not FlagZ) or (Jnc and not FlagC) or (Jnm and not FlagS);

    -- CPU内のレジスタやマルチプレクサの制御信号
    IrLd  <= State(0) or State(24);                            -- Stop, Intr
    DrLd  <= State(1) or                                       -- Fetch
             (State(2) and not Immd) or                        -- LD/ADD/.../XOR
             State(6) or State(14);                            -- IN, POP
    FlgLdA <= '1' when State(3)='1' and OP/="0001" else '0';   -- OP /=LD
    FlgLdM <= State(17);                                       -- RETI
    FlgOn  <= State(11);                                       -- EI
    FlgOff <= State(12) or State(24);                          -- DI, Intr
    GrLd  <= '1' when (State(3)='1' and OP/="0101") or         -- OP /=CMP
                      State(7)='1' or                          -- IN
                      State(15)='1' else '0';                  -- POP
    SpP1  <= State(14) or State(16) or State(17) or State(18); -- POP, RET, RETI
    SpM1  <= State(9)  or State(13) or                         -- CALL, PUSH
             State(21) or State(22);                           -- Intr
    PcP1  <= (State(0) and not Stop and 
             (not Intr or not FlagE)) or                       -- Stop
             State(2) or                                       -- LD/ADD/.../XOR
             State(4) or (State(5) and not JmpCnd) or          -- ST, JMP
             State(6) or State(8) or State(9);                 -- IN, OUT, CALL
    PcJmp <= (State(5) and JmpCnd) or State(10);               -- JMP, CALL
    PcRet <= State(16) or State(18) or                         -- RET, RETI
             State(24) or State(25);                           -- Intr
    Ma    <= "00" when State(0)='1' or State(1)='1' or         -- "00"=PC
                       State(25)='1' else                      -- Fetch, Intr
             "01" when State(2)='1' or State(4)='1' or         -- "01"=EA, LD..
                       State(6)='1' or State(8)='1' else       -- ST, OUT, IN
             "10" when State(13)='1' else                      -- "10"=SP-1,PUSH
             "11";                                             -- "11"=SP
    Md    <= "00" when State(10)='1' or State(22)='1' else     -- "00"=PC
             "01" when State(23)='1' else                      -- "01"=FLAG
             "10";                                             -- "10"=GR
    We    <= State(4)  or State(8) or                          -- ST, OUT
             State(10) or State(13) or                         -- CALL, PUSH
             State(22) or State(23);                           -- Intr
    Mr    <= (State(0) and not Stop) or State(1) or            -- Fetch
             State(2)  or State(4) or                          -- LD/..., ST
             State(10) or State(13) or                         -- CALL, PUSH
             State(14) or State(16) or                         -- POP, RET
             State(17) or State(18) or                         -- RETI
             State(22) or State(23) or State(25);              -- Intr
    Ir    <= State(6)  or State(8) or State(24) or State(25);  -- OUT, IN, Intr
    Halt  <= State(19) or State(20);                           -- HALT, ERROR
    Err   <= State(20);                                        -- ERROR

end Behavioral;
