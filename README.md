# Tokuyama Educational Computer Ver.7 (TeC7)

![TeC7の写真](https://github.com/tctsigemura/TeC7/blob/master/Doc/TeC7.jpg?raw=true "写真")

TeC7は徳山高専で開発した教育用コンピュータです。
TeC7の最大の特徴はコンピュータの内部を２進数でアクセスすることができるコンソールパネルを持っていることです。
コンソールパネルを用いるとソフトウェアの介在なしに、
CPUやメモリの内部を直接に観察・操作でき、
ノイマン型コンピュータの動作原理を体感的に学習するために最適です。
TeC7は
[竹上電気商会](http://www.e-takegami.jp/products/tec6/)
から入手することができます。

## TeCプロジェクトの目標

VHDLなどで記述されたTeCのハードウェア、
C--言語で記述されたTacOS、
C--言語で記述されたコンパイラ、
これら全てのソースコードを公開し、
ハードウェアからアプリケーションまで一貫した
教材を提供することを目標にしています。

## レポジトリの内容
このレポジトリにはVHDLで記述されたTeC7の設計データ、
マイクロプログラム開発用のツール、
マイクロプログラムのソース、
IPLなどファームウェアのソース、
多少のドキュメントが置いてあります。
TeC7にはTeC(8bit)とTaC(16bit)の２台の教育用コンピュータが内蔵されています。
どちらを使用するかはプリント基板上のジャンパーのセッティングにより決まります。

### TeC(Tokuyama Educational Computer)
TeC7に内蔵された8bitマイコンです。
コンピュータサイエンスを学ぶ高専低学年の学生が
ノイマン型コンピュータの原理を体感的に学ぶために開発しました。
TeCのプログラムはハンドアセンブルして作成した機械語です。
2進数に変換してコンソールパネルから入力します。
クロスアセンブラ
([Tasm](https://github.com/tctsigemura/Tasm))を
使用したアセンブリ言語によるプログラミングも可能です。

TeCの詳しいドキュメントは
[TeC教科書](https://github.com/tctsigemura/TecTextBook)
に公開してあります。

### TaC(Tokuyama Advaced educational Computer)
TeC7に内蔵された16bitのパーソナルコンピュータです。
ディスプレイ、キーボード、マイクロSDカードを接続することで、1980年代前半の8bitパソコン程度（？）の能力を発揮します。
コンピュータサイエンスを学ぶ高専高学年の学生が
実際に動作するPCの例として使用したり、
設計を解析する目的で設計しました。

TaC上では
[C--言語](https://github.com/tctsigemura/C--)
で記述された
[TacOS](https://github.com/tctsigemura/TacOS)
が動作します。
現在C--言語プログラムはクロス開発ですが、
近い将来にはTacOS上でセルフ開発ができるようになる予定です。

### TaCとして動作中の写真(OS起動前の状態)
![TaCとして動作中](https://github.com/tctsigemura/TeC7/blob/master/Doc/TaC.jpg?raw=true "写真")

### ディレクトリ構成

```
+ README.md     このファイル
|
+ TeC +         TeCモード関連のユーティリティ等
|     |
|     + Ipl     Ipl(シリアル通信でプログラムをダウンロード)
|     |
|     + Mcode   マイクロプログラム
|     |
|     + Test    デモプログラム等
|
+ TaC +         TaCモード関連のユーティリティ等
|     |
|     + Ipl     Ipl(uSDカードから kernel.bin を読み込む)
|     |
|     + Mcode   マイクロプログラム
|     |
|     + Test    TaC の I/O 動作テスト等で使用するプログラム
|
+ Util          TeC,TaC両方のIPL,Mcodeの生成に必要なツール
|
+ VHDL          TeC7 VHDL ソース
```
