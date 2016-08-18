#include <stdlib.h>
#include <Windows.h>

int main(int argc, char* argv[])
{
	HANDLE hc,hf;
	DCB dcb;
	COMMTIMEOUTS cto;
	char buf[256];
	DWORD rn,wn;
	BOOL b;

	hf=CreateFile(argv[1],
		GENERIC_READ,
		0,
		NULL,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		NULL);

	if(hf==INVALID_HANDLE_VALUE){
		perror("Can't open file\n");
		exit(1);
	}

	hc=CreateFile(argv[2],
		GENERIC_WRITE,
		0,
		NULL,
		OPEN_EXISTING,
		0,
		NULL);

	if(hc==INVALID_HANDLE_VALUE){
		perror("Can't open port\n");
		CloseHandle(hf);
		exit(1);
	}

	ClearCommBreak(hc);

	GetCommState(hc,&dcb);
	dcb.BaudRate = 9600;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;
	SetCommState(hc,&dcb);

	GetCommTimeouts(hc,&cto);
	cto.WriteTotalTimeoutConstant=1000;
	cto.WriteTotalTimeoutMultiplier=0;
	SetCommTimeouts(hc,&cto);

	printf("TeC を受信状態にして Enter キーを押してください。");
	getchar();

	while(1){
		if(ReadFile(hf,buf,256,&rn,NULL)!=0){
			if(rn==0) break;
		}else{
			perror("Can't read file\n");
			CloseHandle(hf);
			CloseHandle(hc);
			exit(1);			
		}
		buf[rn]='\0';
		/*printf("%s\n %d\n",buf,rn);*/
		b=WriteFile(hc,buf,rn,&wn,NULL);
		if(b==0 || (b!=0 && rn>wn)){
			
			perror("Can't write file\n");
			CloseHandle(hf);
			CloseHandle(hc);
			exit(1);				
		}

	}

	CloseHandle(hf);
	CloseHandle(hc);
	return 0;
}