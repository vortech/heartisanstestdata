#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
//#pragma warning (disable:4996)
#include <assert.h>

#define COLS 2
#define ROWS 300
#define SEP ","
_Bool ppg;

void powerfWay(){
//	http://stackoverflow.com/questions/18712774/parsing-integer-and-float-values-of-a-text-file-with-sscanf
//	while(fgets(str,512,fp)!= NULL)//read file line by line
//	{
//	    char *tokenstring = str;
//	    uint64_t netrx,nettx,vbd_rd,vbd_wr;
//	    char g[10];
//	    double cpu, mem;
//	    long int c, d, e, f;
//	    sscanf(tokenstring, "%s %lf %lf %lu %lu %lu %lu", g, &cpu, &mem, &nettx, &netrx, &vbd_rd, &vbd_wr);
//	    printf("%s %f %f %ld %ld %ld %ld\n",g,cpu,mem,netrx,nettx,vbd_rd,vbd_wr);
//	}
//	fclose(fp);
}

void dataParse(char *date){
	printf (">>date parser:\n");

	char bkslash;
	int d, m, y, h, mi, ms;
    int s;
	if (ppg){// 2016-05-20 09:48:09.02
		// clean date: remove \" at the beginning and the end. "\"2016-05-20 09:48:09.00\""
	    sscanf(date, "%c %d-%d-%d%d:%d:%d.%d",&bkslash, &y, &m, &d, &h, &mi, &s, &ms);
	}else{// "20/05/2016 09:48:17.439"
	    sscanf(date, "%d/%d/%d%d:%d:%d.%d", &d, &m, &y, &h, &mi, &s, &ms);
	}
	printf ("%d\n", d);
	printf ("%d\n", m);
	printf ("%d\n", y);
	printf ("%d\n", h);
	printf ("%d\n", mi);
	printf ("%d\n", s);
	printf ("%d\n", ms);

	// Convert into epoch milliseconds/UNIX timestamps
	date2epoch(y, m, d, h, mi, s, ms);
}

void date2epoch(int y, int m, int d, int h, int mi, int s, int ms) {
	// online check: http://www.epochconverter.com/
	time_t t_of_day;
	struct tm t;
	t.tm_year = y - 1900;
	t.tm_mon = m;           // Month, 0 - jan
	t.tm_mday = d;          // Day of the month
	t.tm_hour = h;
	t.tm_min = mi;
	t.tm_sec = s;
	t.tm_isdst = -1;        // Is DST on? 1 = yes, 0 = no, -1 = unknown
	t_of_day = mktime(&t);

	double tt = (double)((long) t_of_day) + (ms * 0.01);

	printf("seconds since the Epoch: %.2f\n", tt);
}

void parser(float array[][COLS], int _row, int _col, const char *_colstr){
	// get date
	//dateParse("20/05/2016 09:48:17.435"); // "Tue, 13 Dec 2011 16:08:21 GMT"

	// get value
	array[_row][_col] = atof(_colstr);

	printf("%s%.2f%s", _col?"":"\n", array[_row][_col], SEP);
	//printf(strcat(_colstr, "\n"));
}

void parserPayload(){

}

/*	PPG
  	 "TIMESTAMP","PAYLOAD"
	"2016-05-20 09:48:09.00","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2"
	"2016-05-20 09:48:09.01","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2"
	"2016-05-20 09:48:09.02","00,21,52,00,1F,3D,FF,E7,FF,E7,00,06"*/

/*	ECG
	imestamp,ECG
	20/05/2016 09:48:17.435,3422
	20/05/2016 09:48:17.439,3413
	20/05/2016 09:48:17.443,3403
	20/05/2016 09:48:17.447,3392*/

int main(){
	const char filename[]="D:\\Dev\\HEARTISANS\\TR20160520101713_1002_PPG2000.csv";ppg = 1;
//	const char filename[]="D:\\Dev\\HEARTISANS\\2016_05_20-09_48_17_ECG2000.csv";ppg = 0;
	char* payload;

	FILE *f = fopen(filename, "r");
	if (f){
		float array[ROWS][COLS] = {0.0f};
		int n, row, col;
		char rowstr[100], colstr[10], *p;

		float arrayDATA[ROWS][COLS] = {0.0f};

		/* row reader*/
		for(row = 0; row < ROWS && fgets(rowstr, 100, f); ++row){
			printf(rowstr);
			if (row == 0){ // header
				printf("\n");
				continue;
			}
			/* columns separated by SEP */
/*			for(col = 0, n = *colstr = 0, p = rowstr;
				col < COLS && sscanf(p, "%8[^"SEP"]%n", colstr, &n) != EOF;
				++col, p+=n, *p?++p:0){
				printf(strcat(colstr, "\n"));
				//parser(array, row, col, colstr); // conversion and save in array
			}*/

			// timestamp
			char* timestamp = strtok(rowstr,",");
			printf ("%s\n",timestamp);

			// value
			if (ppg){
				// search: read bytes to float in c
				printf ("ON PPG MODE\n");
				char bkslash;
				int d, m, y, h, mi, ms;
			    int s;
			    char h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12; // trying to read sensor data
			    sscanf(rowstr, "%c %d-%d-%d%d:%d:%d.%d,%c%c,%c,%c,%c,%c,%c,%c,%c,%c,%c,%c,%c",&bkslash, &y, &m, &d, &h, &mi, &s, &ms, &bkslash,
			    		&h1,&h2,&h3,&h4,&h5,&h6,&h7,&h8,&h9,&h10,&h11,&h12);

				printf ("%s",h1);
				printf ("%s",h2);
				printf ("%s",h3);
				printf ("%s",h4);

				//char* token = strsep(&rowstr, ",");
//				payload = strtok(NULL,",");
//				payload = strtok(NULL,",");
//				payload = strtok(NULL,",");
//				payload = strtok(NULL,",");
				//parserPayload(rowstr);
			}else{
				char* value = strtok(NULL, ",");
				printf ("%s",value);
			}

			// extract real data
			dataParse(timestamp);

			printf("\n");


		}
		fclose(f); puts("\n");
	}else
		perror(filename);
	//return 0;

	return EXIT_SUCCESS;


}
