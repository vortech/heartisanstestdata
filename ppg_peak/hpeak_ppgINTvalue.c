#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
#include <assert.h>

#define COLS 2
#define ROWS 3
#define SEP ","
_Bool ppg;


void dateParse(char *date)
{
	printf(">>date parser:\n");
	char bkslash;
	int d, m, y, h, mi, ms;
	int s;
	if (ppg){// 2016-05-20 09:48:09.02
		// clean date: remove \" at the beginning and the end. "\"2016-05-20
		// 09:48:09.00\""
		sscanf(date, "%c %d-%d-%d%d:%d:%d.%d", &bkslash, &y, &m, &d, &h, &mi, &s, &ms);
	}else{// "20/05/2016 09:48:17.439"
		sscanf(date, "%d/%d/%d%d:%d:%d.%d", &d, &m, &y, &h, &mi, &s, &ms);
	}
	printf("%d ", y);
	printf("%d ", m);
	printf("%d ", d);
	printf("%d ", h);
	printf("%d ", mi);
	printf("%d ", s);
	printf("%d ", ms);
	// Convert into epoch milliseconds/UNIX timestamps
	date2epoch(y, m, d, h, mi, s, ms);
}

void date2epoch(int y, int m, int d, int h, int mi, int s, int ms){
	// online check: http://www.epochconverter.com/
	time_t t_of_day;
	struct tm t;
	t.tm_year = y - 1900;
	t.tm_mon = m;				// Month, 0 - jan
	t.tm_mday = d;				// Day of the month
	t.tm_hour = h;
	t.tm_min = mi;
	t.tm_sec = s;
	t.tm_isdst = -1;			// Is DST on? 1 = yes, 0 = no, -1 = unknown
	t_of_day = mktime(&t);
	double tt = (double)((long)t_of_day) + (ms * 0.01);
	printf(" -> Epoch: %.2f\n", tt);
}

int StringToInt(const char *s){
	char *vBuffer[2] = { 0x41, 0xA0 };
	int y = *(int *)&vBuffer;
	int x = *(int *)&s;
	return x;
}

void test_read_dataformat(){
	char *delim = ",";
	char *token;
	// "2016-05-20 09:48:09.00","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2
	// "2016-05-20 09:48:09.01","00,63,DF,00,1F,70,00,0,FF,E3,FF,F2"
	char rowstr[200] ={
"\"TIMESTAMP\",\"PAYLOAD\"\n\"2016-05-20 09:48:09.00\",\"00,63,DF,00,1F,70,00,05,FF,E3,FF,F2\"\n\"2016-05-20 09:48:09.01\",\"00,63,DF,00,1F,70,00,05,FF,E3,FF,F2\"\n"};
	printf ("%s", rowstr);
	printf("\n");
	char *header = strtok(rowstr, delim);
	header = strtok(NULL, delim);
	// printf ("%s", header);

	int i = 0, int_ppgadc, int_amb_adc;
	char *values[12];
	int *p1, p2, p3, a1, a2, a3;
	
	values[i++] = strtok(NULL, "\"");
	char *dataStrInt = values[i - 1];
	printf("%s \n", dataStrInt); // first chunk of 12 bytes
	
	// access to first 3 bytes, rest in token
	sscanf(dataStrInt, "%2[^,], %2[^,], %2[^,], %2[^,], %2[^,], %2[^,],%32[^\n]",  &p1, &p2, &p3, &a1, &a2, &a3, &token);
	strcat(&p1, &p2); // join them: p1+p2+p3
	strcat(&p1, &p3);
	sscanf(&p1, "%x", &int_ppgadc); // ex->int
	strcat(&a1, &a2); // join them: a1+a2+a3
	strcat(&a1, &a3);
	sscanf(&a1, "%x", &int_amb_adc); // ex->int
	printf("%s -> %d , %s -> %d • %s\n", &p1, int_ppgadc,
	 &a1,  int_amb_adc, &token);	
	int ppg = int_ppgadc -  int_amb_adc;
	printf("ppg = %d\n", ppg);
	
	printf ("%s", rowstr);
}

int hex2int(char *hexstring){
	const char *hexstring0 = "0063DF";	// "abcdef0";
	int num = (int)strtol(hexstring, NULL, 16);
	printf("%d\n", num);
	return num;
}

int main(){
	// const char
	// filename[]="D\\Dev\\HEARTISANS\\TR20160520101713_1002_PPG2000.csv";ppg 
	// = 1;
	// const char
	// filename[]="D:\\Dev\\HEARTISANS\\2016_05_20-09_48_17_ECG2000.csv";ppg = 
	// 0;
	const char filename[] = "2016_05_20-09_48_17_ECG2000.csv";
	ppg = 1;

	char *payload;

	test_read_dataformat();
	// test();

	// storage/emulated/0/Dev/heartbeat/c

	printf("\n fin.... \n");
	FILE *f = fopen(filename, "r");
	if (f){
		float aray[ROWS][COLS] = { 0.0f };
		int n, row, col;
		char rowstr[100], colstr[10], *p;

		float arrayDATA[ROWS][COLS] = { 0.0f };

		/* row reader */
		for (row = 0; row < ROWS && fgets(rowstr, 100, f); ++row){

			printf("-> %d", row);
			printf("\n");
			printf(rowstr);
			if (row == 0){// header
				// printf("\n");
				continue;
			}

			// timestamp
			char *timestamp = strtok(rowstr, ",");
			printf("%s\n", timestamp);
			// extract real data
			dateParse(timestamp);

			// sensor values extraction
			int i = 0;
			char *values[12];
			_Bool firstByte = 1;
			char fr[12];
			while ((values[i++] = strtok(NULL, ",")) != NULL){

				char rest[12] = "0x";
				if (firstByte){
					strcat(rest, values[i - 1]);
					// fr = rest;
					strcpy(fr, rest);

					firstByte = 0;
				}else{
					// strcat(rest, values[i-1]);
					// strcat(rest, fr);

					strcat(fr, values[i - 1]);

					StringToInt(fr);
					firstByte = 1;
				}



				// if (firstByte){
				// fr = values[i-1];
				// firstByte = 0;
				// }else{
				// 
				// char str1[16];
				// char str2[16];
				// char rest[16] = "0x";
				// strcpy(str1, fr);
				// strcpy(str2, values[i-1]);
				// strcat(str1, str2);
				// strcat(rest, str1);
				// 
				// StringToInt(rest);
				// firstByte = 1;
				// }
				printf("%s - ", values[i - 1]);
			}


			// convert float from hexstring
			// StringToInt("0063");




			printf("\n");
		}
		fclose(f);
		puts("\n");
	}else
		perror(filename);
	// return 0;



	return EXIT_SUCCESS;
}

/* PPG "TIMESTAMP","PAYLOAD" "2016-05-20
   09:48:09.00","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2" "2016-05-20
   09:48:09.01","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2" "2016-05-20
   09:48:09.02","00,21,52,00,1F,3D,FF,E7,FF,E7,00,06" */

/* ECG imestamp,date2epochECG 20/05/2016 09:48:17.435,3422 20/05/2016
   09:48:17.439,3413 20/05/2016 09:48:17.443,3403 20/05/2016 09:48:17.447,3392 */
