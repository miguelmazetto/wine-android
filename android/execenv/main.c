#include <unistd.h>
#include <string.h>
#include <stdio.h>
int main(int argc, char* argv[]){
	char** newargv = (char**)malloc(sizeof(char**) * (argc+2));
	char* newargv0 = (char*)malloc(strlen(argv[0]) + 4);
	newargv0[0] = '\0';
	strcat(newargv0, argv[0]);
	strcat(newargv0, ".sh");
	argv[0] = newargv0;
	newargv[0] = "/bin/bash";
	memcpy(newargv+1, argv, (argc) * sizeof(char**));
	newargv[argc+2] = NULL;
	//newargv0[argc+1] = NULL;
	//for (int i = 0; i < argc+2; ++i)
	//{
	//	printf("%u = %s\n",i,newargv[i]);
	//}
	return execvp("/bin/bash", newargv);
}