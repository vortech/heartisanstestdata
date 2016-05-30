library(RCurl)
options(digits.secs = 3);

## PPG
make_sign <- function(x, bytes){
  if (x > (256^bytes/2-1)) {
    x = x- 256^bytes		
  }
  return (x)
}
extract_signal <- function(row) {
  hex_string=row['PAYLOAD']
  bytes = strsplit(hex_string, ',')
  ppg_adc = make_sign(as.integer(paste(c('0x', bytes[[1]][1:3]), collapse='')), 3)
  ambient_adc = make_sign(as.integer(paste(c('0x', bytes[[1]][4:6]), collapse='')), 3)
  signed_ppg = ppg_adc - ambient_adc
  row=as.list(row)
  row['VALUE'] = 256^3-abs(signed_ppg)     #The absolute value...
  row['ACC_X'] = make_sign(as.integer(paste(c('0x', bytes[[1]][7:8]), collapse='')), 2)
  row['ACC_Y'] = make_sign(as.integer(paste(c('0x', bytes[[1]][9:10]), collapse='')), 2)
  row['ACC_Z'] = make_sign(as.integer(paste(c('0x', bytes[[1]][11:12]), collapse='')), 2)
  row['ACC_X_Y'] = sqrt(sum(c(row[['ACC_X']], row[['ACC_Y']])^2))
  row['ACC'] = sqrt(sum(c(row[['ACC_X']], row[['ACC_Y']], row[['ACC_Z']])^2))	
  return (row)
}

#fppg <- getURL("https://raw.githubusercontent.com/vortech/heartisanstestdata/master/TR20160520101713_1002_PPG20000.csv")
#ppg <- read.csv(text = fppg)
ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_PPG5000.csv", colClasses=c("character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002.csv", colClasses=c("character", "character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_cut2132ppg.csv", colClasses=c("character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002.csv",header = TRUE, sep = ",")#ORI
nrow(ppg)
ppg[1:1,]
ppg$TIME[1:1]
ppg = do.call(rbind.data.frame,  apply(ppg, 1, extract_signal))
ppg$TIME <- strptime(ppg[,1], "%Y-%m-%d %H:%M:%OS") # 2016-05-20 09:48:09.00
plot(ppg$TIME, ppg$VALUE, type = "l", col = "blue", main = paste(c("PPG: ", nrow(ppg)), collapse = " "))
par(new=TRUE)
# +ACC_XY
plot(ppg$TIME, ppg$ACC_X_Y, type = "l", col = "green", main = paste(c("PPG: ", nrow(ppg)), collapse = " "))
par(new=TRUE)

## ECG
#fecg <- getURL("https://raw.githubusercontent.com/vortech/heartisanstestdata/master/2016_05_20-09_48_17_ECG20000.csv")
#ecg <- read.csv(text = fecg) 
ecg <- read.csv("D:\\Dev\\R\\test\\2016_05_20-09_48_17_ECG5000.csv",header = TRUE, sep = ",", quote="", dec=".")#,comment.char="")
#ecg <- read.csv("D:\\Dev\\R\\test\\2016_05_20-09_48_17_ECG.csv",header = TRUE, sep = ",", quote="", dec=".")#ORI
nrow(ecg)
ecg$TIME <- strptime(ecg[,1], "%d/%m/%Y %H:%M:%OS")

## Problem with date conversion, rounding milliseconds: 
## ecg$Timestamp[1]; strptime(ecg$Timestamp[1], "%d/%m/%Y %H:%M:%OS")
## need to use the option: options(digits.secs = 3);

ecgT = ecg[1500:2000,]
plot(ecg$TIME, ecg$ECG, type = "l", col = "red", main = paste(c("ECG: ", nrow(ecg)), collapse = " "))


################£
################£

local_path = "D:\\Dev\\R\\test\\"
t <- ppg[, c("TIME","VALUE")]
t
pppg_o = paste(c(local_path, "ppg_out.csv"), collapse = "")
#write.csv(t, pppg_o, row.name=TRUE)
t <- write.table(ppg[, c("TIME","VALUE")],paste(c(local_path, 'ppg_out.csv'), collapse = ""),row.names=F,sep=",")

######
###### same columns names for both csv ??
######

pecg_o = paste(c(local_path, "ecg_out.csv"), collapse = "")
w <- ecg[, c("TIME","ECG")]
w
#write.csv(w, pecg_o, row.name=TRUE)
w <- write.table(ecg[, c("TIME","ECG")],paste(c(local_path, 'ecg_out.csv'), collapse = ""),row.names=F,sep=",")


library('zoo')
#Read CSV data as time-series data

z1<-read.zoo(file=pppg_o,sep=",",header=TRUE,tz= "",format="%Y-%m-%d %H:%M:%OS")
z2<-read.zoo(file=pecg_o,sep=",",header=TRUE,tz= "",format="%Y-%m-%d %H:%M:%OS") # "%d/%m/%Y %H:%M:%OS"

#Plot graph
plot.zoo(cbind(z1,z2), plot.type="single", col=c("red","blue"))
