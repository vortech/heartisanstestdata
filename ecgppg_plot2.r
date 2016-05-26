library(RCurl)
library(zoo)

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

# fppg <- getURL("https://raw.githubusercontent.com/vortech/heartisanstestdata/master/TR20160520101713_1002_cut2132ppg.csv")
# ppg <- read.csv(text = fppg)
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002.csv", colClasses=c("character", "character", "character"))
ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_PPG10000.csv",header = TRUE, sep = ",")#ORI
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_cut2132ppg.csv", colClasses=c("character", "character"))
#ppg <- read.csv("D:\\Dev\\R\\test\\TR20160520101713_1002_cut40000ppg.csv", colClasses=c("character", "character"))
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
# fecg <- getURL("https://raw.githubusercontent.com/vortech/heartisanstestdata/master/2016_05_20-09_48_17_ECG2.csv")
# ecg <- read.csv(text = fecg) 
ecg <- read.csv("D:\\Dev\\R\\test\\2016_05_20-09_48_17_ECG10000.csv",header = TRUE, sep = ",", quote="", dec=".")#,comment.char="")
#ecg <- read.csv("D:\\Dev\\R\\test\\2016_05_20-09_48_17_ECG.csv",header = TRUE, sep = ",", quote="", dec=".")#ORI
nrow(ecg)
ecg$TIME <- strptime(ecg[,1], "%d/%m/%Y %H:%M:%OS")
ecgT = ecg[1500:2000,]
plot(ecg$TIME, ecg$ECG, type = "l", col = "red", main = paste(c("ECG: ", nrow(ecg)), collapse = " "))

######################################
######################################
# 
# # sam <- textConnection("time, value
# #                       01:00:52, 256
# #                       01:03:02, 254
# #                       01:05:23, 255
# #                       01:07:42, 257
# #                       01:10:12, 256")
# # cal <- textConnection("time, value
# #                       01:01:02, 252.3
# #                       01:05:15, 249.8
# #                       01:10:02, 255.6")
# # sample <- read.csv(sam)
# # sample$time <- as.POSIXct(sample$time, format="%H:%M:%S")
# # calib <- read.csv(cal)
# # calib$time <- as.POSIXct(calib$time, format="%H:%M:%S")
# # Create zoo objects
# #zc <- zoo(calib$value, calib$time)    # low freq
# 
# zc <- zoo(ppg$VALUE, ppg$TIME)    # low freq 
# aa <- aggregate(zc, index, mean)
# AggHits <- aggregate(TIME ~ ., data = ppg, sum)
# 
# #zs <- zoo(sample$value, sample$time)  # high freq
# zs <- zoo(ecg$VALUE, ecg$TIME)  # high freq
# bb <- aggregate(zs, index, mean)
# # Merge series into one object
# z <- merge(zs,zc)
# # Interpolate calibration data (na.spline could also be used)
# z$zc <- na.approx(z$zc, rule=2)
# # Only keep index values from sample data
# Z <- z[index(zs),]
# plot(Z)

# irregular time points at which data was sampled
t <- c(5,10,15,25,30,40,50)
# measurements 
y <- c(4.3,1.2,5.4,7.6,3.2,1.2,3.7)
f <- approxfun(t,y)
# get interpolated values for time points 5, 20, 35, 50
f(seq(from=5,to=50,by=15))
