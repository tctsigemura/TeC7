# Tokuyama Educational Computer Ver.7 (TeC7)

![TeC7の写真](https://github.com/tctsigemura/TeC7/blob/master/Doc/Photos/TeC7c.jpg?raw=true "写真")

TeC7は徳山高専で開発した教育用コンピュータです．
TeC7の最大の特徴はコンピュータの内部を２進数でアクセスすることができるコンソールパネルを持っていることです．
コンソールパネルを用いるとソフトウェアの介在なしに，
CPUやメモリの内部を直接に観察・操作でき，
ノイマン型コンピュータの動作原理を体感的に学習するために最適です．
TeC7は
[竹上電気商会](http://www.e-takegami.jp/products/tec6/)
から入手することができます．

## TeCプロジェクトの目標

VHDLなどで記述されたTeCのハードウェア，
C--言語で記述されたTacOS，
C--言語で記述されたコンパイラ，
これら全てのソースコードを公開し，
ハードウェアからアプリケーションまで一貫した
教材を提供することを目標にしています．

## レポジトリの内容
このレポジトリにはVHDLで記述されたTeC7の設計データ，
IPLなどファームウェアのソース，
多少のドキュメントが置いてあります．
TeC7にはTeC(8bit)とTaC(16bit)の２台の教育用コンピュータが内蔵されています．
どちらを使用するかはプリント基板上のジャンパーのセッティングにより決まります．

### TeC(Tokuyama Educational Computer)
TeC7に内蔵された8bitマイコンです．
コンピュータサイエンスを学ぶ高専低学年の学生が
ノイマン型コンピュータの原理を体感的に学ぶために開発しました．
TeCのプログラムはハンドアセンブルして作成した機械語です．
2進数に変換してコンソールパネルから入力します．
クロスアセンブラ
([Tasm](https://github.com/tctsigemura/Tasm))を
使用したアセンブリ言語によるプログラミングも可能です．

TeCの詳しいドキュメントは
[TeC教科書](https://github.com/tctsigemura/TecTextBook/raw/master/tec.pdf)
に公開してあります．

### TaC(Tokuyama Advaced educational Computer)
TeC7に内蔵された16bitのパーソナルコンピュータです．
古い機種TeC7aは，ディスプレイ，キーボード，マイクロSDカードを接続することで，
1980年代前半の8bitパソコン程度（？）の能力を発揮します．
最近の機種TeC7b,c,dは，USBシリアル，または，
Blutetoothで接続したPCやスマホを
ディスプレイやキーボードの代替として使用します．
コンピュータサイエンスを学ぶ高専高学年の学生が
実際に動作するPCの例として使用したり，
設計を解析する目的で設計しました．

TaC上では
[C--言語](https://github.com/tctsigemura/C--)
で記述された
[TacOS](https://github.com/tctsigemura/TacOS)
が動作します．
現在C--言語プログラムはクロス開発ですが，
近い将来にはTacOS上でセルフ開発ができるようになる予定です．

### Bluetooth で接続した Mac を端末にして TacOS が動作中の写真
![TaCとして動作中](https://github.com/tctsigemura/TeC7/blob/master/Doc/Photos/Blueterm.jpg?raw=true "写真")

### ディレクトリ構成

```
+ README.md     このファイル
|
+ TeC7d.msc     コンパイル済みのTeC7の設計データ
|
+ VHDL          TeC7 VHDL ソース
|
+ Doc +         ドキュメント
|     |
|     + Arch    TeC, TaC の命令表
|     |
|     + Manual  TeC7 のマニュアル（manual.pdf）
|     |
|     + PCB     TeC7 の回路図，ピンコネ
|     |
|     + Photos  TeC7 の写真
|     |
|     + VHDL    TeC7 の設計に関する資料（ブロック図，ステートマシン図など）
|
+ TeC +         TeC に組み込むプログラムとテストプログラム
|     |
|     + Ipl     Ipl(シリアル通信でプログラムをダウンロード)
|     |
|     + Drom    命令デコード用のROMデータ
|     |
|     + Test    テストプログラムやデモプログラム等
|
+ TaC +         TaC に組み込むプログラムとテストプログラム
|     |
|     + Ipl     Ipl(uSDカードから kernel.bin を読み込む)
|     |
|     + Test    TaC の動作テスト等で使用するプログラム
|
+ Util          TeC,TaC両方のIPLなどの生成に必要なツール
|
+ Case          TeC7 ケースのラベル
|
+ VERSION       バージョン
|
+ HISTORY       変更の記録
```
