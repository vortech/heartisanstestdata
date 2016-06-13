# #time_stamp_format = "%Y-%m-%d %H:%M:%OS"
# data <- read.csv("D:\\Dev\\R\\test\\ecgtestmiga.csv",header = TRUE, sep = ",", quote="", dec=".",comment.char="") #ecgtestmiga mitest
# #data$TIME = strptime(data$TIMESTAMP, time_stamp_format)
# data
# #plot(data[,1], data[,2], col="red")
# plot(data$Timestamp, data$ECG, col="red")



# #plot(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$VALUE[lower_index:upper_index]), type="l", xlab='Time', ylab='Absorbed Light', col='blue')	


# # --------------------

# data <- read.csv("D:\\Dev\\R\\test\\ecgtestmiga.csv",header = TRUE, sep = ",", quote="", dec=".",comment.char="")
# size = nrow(data)
# capture.output(cat('size of data: ',size))
# rngX = 500
# rngY = 2000
# data2 = data[rngX:rngY,]
# #plot(data2$Timestamp, data2$ECG, col="red")
# plot(data2$Timestamp, data2$ECG, col="red", xlim = c(500, 2000))


# --------------------
require('pracma')

make_sign <- function(x, bytes){
	if (x > (256^bytes/2-1)) {
		x = x- 256^bytes		
	}
	return (x)
}

extract_signal <- function(row) {
	hex_string = row['PAYLOAD']
	bytes = strsplit(hex_string, ',')

	ppg_adc = make_sign(as.integer(paste(c('0x', bytes[[1]][1:3]), collapse='')), 3) # 3b
	ambient_adc = make_sign(as.integer(paste(c('0x', bytes[[1]][4:6]), collapse='')), 3) # 3b
	signed_ppg = ppg_adc - ambient_adc
	row = as.list(row)
	row['VALUE'] = 256^3-abs(signed_ppg)  #The absolute value respresents the amoutn of light reflected, but what we want is the amount of light being absorbed by the skin
	row['ACC_X'] = make_sign(as.integer(paste(c('0x', bytes[[1]][7:8]), collapse='')), 2) # 2b
	row['ACC_Y'] = make_sign(as.integer(paste(c('0x', bytes[[1]][9:10]), collapse='')), 2) # 2b
	row['ACC_Z'] = make_sign(as.integer(paste(c('0x', bytes[[1]][11:12]), collapse='')), 2) # 2b
	row['ACC_X_Y'] = sqrt(sum(c(row[['ACC_X']], row[['ACC_Y']])^2))
	row['ACC'] = sqrt(sum(c(row[['ACC_X']], row[['ACC_Y']], row[['ACC_Z']])^2))	
	return (row) 
}

plot_analysis <- function(filename='example.csv', start=NA, end=NA) {
	ppg_data = read.csv(filename, colClasses=c("character", "character", "character"))	
	if (is.null(ppg_data$ACC_X)) { # PPG data
		ppg_data = do.call(rbind.data.frame,  apply(ppg_data, 1, extract_signal))
	} else { # ECG data
		ppg_data$VALUE = as.double(ppg_data$VALUE)
	}
	#...
	# Need to cut out the ends as they are distorted by signal processing
	length=nrow(ppg_data)
	lower_index=floor(length*0.1)
	upper_index=floor(length*0.9)
	  
	plot(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$VALUE[lower_index:upper_index]), type="l", xlab='Time', ylab='Absorbed Light', col='blue')	
	  
}

args <- commandArgs(trailingOnly = TRUE)
print(args)
ppg_data = plot_analysis(filename=args[1], start=args[2], end=args[3])
# size 
capture.output(cat('data size: ', nrow(ppg_data)))
