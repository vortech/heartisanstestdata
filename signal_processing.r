require('pracma')
library(signal)

time_stamp_format="%Y-%m-%d %H:%M:%OS"
pdf(width=40, height=31.96)
par(mai = rep(1,4), pin = c(39, 30), cex=1)	

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
	row['VALUE'] = 256^3-abs(signed_ppg)     #The absolute value respresents the amoutn of light reflected, but what we want is the amount of light being absorbed by the skin
	row['ACC_X'] = make_sign(as.integer(paste(c('0x', bytes[[1]][7:8]), collapse='')), 2)
	row['ACC_Y'] = make_sign(as.integer(paste(c('0x', bytes[[1]][9:10]), collapse='')), 2)
	row['ACC_Z'] = make_sign(as.integer(paste(c('0x', bytes[[1]][11:12]), collapse='')), 2)
	row['ACC_X_Y'] = sqrt(sum(c(row[['ACC_X']], row[['ACC_Y']])^2))
	row['ACC'] = sqrt(sum(c(row[['ACC_X']], row[['ACC_Y']], row[['ACC_Z']])^2))	
	return (row)
}

plot_analysis <- function(filename='example.csv', start=NA, end=NA) {
	ppg_data=read.csv(filename, colClasses=c("character", "character", "character"))
	if (is.null(ppg_data$ACC_X)) {
		ppg_data=do.call(rbind.data.frame,  apply(ppg_data, 1, extract_signal))
	} else {
		ppg_data$VALUE=as.double(ppg_data$VALUE)
	}

	#Parse the time stamp and filter out by time range
	ppg_data$TIME=strptime(ppg_data$TIMESTAMP, time_stamp_format)
 	if (!is.na(start)) ppg_data = subset(ppg_data, TIME > strptime(start, time_stamp_format))   #Example TIMESTAMP '2016-03-18 10:33:00.00'
 	if (!is.na(end)) ppg_data =subset(ppg_data, TIME < strptime(end, time_stamp_format))
 	if (!is.na(start) | !is.na(end)) write.csv(ppg_data[,c('TIMESTAMP', 'PAYLOAD', 'VALUE', 'ACC')], file = paste("PPG", start, end, ".csv"))

	# Need to cut out the ends as they are distorted by signal processing
	length=nrow(ppg_data)
	lower_index=floor(length*0.1)
	upper_index=floor(length*0.9)

	# Apply Savitzky-Golay Smoothing
	ppg_data$SMOOTHED_VALUE = savgol(ppg_data$VALUE, 71)
	# Remove the DC shift
	ppg_data$PLUSE_WAVE = filter(butter(2, 1/100, type="high"), ppg_data$SMOOTHED_VALUE)

	plot(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$VALUE[lower_index:upper_index]), type="l", xlab='Time', ylab='Absorbed Light', col='blue')	
	lines(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$SMOOTHED_VALUE[lower_index:upper_index]), col='green')		
	lines(ppg_data$TIME, ppg_data$PLUSE_WAVE, col='red')	
	lines(ppg_data$TIME, detrend(ppg_data$ACC)*2*10^2-50000, col=adjustcolor('cyan', alpha.f=0.8))			

	plot(ppg_data$TIME[lower_index:upper_index], ppg_data$PLUSE_WAVE[lower_index:upper_index], type="l", xlab='Time', ylab='Absorbed Light', col='red')	
	lines(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$ACC[lower_index:upper_index])*1*10^2, col=adjustcolor('black', alpha.f=0.9))	

	plot(ppg_data$TIME, detrend(ppg_data$ACC_X)*5*10^2, type="l", col='cyan', lwd=1, ylim=c(-100000, 100000))			
	lines(ppg_data$TIME, detrend(ppg_data$ACC_Y)*5*10^2, col='orange', lwd=1)			
	lines(ppg_data$TIME, detrend(ppg_data$ACC_Z)*5*10^2, col='black', lwd=1)			

	# Extract the RR Interval
	R_Peaks = extract_R_Peak(ppg_data)
	RRI=ppg_data$TIME[R_Peaks]
	print(RRI)

	plot(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$SMOOTHED_VALUE[lower_index:upper_index]),  type="l", xlab='Time', ylab='Absorbed Light', col='green')		
	lines(ppg_data$TIME, ppg_data$PLUSE_WAVE, col='red')			
	points( ppg_data$TIME[R_Peaks], ppg_data$PLUSE_WAVE[R_Peaks], pch=8)		
	grid()

	return (ppg_data)
}

extract_R_Peak <- function(ppg_data) {
	n = nrow(ppg_data)
	y=ppg_data$PLUSE_WAVE
	t=ppg_data$TIME
	peaks = y[2:(n-1)] > y[1:(n-2)] & y[2:(n-1)] > y[3:n]				#This is when the window points are 1 step apart
	troughs = y[2:(n-1)] < y[1:(n-2)] & y[2:(n-1)] < y[3:n]			
	flat_peaks=(y[2:(n-1)] == y[1:(n-2)] & y[2:(n-1)] > y[3:n]) | (y[2:(n-1)] > y[1:(n-2)] & y[2:(n-1)] == y[3:n])
	flat_troughs=(y[2:(n-1)] == y[1:(n-2)] & y[2:(n-1)] < y[3:n]) | (y[2:(n-1)] < y[1:(n-2)] & y[2:(n-1)] == y[3:n])		

	# Need to cut out the ends as they are distorted by signal processing
	length=nrow(ppg_data)
	lower_index=floor(length*0.1)
	upper_index=floor(length*0.9)
	plot(ppg_data$TIME[lower_index:upper_index], detrend(ppg_data$SMOOTHED_VALUE[lower_index:upper_index]), type="l", xlab='Time', ylab='Reflected Light', col='green')		
	lines(ppg_data$TIME[lower_index:upper_index], ppg_data$PLUSE_WAVE[lower_index:upper_index], col='red')			
	points( ppg_data$TIME[lower_index:upper_index][which(peaks[lower_index:upper_index])], ppg_data$PLUSE_WAVE[lower_index:upper_index][peaks[lower_index:upper_index]], pch=8)		
	points( ppg_data$TIME[lower_index:upper_index][which(troughs[lower_index:upper_index])], ppg_data$PLUSE_WAVE[lower_index:upper_index][troughs[lower_index:upper_index]], pch=20)		
	points( ppg_data$TIME[lower_index:upper_index][which(flat_peaks[lower_index:upper_index])], ppg_data$PLUSE_WAVE[lower_index:upper_index][flat_peaks[lower_index:upper_index]], pch=12)		
	points( ppg_data$TIME[lower_index:upper_index][which(flat_troughs[lower_index:upper_index])], ppg_data$PLUSE_WAVE[lower_index:upper_index][flat_troughs[lower_index:upper_index]], pch=13)		
	grid()

	#We need to add 1 to the index because the actual peak or trough is 1 position behind the Boolean that was detected earlier
	peaks_index=which(peaks | flat_peaks)+1
	troughs_index=which(troughs | flat_troughs)+1   

	is_first_peak = peaks_index[1] < troughs_index[1]
	more_peaks= length(peaks_index) > length(troughs_index)
	same_lengths = length(troughs_index) == length(peaks_index)

	#Make sure the series starts and end with a trough
	if (more_peaks) {
		peaks_index=peaks_index[c(-1, -length(peaks_index))]
	}
	if (same_lengths) {
		if (is_first_peak) peaks_index=peaks_index[-1]
		else peaks_index=peaks_index[-length(peaks_index)]
	}

	#Calculate the peak properties
	t2p_amplitudes = abs(y[troughs_index[-length(troughs_index)]] - y[peaks_index])
	p2t_amplitudes = abs(y[peaks_index] - y[troughs_index[-1]])
	t2p_durations = t[peaks_index] -t[troughs_index[-length(troughs_index)]] 
	p2t_durations = t[troughs_index[-1]] -t[peaks_index]

	t2p_amplitude_ok = t2p_amplitudes > 500 & t2p_amplitudes < 50000
	p2t_amplitude_ok = p2t_amplitudes > 500 & p2t_amplitudes < 50000
	t2p_durations_ok = t2p_durations > 0.1 & t2p_durations < 0.7
	p2t_durations_ok = p2t_durations > 0.1 & p2t_durations < 1.5

	# Remove all the peaks that are abnormal
	peaks_index = peaks_index[t2p_amplitude_ok & p2t_amplitude_ok & t2p_durations_ok & p2t_durations_ok]
	return (peaks_index)
}


args <- commandArgs(trailingOnly = TRUE)
print(args)
ppg_data=plot_analysis(filename=args[1], start=args[2], end=args[3])
# R_Peaks=extract_R_Peak(ppg_data)
