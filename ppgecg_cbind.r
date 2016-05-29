library(RCurl)

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

fppg <- getURL("https://raw.githubusercontent.com/vortech/heartisanstestdata/master/TR20160520101713_1002_PPG20000.csv")
ppg <- read.csv(text = fppg)
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002.csv", colClasses=c("character", "character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_cut2132ppg.csv", colClasses=c("character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_cut40000ppg.csv", colClasses=c("character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002.csv",header = TRUE, sep = ",")#ORI
nrow(ppg)
ppg[1:1,]
ppg$TIME[1:1]
ppg = do.call(rbind.data.frame,  apply(ppg, 1, extract_signal))
ppg$TIME <- strptime(ppg[,1], "%Y-%m-%d %H:%M:%OS") # 2016-05-20 09:48:09.00
plot(ppg$TIME, ppg$VALUE, type = "l", col = "blue", main = paste(c("PPG: ", nrow(ppg)), collapse = " "))
par(new=TRUE)
# ACC
plot(ppg$TIME, ppg$ACC_X_Y, type = "l", col = "green", main = paste(c("PPG: ", nrow(ppg)), collapse = " "))
par(new=TRUE)

## ECG
fecg <- getURL("https://raw.githubusercontent.com/vortech/heartisanstestdata/master/2016_05_20-09_48_17_ECG20000.csv")
ecg <- read.csv(text = fecg) 
#ecg <- read.csv("D:\\Dev\\R\\test\\2016_05_20-09_48_17_ECG20000.csv",header = TRUE, sep = ",", quote="", dec=".")#,comment.char="")
#ecg <- read.csv("D:\\Dev\\R\\test\\2016_05_20-09_48_17_ECG.csv",header = TRUE, sep = ",", quote="", dec=".")#ORI
nrow(ecg)
ecg$TIME <- strptime(ecg[,1], "%d/%m/%Y %H:%M:%OS")
ecgT = ecg[1500:2000,]
plot(ecg$TIME, ecg$ECG, type = "l", col = "red", main = paste(c("ECG: ", nrow(ecg)), collapse = " "))





################£
################£


#df <- data.frame(x=1:5, y=2:6, z=3:7, u=4:8)
#df
t <- ppg[, c("TIME","VALUE")]
t
write.csv(t, "ppgf.csv", row.name=TRUE)

#u <- df[, c("x","y")]
#u
write.csv(ecg, "ecgf.csv", row.name=TRUE)

library('zoo')
#Read CSV data as time-series data
z1<-read.zoo(file="ppgf.csv",sep=",",header=TRUE,tz="",format="%Y-%m-%d %H:%M:%OS")
z2<-read.zoo(file="ecgf.csv",sep=",",header=TRUE,tz="",format="%d/%m/%Y %H:%M:%OS")

#Plot graph
plot.zoo(cbind(z1,z2), plot.type="single", col=c("red","blue"))


################£
################£

#Install package 'zoo'
#Go to 'Packages' in toolbar and select 'Install package(s)'. Select any CRAN mirror and install 'zoo' package.

#Load package 'zoo'
library('zoo')

#Go to directory in which files are stored
#Go to 'File' in toolbar and select 'Change dir'. Select the directory in which you have kept the files.

#Read CSV data as time-series data
z1<-read.zoo(file="a.csv",sep=",",header=TRUE,tz="",format="%m/%d/%Y")
z2<-read.zoo(file="b.csv",sep=",",header=TRUE,tz="",format="%m/%d/%Y")

#In case you do not have headers, specify header=FALSE.
#In case your date format is in D/M/Y, change the format specification accordingly.

#Plot graph
plot.zoo(cbind(z1,z2), plot.type="single", col=c("red","blue"))