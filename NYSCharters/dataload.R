require(gdata)

path <- 'Data/'

nysenrollment <- list(
	All=list(# All Students
		charters = read.xls(paste0(path, '2013-Charters_All_Students.xls')),
		publics = read.xls(paste0(path, '2013-Public_Enrollment_All_Students.xls'))
	),
	Gender=list(# Gender
		charters = read.xls(paste0(path, '2013-Charters_Gender.xls')),
		publics = read.xls(paste0(path, '2013-Public_Enrollment_Gender.xls'))
	),
	Race=list(# Race/Ethnicity
		charters = read.xls(paste0(path, '2013-Charters_Race_Ethnicity.xls')),
		publics = read.xls(paste0(path, '2013-Public_Enrollment_Race_Ethnicity.xls'))
	),
	Economically=list(# Economically Disadvantages
		charters = read.xls(paste0(path, '2013-Charters_Econ_Disad_Supressed.xls')),
		publics = read.xls(paste0(path, '2013-Public_Enrollment_Econ_Disad.xls'))
	),
	LEP=list(# Limited English Proficiency
		charters = read.xls(paste0(path, '2013-Charters_LEP_Supressed.xls')),
		publics = read.xls(paste0(path, '2013-Public_Enrollment_LEP.xls'))
	),
	SWD=list(# Students with Disabilities
		charters = read.xls(paste0(path, '2013-Charters_SWDs_Supressed.xls')),
		publics = read.xls(paste0(path, '2013-Public_Enrollment_SWD.xls'))
	)
)

district.codes <- read.fwf(paste0(path, '../District.txt'), 
						   widths=c(6, -3, 100), header=FALSE,
						   col.names=c('Code','DistrictName'),
						   stringsAsFactors=FALSE, 
						   colClasses='character',
						   comment.char='')

grade.cols <- c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',paste0('GRADE.', 1:12))

for(gr in seq_along(nysenrollment)) {
	charters <- nysenrollment[[gr]]$charters
	publics <- nysenrollment[[gr]]$publics
	
	# Set any suppressed cells (i.e. fewer than 5 students) to 0
	for(i in c('TOTAL.ENROLLMENT', grade.cols)) {
		charters[charters[,i] == 'S',i] <- 0
		publics[publics[,i] == 'S',i] <- 0
		charters[,i] <- as.integer(charters[,i])
		publics[,i] <- as.integer(publics[,i])
	}
	
	charters[,'BEDS.CODE'] <- format(charters[,'BEDS.CODE'], width=12, nsmall=0, zero.print='0')
	charters[,'BEDS.CODE'] <- gsub(' ', '0', charters[,'BEDS.CODE'], fixed=TRUE)
	publics[,'BEDS.CODE'] <- format(publics[,'BEDS.CODE'], width=12, nsmall=0, zero.print='0')
	publics[,'BEDS.CODE'] <- gsub(' ', '0', publics[,'BEDS.CODE'], fixed=TRUE)
	
	charters$District <- substr(charters[,'BEDS.CODE'], 1, 6)
	publics$District <- substr(publics[,'BEDS.CODE'], 1, 6)
	
	charters <- merge(charters, district.codes, by.x='District', by.y='Code', all.x=TRUE)
	publics <- merge(publics, district.codes, by.x='District', by.y='Code', all.x=TRUE)
	
	nysenrollment[[gr]]$charters <- charters
	nysenrollment[[gr]]$publics <- publics
}
