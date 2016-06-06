#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
//#pragma warning (disable:4996)

#define COLS 2
#define ROWS 3
#define SEP ","

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

void dateParse(char *date){
	printf (">>date parser:\n");

    //date = "20/05/2016 09:48:17.439";
    int d, m, y, h, mi, ms;
    int s;
    //float s;

    sscanf(date, "%d/%d/%d%d:%d:%d.%d", &d, &m, &y, &h, &mi, &s, &ms);
    //sscanf(date, "%d/%d/%d %d:%d:%f4", &d, &m, &y, &h, &mi, &s);
	printf ("%d\n", d);
	printf ("%d\n", m);
	printf ("%d\n", y);
	printf ("%d\n", h);
	printf ("%d\n", mi);
	printf ("%d\n", s);
	printf ("%d\n", ms);

	// Convert into milliseconds Linux
}

void parser(float array[][COLS], int _row, int _col, const char *_colstr){
	// get date
	dateParse("20/05/2016 09:48:17.435"); // "Tue, 13 Dec 2011 16:08:21 GMT"

	// get value
	array[_row][_col] = atof(_colstr);

	printf("%s%.2f%s", _col?"":"\n", array[_row][_col], SEP);
	//printf(strcat(_colstr, "\n"));
}

int main(){
	//const char filename[] = "D:\\Dev\\HEARTISANS\\csv_reader\\input.txt";
	const char filename[] = "D:\\Dev\\HEARTISANS\\2016_05_20-09_48_17_ECG2000.csv";
	// 20/05/2016 09:48:17.435,3422
	// 20/05/2016 09:48:17.439,3413

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
			char* value = strtok(NULL, ",");
			printf ("%s",value);

			// extract real data
			dateParse(timestamp);

			printf("\n");


		}
		fclose(f); puts("\n");
	}else
		perror(filename);
	//return 0;

	return EXIT_SUCCESS;


}
