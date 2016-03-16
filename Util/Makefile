all: bin2hex bin2hex16 hex2txt tbl2hex

bin2hex: bin2hex.c
	cc -o bin2hex bin2hex.c

bin2hex16: bin2hex16.c
	cc -o bin2hex16 bin2hex16.c


hex2txt: hex2txt.c
	cc -o hex2txt hex2txt.c

tbl2hex: tbl2hex.c
	cc -o tbl2hex tbl2hex.c

clean :
	rm -f ./bin2hex ./bin2hex16 ./hex2txt ./tbl2hex *~

