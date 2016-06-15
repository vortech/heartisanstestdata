/*  srv 0.0.09
 *  - plotting use gnuplot
 *  gnuplot> cd 'D:\Dev\HEARTISANS\c\ppg_peak'
 *  gnuplot> set yrange[500000:1300000]
 *  gnuplot> p 'ppgdate.dat' using 1:2  with lines, 'ppgdate.dat' using 3:4 with points pointtype 7 pointsize 1 lc rgb "red"
 */

/* PPG "TIMESTAMP","PAYLOAD" "2016-05-20
   09:48:09.00","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2" "2016-05-20
   09:48:09.01","00,63,DF,00,1F,70,00,05,FF,E3,FF,F2" "2016-05-20
   09:48:09.02","00,21,52,00,1F,3D,FF,E7,FF,E7,00,06" */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
#include <assert.h>

#define COLS 2
#define ROWS 100000 // 100634 166634
#define SEP ","
#define START_CUT 2800 // 380
_Bool debug = 0;
FILE *outputFile;
char* ppg_ds;
float ppg_d;
//double ppg_UnixTime;
long long ppg_UnixTime_2lng;
int ppg_Value;

// peak detector settings
#define _initMAXppg  -99999999
#define _initMINppg  99999999
int _MAXppg = _initMAXppg;
int _MINppg = _initMINppg;
int p_ppg = -730500;
long long p_time = 0;
_Bool search4Max = 0;
int enough_MinMax = 0;
long long _MINtime = .0f;
long long _MAXtime = .0f;
long long _MAXt_pv = .0f;
long long Sum_MAXppg;
float Mean;
float dataProcd;
long long elapsedTime;
float tolerance;
float nTickAvg;
int nTicks;
int nTicksSum;
int nTicksCrt;
float tolerPrc = .30f; // % 30
float moreTolerPrc = .30f;
float lessTolerPrc = .15f;
int pksErr = -1;
int Num_Peaks = 0;
int enough_MinMax_threshold = 15; //15 9
const char filename[]="D:\\Dev\\HEARTISANS\\TR20160520101713_1002_PPG166634ALL.csv";
//const char filename[]="/storage/emulated/0/Dev/heartbeat/c/TR20160520101713_1002_PPG2000.csv";

//float
void dateParse(char *date){
    if (debug) printf(">> Date parse: ");
    char bkslash;
    int d, m, y, h, mi, ms;
    int s;
    // 2016-05-20 09:48:09.02
// clean date: remove \" at the beginning and the end. "\"2016-05-20
// 09:48:09.00\""
    sscanf(date, "%c %d-%d-%d%d:%d:%d.%d", &bkslash, &y, &m, &d, &h, &mi, &s, &ms);

    if (debug){
        printf("%d ", y);
        printf("%d ", m);
        printf("%d ", d);
        printf("%d ", h);
        printf("%d ", mi);
        printf("%d ", s);
        printf("%d ", ms);
    }
// Convert into epoch milliseconds/UNIX timestamps
//float ff =
    date2epoch(y, m, d, h, mi, s, ms);
//return ff;
}

//float
void date2epoch(int y, int m, int d, int h, int mi, int s, int ms){
// online check: http://www.epochconverter.com/
    time_t t_of_day;
    struct tm t;
    t.tm_year = y - 1900;
    t.tm_mon = m;	// Month, 0 - jan
    t.tm_mday = d;	// Day of the month
    t.tm_hour = h;
    t.tm_min = mi;
    t.tm_sec = s;
    t.tm_isdst = -1;	// Is DST on? 1 = yes, 0 = no, -1 = unknown
    t_of_day = mktime(&t);
    double ppg_UnixTime = (double)((long)t_of_day) + (ms * 0.01);
    ppg_UnixTime_2lng = (long long) (ppg_UnixTime * 100);

//    if (debug) printf(" -> Epoch: %.2f\n", ppg_UnixTime);
    if (debug) printf(" -> Epoch(long long): %d\n", ppg_UnixTime_2lng);
    // add to OUTPUT-DATA
//    fprintf(outputFile, "%.2f ", UnixTime);
    //convert to integer
//    int tt_int = tt * 100;
//   printf(">> tt as INT = %d\n", tt_int);
//    ppg_d = UnixTime;
//    printf(ppg_ds, "%.2f ", UnixTime);
    //ppg_ds = (float) tt;
    //return tt;
}

int valueParse(char* dataStrInt){
    char *token;
    int i = 0, int_ppgadc, int_amb_adc;
    char *values[12];
    int *p1, p2, p3, a1, a2, a3;
// access to first 3 bytes, rest in token
    sscanf(dataStrInt, "%2[^,], %2[^,], %2[^,], %2[^,], %2[^,], %2[^,],%32[^\n]",
           &p1, &p2, &p3, &a1, &a2, &a3, &token);
    strcat(&p1, &p2); // join them: p1+p2+p3
    strcat(&p1, &p3);
    sscanf(&p1, "%x", &int_ppgadc); // ex->int
    strcat(&a1, &a2); // join them: a1+a2+a3
    strcat(&a1, &a3);
    sscanf(&a1, "%x", &int_amb_adc); // ex->int
    if (debug) printf("%s -> %d , %s -> %d ... %s\n", &p1, int_ppgadc,
                          &a1,  int_amb_adc, &token);
    // int VALUE = powf(256.0,3)-abs(int_ppgadc-int_amb_adc);
    ppg_Value = (int_amb_adc - int_ppgadc) + 1600000;
    //int VALUE = int_ppgadc - int_amb_adc;

    if (debug) printf(">> VALUE parse = %d\n", ppg_Value);

    // add to OU_MAXtimeTPUT-DATA
    //fprintf(outputFile, "%d", ppg_Value);

    return ppg_Value;
}

void peakdetector(long long time, int ppg){
    // update current
    int c_ppg = ppg;
    long long c_time = time;
    long long PEAK_t = 0;
    int PEAK_v = 0;
    // update previous as current
    p_time = c_time;
    p_ppg = c_ppg;
    nTicks++;
    // start by default searching for the minimum local
    // valid range of search:
    if (search4Max == 0){   // search for minimum.
        if (c_ppg < _MINppg){   // found a new minimum
            _MINppg = c_ppg;
            _MINtime = c_time;
            enough_MinMax = 0;
        }
    }
    else{// search for maximum.
        if (c_ppg > _MAXppg){   // found a new maximum
            _MAXppg = c_ppg;
            _MAXtime = c_time;
            enough_MinMax = 0;
        }
    }
    enough_MinMax++;
    // enough samples to validate the peaks found ?
    if (enough_MinMax >= enough_MinMax_threshold){
        enough_MinMax = 0;
        if (search4Max == 1){   // set maximum found
            dataProcd++;
            // skip the first one. no data!
            if (dataProcd>1){
                //timeSeriesPeaks.add(_MAXtime, _MAXppg);
                //printf("Got a peak!!!...: %d\n", _MAXppg);
                PEAK_v = _MAXppg;
                PEAK_t = _MAXtime;
                Num_Peaks++;
            }
            // check for especial cases: sensor errors? etc.
            // calculate the Mean Value
            elapsedTime = _MAXtime - _MAXt_pv;
            Sum_MAXppg += elapsedTime;
            Mean = (float) (Sum_MAXppg / dataProcd);

            // check for especial area
            // calculate the standard deviation
            tolerance = Mean * tolerPrc; // %
            if ((elapsedTime > (Mean+tolerance)) ||
                    (elapsedTime < (Mean-tolerance))){
                if (pksErr >= 0){  // skip the first one (not valid)
                //timeSeriesErr.add(_MAXtime, _MAXppg);
                }
                pksErr++;
            }
            _MAXppg = _initMAXppg;
            _MAXt_pv = _MAXtime;
            _MAXtime = -99999999;//??????
        }
        else{     // minimum
            //timeSeriesPeaks.add(_MINtime, _MINppg);
            _MINppg = _initMINppg;
            //_MINtime = new Date();
            _MINtime = 9999999;//??????
            nTicksSum += nTicks;
            nTickAvg = (float) (nTicksSum / dataProcd);
            nTicksCrt = nTicks;
            nTicks = 0;
        }
        search4Max = !search4Max; // swapping: valid search
    }
    // add to OUTPUT DATA
    if (PEAK_v > 0)
        fprintf(outputFile, "%lld %d %lld %d\n", ppg_UnixTime_2lng, ppg_Value, PEAK_t, PEAK_v);
    else
        fprintf(outputFile, "%lld %d %s %s\n", ppg_UnixTime_2lng, ppg_Value, "", "");

    return 1;
}

int main(){

// storage/emulated/0/Dev/heartbeat/c
    outputFile = fopen("ppgdate.dat", "w");
    if (outputFile == NULL){
        printf("Error opening file ppgdate.dat!\n");
        exit(1);
    }

    FILE *f = fopen(filename, "r");
    if (f){
        float aray[ROWS][COLS] = { 0.0f };
        int n, row, col;
        char rowstr[100], colstr[10], *p;
        float arrayDATA[ROWS][COLS] = { 0.0f };
        /* row reader */
        for (row = 0; row < ROWS && fgets(rowstr, 100, f); ++row){
            if (row < START_CUT)// cut the beginning noise...
                continue;

            if (debug){
                printf("-> %d", row);
                printf("\n");
                printf(rowstr);
            }
            if (row == 0)// header
                continue;
            // timestamps
            char *timestamp = strtok(rowstr, ",");
            if (debug) printf("%s\n", timestamp);
            // extract real data
            //float t =
            dateParse(timestamp);

            // sensor values extraction
            char *rest  = strtok(NULL, "\"");
            int ppg_v = valueParse(rest);

            // peak detector
            peakdetector(ppg_UnixTime_2lng, ppg_v);

            if (debug) printf("\n");
        }
        fclose(f);
        printf("Total Data: %d\n", ROWS);
        printf("Total PEAKS found: %d\n", Num_Peaks);

        puts("\n");
    }
    else
        perror(filename);

    return EXIT_SUCCESS;
}

