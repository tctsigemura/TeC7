PDFS = Fig/TacInst-crop.pdf \
       Fig/TeC7.pdf Fig/TeC.pdf Fig/kakubu.pdf Fig/TaC.pdf \
       Fig/Console.pdf Fig/Jumper.pdf Fig/Spi.pdf Fig/TeC7dPcb.pdf

all : ${PDFS}
	latexmk -lualatex manual
#	latexmk -interaction=nonstopmode -lualatex manual

Fig/TacInst-crop.pdf : ../Arch/TaC命令表.pdf
	pdfcrop ../Arch/TaC命令表.pdf Fig/TacInst-crop.pdf

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

Fig/TeC7dPcb.pdf : ../PCB/TeC7d.pdf
	pdfcrop ../PCB/TeC7d.pdf Fig/TeC7dPcb.pdf

clean :
	rm -f *.log *.aux *.dvi *.out *.toc *.vrb *.snm *.nav \
        *.fls *.fdb_latexmk *~

