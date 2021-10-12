--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2021 by
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
-- 2019.08.29           : IPL-ROMを8KiBにしたのでPCの初期値をE000hに変更
-- 2019.01.29           : MPCの変化タイミングを5ns早く(MROMが間に合わないので）
-- 2019.01.17           : I/O特権モード（隅田の成果）を取り込む
-- 2016.01.08           : "DR の制御" 部分 warning 対応
-- 2012.09.27           : TaC-CPU V2 対応完了
-- 2012.01.22           : entity 名、見直し
-- 2011.07.18           : レジスタ G12 を TMP に置き換える
-- 2011.07.18           : レジスタ指定 RxP を TMP に置き換える
-- 2011.06.10           : TeC7 用に書き換える
-- 2010.07.23           : インデントの調整
-- 2010.07.20           : Subversion による管理を開始
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;

entity TAC_CPU is
  port ( P_CLK0     : in  std_logic;                        -- Clock
         P_CLK90    : in  std_logic;
         P_RESET    : in  std_logic;                        -- Reset

         P_ADDR     : out std_logic_vector(15 downto 0);    -- ADDRESS BUS
         P_DIN      : in  std_logic_vector(15 downto 0);    -- DATA    BUS
         P_DOUT     : out std_logic_vector(15 downto 0);    -- DATA    BUS

         P_RW       : out std_logic;                        -- Read/Write
         P_IR       : out std_logic;                        -- I/O Req.
         P_MR       : out std_logic;                        -- Memory Req.
         P_LI       : out std_logic;                        -- Instruction Fetch
         P_VR       : out std_logic;                        -- Vector Fetch
         P_HL       : out std_logic;                        -- Halt Instruction
         P_BT       : out std_logic;                        -- Byte to
         P_PR       : out std_logic;                        -- privilege Mode
         P_IOPR     : out std_logic;                        -- IO privilege Mode
         P_SVC      : out std_logic;                        -- Super Visor Call
         P_ZDIV     : out std_logic;                        -- Zero Division
         P_PRIVIO   : out std_logic;                        -- Privilege Vio.
         P_INVINST  : out std_logic;                        -- 
         P_INTR     : in  std_logic;                        -- Intrrupt
         P_STOP     : in  std_logic;                        -- Panel RUN F/F
         P_ADR_INT  : in std_logic;                        -- Address Violation
         P_VIO_INT  : in std_logic;                        -- Memory Violation
         P_TLBMISS  : in std_logic                        -- TLB miss
        );
end TAC_CPU;


architecture RTL of TAC_CPU is
  
subtype Word is std_logic_vector(15 downto 0);

component TAC_CPU_ALU is
  port (  P_CLK       : in std_logic;
          P_RESET     : in std_logic;
          P_START     : in std_logic;
          P_OP1       : in std_logic_vector(4 downto 0);
          P_A         : in std_logic_vector(15 downto 0);
          P_B         : in std_logic_vector(15 downto 0);
          P_BUSY      : out std_logic;
          P_ZDIV      : out std_logic;
          P_OUT       : out std_logic_vector(15 downto 0);
          P_OVERFLOW  : out std_logic;
          P_CARRY     : out std_logic;
          P_ZERO      : out std_logic;
          P_SIGN      : out std_logic
          );
end component;

component TAC_CPU_SEQUENCER is
  port (
  P_CLK         : in std_logic;
  P_RESET       : in std_logic;
  P_STOP        : in std_logic;
  P_INTR        : in std_logic;
  P_OP1         : in std_logic_vector(4 downto 0);
  P_OP2         : in std_logic_vector(2 downto 0);
  P_RD          : in std_logic_vector(3 downto 0);
  P_UPDATE_PC   : out std_logic_vector(2 downto 0);  -- PC の更新
  P_UPDATE_SP   : out std_logic_vector(1 downto 0);  -- SP の更新
  P_LOAD_IR     : out std_logic;                     -- IR のロード
  P_LOAD_DR     : out std_logic;                     -- DR のロード
  P_LOAD_FLAG   : out std_logic;                     -- FLAG のロード
  P_LOAD_TMP    : out std_logic;                     -- TMP のロード
  P_LOAD_GR     : out std_logic;                     -- 汎用レジスタのロード
  P_SELECT_A    : out std_logic_vector(2 downto 0);  -- アドレス出力の選択
  P_SELECT_D    : out std_logic_vector(2 downto 0);  -- データ出力の選択
  P_SELECT_W    : out std_logic_vector(1 downto 0);  -- DR への入力の選択
  P_SELECT_B    : out std_logic;                     -- ALU B への入力の選択
  P_ALU_START   : out std_logic;
  P_BUSY        : in std_logic;
  P_FLAG_V      : in std_logic;
  P_FLAG_C      : in std_logic;
  P_FLAG_Z      : in std_logic;
  P_FLAG_S      : in std_logic;
  P_TLBMISS     : in std_logic;                      -- MMU Interrupt
  P_MR          : out std_logic;                     -- Memory Request
  P_IR          : out std_logic;                     -- I/O Request
  P_RW          : out std_logic;                     -- Read/Write
  P_SVC         : out std_logic                      -- Super Visor Call
  );
end component;

-- レジスタファイル
type RegGR is array(0 to 11) of Word;
signal I_REG_GR  : RegGR; -- G0-G11
signal I_REG_FP  : Word;  -- FP (G12)
signal I_REG_SSP : Word;  -- SSP
signal I_REG_USP : Word;  -- USP

signal I_REG_PC  : Word;  -- PC

-- フラグ
signal I_FLAG: Word;              -- FLAG
signal I_FLAG_E   : std_logic;    -- Interrupt Enable
signal I_FLAG_P   : std_logic;    -- Privilege
signal I_FLAG_I   : std_logic;    -- IO Privilege
signal I_FLAG_V   : std_logic;    -- Over Flow
signal I_FLAG_C   : std_logic;    -- Carry
signal I_FLAG_S   : std_logic;    -- Sign
signal I_FLAG_Z   : std_logic;    -- Zero

-- 内部レジスタ
signal I_REG_DR  : Word;                              -- DR
signal I_REG_TMP : Word;                              -- TMP
signal I_INST_OP1    : std_logic_vector(4 downto 0);  -- 命令の OP1
signal I_INST_OP2    : std_logic_vector(2 downto 0);  -- 命令の OP2
signal I_INST_RD     : std_logic_vector(3 downto 0);  -- 命令の Rd
signal I_INST_RX     : std_logic_vector(3 downto 0);  -- 命令の Rx

-- 内部配線
signal I_ADDR        : Word;                          -- アドレス出力
signal I_DOUT        : Word;                          -- データ出力
signal I_EA          : Word;                          -- 実効アドレス
signal I_SP          : Word;                          -- スタックポインタ (カーネルモードとユーザーモードで切り替える)
signal I_RD          : Word;                          -- GR[Rd]
signal I_RX          : Word;                          -- GR[Rx]
signal I_DR_IN       : Word;                          -- DR への入力
signal I_UPDATE_PC   : std_logic_vector(2 downto 0);  -- PC の更新
signal I_UPDATE_SP   : std_logic_vector(1 downto 0);  -- SP の更新
signal I_LOAD_IR     : std_logic;                     -- IR のロード
signal I_LOAD_DR     : std_logic;                     -- DR のロード
signal I_LOAD_FLAG   : std_logic;                     -- FLAG のロード
signal I_LOAD_TMP    : std_logic;                     -- TMP のロード
signal I_LOAD_GR     : std_logic;                     -- 汎用レジスタのロード
signal I_SELECT_A    : std_logic_vector(2 downto 0);  -- MUX A の選択
signal I_SELECT_D    : std_logic_vector(2 downto 0);  -- MUX D の選択
signal I_SELECT_W    : std_logic_vector(1 downto 0);  -- MUX W の選択
signal I_SELECT_B    : std_logic;                     -- MUX B の選択
signal I_BUSY        : std_logic;                     -- ALU と MMU の BUSY 信号
signal I_ALU_B       : Word;                          -- ALU への B 信号
signal I_ALU_START   : std_logic;                     -- ALU への START 信号
signal I_ALU_BUSY    : std_logic;                     -- ALU からの BUSY 信号
signal I_ALU_OUT     : Word;                          -- ALU の出力
signal I_ALU_OVERFLOW: std_logic;                     -- ALU の Over flow 出力
signal I_ALU_CARRY   : std_logic;                     -- ALU の Carry 出力
signal I_ALU_ZERO    : std_logic;                     -- ALU の Zero  出力
signal I_ALU_SIGN    : std_logic;                     -- ALU の Sign  出力
signal I_TLBMISS     : std_logic;                     -- MMU の割込み
signal I_PRIVIO      : std_logic;                     -- 特権違反

begin
  
  ALU : TAC_CPU_ALU
  port map (
    P_CLK       => P_CLK0,
    P_RESET     => P_RESET,
    P_START     => I_ALU_START,
    P_OP1       => I_INST_OP1,
    P_A         => I_RD,
    P_B         => I_ALU_B,
    P_BUSY      => I_ALU_BUSY,
    P_ZDIV      => P_ZDIV,
    P_OUT       => I_ALU_OUT,
    P_OVERFLOW  => I_ALU_OVERFLOW,
    P_CARRY     => I_ALU_CARRY,
    P_ZERO      => I_ALU_ZERO,
    P_SIGN      => I_ALU_SIGN
  );

  SEQUENCER : TAC_CPU_SEQUENCER
  port map (
    P_CLK       => P_CLK0,
    P_RESET     => P_RESET,
    P_STOP      => P_STOP,
    P_INTR      => P_INTR,
    P_OP1       => I_INST_OP1,
    P_OP2       => I_INST_OP2,
    P_RD        => I_INST_RD,
    P_UPDATE_PC => I_UPDATE_PC,
    P_UPDATE_SP => I_UPDATE_SP,
    P_LOAD_IR   => I_LOAD_IR,
    P_LOAD_DR   => I_LOAD_DR,
    P_LOAD_FLAG => I_LOAD_FLAG,
    P_LOAD_TMP  => I_LOAD_TMP,
    P_LOAD_GR   => I_LOAD_GR,
    P_SELECT_A  => I_SELECT_A,
    P_SELECT_D  => I_SELECT_D,
    P_SELECT_W  => I_SELECT_W,
    P_SELECT_B  => I_SELECT_B,
    P_ALU_START => I_ALU_START,
    P_BUSY      => I_BUSY,
    P_FLAG_V    => I_FLAG_V,
    P_FLAG_C    => I_FLAG_C,
    P_FLAG_Z    => I_FLAG_Z,
    P_FLAG_S    => I_FLAG_S,
    P_TLBMISS   => I_TLBMISS,
    P_MR        => P_MR,
    P_IR        => P_IR,
    P_RW        => P_RW,
    P_SVC       => P_SVC
  );

  -- ポート
  P_ADDR <= I_ADDR;
  P_DOUT <= I_DOUT;
  P_LI   <= I_LOAD_IR;
  P_VR   <= '0'; -- TODO
  P_HL   <= '0'; -- TODO
  P_BT   <= '0'; -- TODO
  P_PR   <= I_FLAG_P;
  P_IOPR <= I_FLAG_I;
  P_PRIVIO <= '0'; --TODO: 命令で特権違反がある場合1

  -- マルチプレクサ

  --- MUX A
  with I_SELECT_A select
    I_ADDR <= I_REG_PC          when "000",
              I_REG_PC + 2      when "001",
              I_EA              when "010",
              I_SP              when "100",
              I_SP + 2          when "101",
              I_SP - 2          when others;
  
  --- MUX D
  with I_SELECT_D select
    I_DOUT <= I_REG_PC                        when "000",
              I_REG_PC + 2                    when "001",
              I_REG_PC + 4                    when "010",
              I_RD                            when "100",
              "00000000" & I_RD(15 downto 8)  when "101",
              I_FLAG                          when "110",
              I_REG_TMP                       when others;

  --- MUX W
  with I_SELECT_W select
    I_DR_IN <= P_DIN                                    when "00",
               (others => P_DIN(3)) & P_DIN(3 downto 0) when "01",
               "00000000" & P_DIN(7 downto 0)           when "10",
               "00000000" & P_DIN(15 downto 8)          when others;
  
  --- MUX B
  with I_SELECT_B select
    I_ALU_B <= I_REG_DR        when '0',
               I_RX            when others;

  --- EA
  with I_INST_OP2 select
    I_EA <= I_REG_DR                when "000",
            I_REG_DR + I_RX         when "001",
            I_REG_FP + (I_REG_DR(14 downto 0) & "0") when "011",
            I_RX                    when "110",
            I_RD                    when others;

  -- 信号の設定
  I_SP <= I_REG_SSP when I_FLAG_P='1' else I_REG_USP;

  I_RD <= I_REG_FP   when I_INST_RD="1100" else
          I_SP       when I_INST_RD="1101" else
          I_REG_USP  when I_INST_RD="1110" else
          I_FLAG     when I_INST_RD="1111" else
          I_REG_GR(conv_integer(I_INST_RD));
  
  I_RX <= I_REG_FP   when I_INST_RX="1100" else
          I_SP       when I_INST_RX="1101" else
          I_REG_USP  when I_INST_RX="1110" else
          I_FLAG     when I_INST_RX="1111" else
          I_REG_GR(conv_integer(I_INST_RX));
  
  I_FLAG <= "00000000" & I_FLAG_E & I_FLAG_P & I_FLAG_I & '0' & I_FLAG_V & I_FLAG_C & I_FLAG_S & I_FLAG_Z;
  
  I_BUSY <= '1' when I_ALU_BUSY = '1' else '0';

  I_TLBMISS <= '1' when P_ADR_INT = '1' or P_VIO_INT = '1' or P_TLBMISS = '1'
          else '0';
  
  -- レジスタの制御

  --- GR の書き込み制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      for i in 0 to 11 loop
        I_REG_GR(i) <= (others => '0');
      end loop;
      I_REG_FP  <= (others => '0');
      I_REG_SSP <= (others => '0');
      I_rEG_USP <= (others => '0');
    elsif (P_CLK0' event and P_CLK0='1' and I_LOAD_GR='1') then
      case I_INST_RD is
        when "1100" => I_REG_FP   <= I_ALU_OUT;
        when "1101" =>
          if (I_FLAG_P='1') then
            I_REG_SSP <= I_ALU_OUT;
          else
            I_REG_USP <= I_ALU_OUT;
          end if;
        when "1110" => I_REG_USP  <= I_ALU_OUT;
        when others => I_REG_GR(conv_integer(I_INST_RD)) <= I_ALU_OUT;
      end case;
    end if;
  end process;

  --- DR の書き込み制御
  process(P_CLK0, P_RESET) begin
    if (P_RESET='0') then
      I_REG_DR <= (others => '0');
    elsif (P_CLK0' event and P_CLK0='1' and I_LOAD_DR='1') then
      I_REG_DR <= I_DR_IN;
    end if;
  end process;
      
  --- FLAG の書き込み制御
  process(P_CLK0, P_RESET) begin
    if (P_RESET='0') then
      I_FLAG_E <= '0';
      I_FLAG_P <= '1';
      I_FLAG_I <= '0';
      I_FLAG_V <= '0';
      I_FLAG_C <= '0';
      I_FLAG_S <= '0';
      I_FLAG_Z <= '0';
    elsif (P_CLK0'event and P_CLK0='1') then
      if (I_LOAD_GR='1' and I_INST_RD="1111") then
        if (I_FLAG_P='1') then
          I_FLAG_E <= I_ALU_OUT(7);
          I_FLAG_P <= I_ALU_OUT(6);
          I_FLAG_I <= I_ALU_OUT(5);
        end if;
        I_FLAG_V <= I_ALU_OUT(3);
        I_FLAG_C <= I_ALU_OUT(2);
        I_FLAG_S <= I_ALU_OUT(1);
        I_FLAG_Z <= I_ALU_OUT(0);
      elsif (I_LOAD_FLAG='1') then
        I_FLAG_V <= I_ALU_OVERFLOW;
        I_FLAG_C <= I_ALU_CARRY;
        I_FLAG_S <= I_ALU_SIGN;
        I_FLAG_Z <= I_ALU_ZERO;
      end if;
    end if;
  end process;
  
  -- PC の書き込み制御
  process(P_CLK0, P_RESET) begin
    if (P_RESET='0') then
      I_REG_PC <= (others => '0');
    elsif (P_CLK0'event and P_CLK0='1') then
      case I_UPDATE_PC is
        when "100" => I_REG_PC <= I_REG_PC + 2;
        when "101" => I_REG_PC <= I_REG_PC + 4;
        when "110" => I_REG_PC <= P_DIN;
        when "111" => I_REG_PC <= I_EA;
        when others => NULL;
      end case;
    end if;
  end process;

  -- TMP の書き込み制御
  process(P_CLK0, P_RESET) begin
    if (P_RESET='0') then
      I_REG_TMP <= (others => '0');
    elsif (P_CLK0'event and P_CLK0='1') then
      if (I_LOAD_TMP='1') then
        I_REG_TMP <= I_FLAG;
      end if;
    end if;
  end process;
end RTL;
