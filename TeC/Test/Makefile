all : 55.bin console_int.bin echo.bin jnz.bin \
      pio.bin servo.bin sound.bin test.bin timer_int.bin sigemura.bin

55.bin : 55.t7
	tasm7 55.t7

console_int.bin : console_int.t7
	tasm7 console_int.t7

echo.bin : echo.t7
	tasm7 echo.t7

jnz.bin : jnz.t7
	tasm7 jnz.t7

pio.bin : pio.t7
	tasm7 pio.t7

servo.bin : servo.t7
	tasm7 servo.t7

sound.bin : sound.t7
	tasm7 sound.t7

test.bin : test.t7
	tasm7 test.t7

timer_int.bin : timer_int.t7
	tasm7 timer_int.t7

sigemura.bin : sigemura.t7
	tasm7 sigemura.t7

clean :
	rm -f *.bin *.lst *~
