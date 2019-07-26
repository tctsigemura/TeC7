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
-- TeC RAM
--
-- 2019.03.01 : シングルポート分散RAMに書き換える
--              （もとはデュアルポートブロックRAMだったがリソース不足）
--

library IEEE;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

entity TEC_RAM is
  port (
    P_CLK  : in  std_logic;
    P_ADDR : in  std_logic_vector(7 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0);
    P_DIN  : in  std_logic_vector(7 downto 0);
    P_RW   : in  std_logic;
    P_MR   : in  std_logic;

    P_PNA  : in  std_logic_vector(7 downto 0);  -- パネルアドレス
    P_PND  : in  std_logic_vector(7 downto 0);  -- パネル用データ入力
    P_SEL  : in  std_logic_vector(2 downto 0);  -- ロータリースイッチの位置
    P_WRITE: in  std_logic;                     -- パネル書き込み信号
    P_MMD  : out std_logic_vector(7 downto 0);  -- パネル用データ出力

    P_MODE : in  std_logic_vector(1 downto 0)   -- 0,1:通常, 2:デモ1, 3:デモ2
-- デモ1 : 電子オルゴールプログラム入力済
-- デモ2 : 電子オルゴールプログラムとデータが入力済
  );
end TEC_RAM;

architecture BEHAVE of TEC_RAM is
  subtype word is std_logic_vector(7 downto 0);
  type memory is array(0 to 1023) of word;
  function read_file (fname : in string) return memory is
    file data_in : text is in fname;
    variable line_in: line;
    variable ram : memory;
    begin
      for i in 0 to 1023 loop
        readline (data_in, line_in);
		  read(line_in, ram(i));
      end loop;
      return ram;
    end function;
  signal mem : memory := read_file("tec_ram.txt");

  signal dec   : std_logic;                     -- アドレスデコード結果
  signal we     : std_logic;                    -- 書き込み信号
  signal addr10 : std_logic_vector(9 downto 0); -- 10ビットにしたアドレス

  signal ain    : std_logic_vector(9 downto 0); -- RAMのアドレス
  signal din    : std_logic_vector(7 downto 0); -- RAMの書き込みデータ
  signal dout   : std_logic_vector(7 downto 0); -- RAMの読み出しデータ

  begin
    -- CPUがBUS命令実行ならCPUのアドレス
    addr10 <= (P_MODE & P_ADDR) when (P_MR='1') else (P_MODE & P_PNA);

    -- アドレスをラッチすると(BLOCK RAMになる)
    ain <= addr10;
--  process(P_CLK)
--    begin
--      if (P_CLK'event and P_CLK='0') then
--        ain <= addr10;
--      end if;
--    end process;

    -- 書き込みアドレスのデコード
    -- MODE=0,1 の時は E0H〜FFH が書き込み不可
    -- MODE=2   の時は、加えて 80H〜BFH が書き込み不可
    -- MODE=3   の時は、更に加えて 00H〜7FH が書き込み不可
    dec<= not ain(7) or not ain(6) or not ain(5) when P_MODE="00" else
          not ain(7) or not ain(6) or not ain(5) when P_MODE="01" else
          not ain(7) or (ain(6) and not ain(5))  when P_MODE="10" else
          ain(7) and ain(6) and not ain(5);

    -- 書き込み判定
    we <= (P_MR and P_RW and dec) or
          (P_WRITE and P_SEL(2) and not P_SEL(1) and P_SEL(0) and dec);

    -- 書き込み制御（シングルポートにする）
    din <= P_DIN when P_MR='1' else P_PND;      -- CPUがBUS命令実行ならP_DIN
    process(P_CLK)
      begin
        if (P_CLK'event and P_CLK='0') then
          if (we='1') then
            mem( conv_integer(ain) ) <= din;
          end if;
        end if;
      end process;

    -- 読み出し制御（CPU読み出し時にパネルの表示が変化しないように）
    dout <= mem( conv_integer(ain) );
    P_DOUT <= dout;
    process(P_CLK)
      begin
        if (P_CLK'event and P_CLK='0') then
          if (P_MR='0') then
            P_MMD <= dout;                      -- CPUがBUS命令以外ならパネル
          end if;
        end if;
      end process;
  end BEHAVE;
