--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2019 by
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
         P_VR    : out std_logic;                        -- Vector Fetch
         P_HL    : out std_logic;                        -- Halt Instruction
         P_BT    : out std_logic;                        -- Byte to
         P_PR    : out std_logic;                        -- privilege Mode
         P_IOPR  : out std_logic;                        -- IO privilege Mode
         P_INTR  : in  std_logic;                        -- Intrrupt
         P_STOP  : in  std_logic                         -- Panel RUN F/F
        );
end TAC_CPU;


architecture RTL of TAC_CPU is

-- レジスタファイル
type RegGR is array(0 to 11) of std_logic_vector(15 downto 0);
signal I_REG_GR  : RegGR;                          -- G0-G11
signal I_REG_FP  : std_logic_vector(15 downto 0);  -- FP (G12)
signal I_REG_SSP : std_logic_vector(15 downto 0);  -- SSP
signal I_REG_USP : std_logic_vector(15 downto 0);  -- USP
signal I_REG_FLAG: std_logic_vector(15 downto 0);  -- USP

signal I_REG_PC  : std_logic_vector(15 downto 0);  -- PC

-- フラグ
signal I_FLAG_E   : std_logic;                     -- Interrupt Enable
signal I_FLAG_P   : std_logic;                     -- Privilege
signal I_FLAG_IOP : std_logic;                     -- IO Privilege
signal I_FLAG_V   : std_logic;                     -- Over Flow
signal I_FLAG_C   : std_logic;                     -- Carry
signal I_FLAG_S   : std_logic;                     -- Sign
signal I_FLAG_Z   : std_logic;                     -- Zero

-- 内部レジスタ
signal I_REG_DR  : std_logic_vector(15 downto 0);  -- DR
signal I_REG_TMP : std_logic_vector(15 downto 0);  -- TMP

-- 内部配線
signal I_EA          : std_logic_vector(15 downto 0); -- 実効アドレス
signal I_SP          : std_logic_vector(15 downto 0); -- スタックポインタ (カーネルモードとユーザーモードで切り替える)
signal I_RD          : std_logic_vector(15 downto 0); -- GR[Rd]
signal I_RX          : std_logic_vector(15 downto 0); -- GR[Rx]
signal I_DR_IN       : std_logic_vector(15 downto 0); -- DR への入力
signal I_INST_OP1    : std_logic_vector(4 downto 0);  -- 命令の OP1
signal I_INST_OP2    : std_logic_vector(2 downto 0);  -- 命令の OP2
signal I_INST_RD     : std_logic_vector(4 downto 0);  -- 命令の Rd
signal I_INST_RX     : std_logic_vector(4 downto 0);  -- 命令の Rx
signal I_UPDATE_PC   : std_logic_vector(1 downto 0);  -- PC の更新
signal I_UPDATE_SP   : std_logic_vector(1 downto 0);  -- SP の更新
signal I_LOAD_IR     : std_logic;                     -- IR のロード
signal I_LOAD_DR     : std_logic;                     -- DR のロード
signal I_LOAD_FLAG   : std_logic;                     -- FLAG のロード
signal I_LOAD_TMP    : std_logic;                     -- TMP のロード
signal I_LOAD_GR     : std_logic;                     -- 汎用レジスタのロード
signal I_SELECT_A    : std_logic_vector(2 downto 0);  -- MUX A の選択
signal I_SELECT_D    : std_logic_vector(2 downto 0);  -- MUX D の選択
signal I_SELECT_W    : std_logic_vector(2 downto 0);  -- MUX W の選択
signal I_SELECT_B    : std_logic_vector(2 downto 0);  -- MUX B の選択
signal I_ALU_B       : std_logic_vector(15 downto 0); -- ALU への B 信号
signal I_ALU_START   : std_logic;                     -- ALU への START 信号
signal I_ALU_BUSY    : std_logic;                     -- ALU からの BUSY 信号
signal I_ALU_OUT     : std_logic_vector(15 downto 0); -- ALU の出力
signal I_ALU_OVERFLOW: std_logic;                     -- ALU の Over flow 出力
signal I_ALU_CARRY   : std_logic;                     -- ALU の Carry 出力
signal I_ALU_ZERO    : std_logic;                     -- ALU の Zero  出力
signal I_ALU_SIGN    : std_logic;                     -- ALU の Sign  出力

begin

  -- マルチプレクサ

  --- MUX A
  with I_SELECT_A select
    P_ADDR <= I_REG_PC          when "000",
              I_REG_PC + 2      when "001",
              I_EA              when "010",
              I_SP              when "100",
              I_SP + 2          when "101",
              I_SP - 2          when "110",
              (others => '0')   when others;
  
  --- MUX D
  with I_SELECT_D select
    P_DOUT <= I_REG_PC                        when "000",
              I_REG_PC + 2                    when "001",
              I_REG_PC + 4                    when "010",
              I_RD                            when "100",
              "00000000" & I_RD(15 downto 8)  when "101",
              I_REG_FLAG                      when "110",
              I_REG_TMP                       when "111",
              (others => '0')                 when others;

  --- MUX W
  with I_SELECT_W select
    I_DR_IN <= P_DIN                                    when "00",
               (others => P_DIN(3)) & P_DIN(3 downto 0) when "01",
               "00000000" & P_DIN(7 downto 0)           when "10",
               "00000000" & P_DIN(15 downto 8)          when "11"
               (others => '0')                          when others;
  
  --- MUX B
  with I_ALU_B <= I_REG_DR        when "0",
                  I_RX            when "1",
                  (0thers => '0') when others;

  --- EA
  with I_INST_OP2 select
    I_EA <= I_REG_DR                when "000",
            I_REG_DR + I_RX         when "001",
            I_REG_FP + I_REG_DR * 2 when "011",
            I_RX                    when "110",
            I_RX                    when "111",
            (others => '0')         when others;

  -- 信号の設定

  
  -- レジスタの制御

  --- GR の書き込み制御
  process(P_CLK0, P_RESET)
  begin
    if (P_RESET='0') then
      for i in 0 to 11 loop
        I_REG_GR(i) <= (others => '0');
      end loop;
      I_FP   <= (others => '0');
      I_SSP  <= (others => '0');
      I_USP  <= (others => '0');
      I_FLAG <= (others => '0');
      I_PC   <= (others => '0');
    elsif (P_CLK0' event and P_CLK0='1') then
      case I_INST_RD is
        when "1100" => I_REG_FP   <= I_ALU_OUT;
        when "1101" =>
          if (FLAG_P='1') then
            I_REG_SSP <= I_ALU_OUT;
          else
            I_REG_USP <= I_ALU_OUT;
          end if;
        when "1110" => I_REG_USP  <= I_ALU_OUT;
        when "1111" =>
          if (FLAG_P='1') then
            I_REG_FLAG <= I_ALU_OUT;
          else
            I_REG_FLAG <= I_REG_FLAG(15 downto 4) & I_ALU_OUT(3 downto 0);
          end if;
        when others => I_REG_GR(conv_integer(I_INST_RD)) <= I_ALU_OUT;
      end case;
    end if;
  end process;

end RTL;
