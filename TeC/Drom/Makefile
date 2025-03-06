../drom.txt : srcToTxt drom.src
	./srcToTxt < drom.src > tec_cpu_drom.txt

srcToTxt : srcToTxt.c
	cc -o srcToTxt srcToTxt.c

clean:
	rm -f ./srcToTxt

