.SUFFIXES:
.SUFFIXES: .tex .pdf

PDFS = manual.pdf

%.pdf : %.tex *.sty
	lualatex $*.tex
#	lualatex $*.tex
#	dvipdfmx $*.dvi
	open $*.pdf

all : ${PDFS}

manual.pdf : manual.tex chap?.tex app?.tex *.sty Fig/TacInst.pdf \
             Fig/TeC7.pdf Fig/TeC.pdf Fig/kakubu.pdf Fig/TaC.pdf \
             Fig/Console.pdf Fig/Jumper.pdf Fig/Spi.pdf Fig/TeC7dPcb.pdf

Fig/TacInst.pdf : ../Doc/Arch/TaC命令表.pdf
	pdfcrop ../Doc/Arch/TaC命令表.pdf Fig/TacInst.pdf

Fig/kakubu.pdf : Keynote/kakubu.pdf
	pdfcrop Keynote/kakubu.pdf Fig/kakubu.pdf

Fig/TeC7.pdf : Keynote/TeC7.pdf
	pdfcrop Keynote/TeC7.pdf Fig/TeC7.pdf

Fig/TeC.pdf : Keynote/TeC.pdf
	pdfcrop Keynote/TeC.pdf Fig/TeC.pdf

Fig/TaC.pdf : Keynote/TaC.pdf
	pdfcrop Keynote/TaC.pdf Fig/TaC.pdf

Fig/Console.pdf : Keynote/Console.pdf
	pdfcrop Keynote/Console.pdf Fig/Console.pdf

Fig/Jumper.pdf : Keynote/Jumper.pdf
	pdfcrop Keynote/Jumper.pdf Fig/Jumper.pdf

Fig/Spi.pdf : Keynote/Spi.pdf
	pdfcrop Keynote/Spi.pdf Fig/Spi.pdf

Fig/TeC7dPcb.pdf : ../Doc/PCB/TeC7d.pdf
	pdfcrop ../Doc/PCB/TeC7d.pdf Fig/TeC7dPcb.pdf

clean :
	rm -f *.log *.aux *.dvi *.out *.toc *.vrb *.snm *.nav *~

