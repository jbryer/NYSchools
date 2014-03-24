require(Hmisc)

if(!exists('nysrc2012') | !exists('nysrc2013')) {
	if(exists('Data/NYSReportCardCache.Rda')) {
		load('Data/NYSReportCardCache.Rda')
	} else {
		# NYS Report Card Database https://reportcards.nysed.gov/
		nysrc2012 <- mdb.get('Data/2012SRC20140227.mdb')
		# ELA and Math scores for 2013 http://www.p12.nysed.gov/irs/pressRelease/20130807/home.html
		nysrc2013 <- mdb.get('Data/2013ELAandMathDistrictandBuildingAggregatesCountyMediaVs2003.mdb')
		save(nysrc2012, nysrc2013, file='Data/NYSReportCardCache.Rda')
	}	
}


schools <- unique(nysrc2013[[2]][,'NAME'])
districts <- unique(nysrc2013[[2]][,'DISTRICT.N'])
boces <- unique(nysrc2013[[2]][,'BOCES.NAME'])
counties <- unique(nysrc2013[[2]][,'COUNTY'])

#' 
#' @param subject either ELA or Math.
#' @param grade integer between 3 and 8
#' @param pass integer between 1 and 4 that indicates the threshold for passing.
#'        Default is 3 so levels 3 and 4 are considered "passing."
reportCard <- function(subject, grade, pass=3) {
	stopifnot(pass >= 0 & pass <= 4)
	
	rc.2012 <- nysrc2012[[paste0(subject, grade, ' Subgroup Results')]]
	rc.2013 <- nysrc2013[[2]]
	rc.2013 <- rc.2013[rc.2013$ITEM.DESC == paste0('Grade ', grade, ' ', subject),]
	
	rc.2012 <- rc.2012[rc.2012$SUBGROUP.NAME == 'All Students',]
	rc.2012 <- rc.2012[rc.2012$YEAR == 2012,]
	
	# Format the school codes to be 12 charaters
	rc.2012$ENTITY.CD <- format(rc.2012$ENTITY.CD, width=12, nsmall=0, zero.print='0')
	rc.2012$ENTITY.CD <- gsub(' ', '0', rc.2012$ENTITY.CD, fixed=TRUE)
	rc.2012$charter <- substr(rc.2012$ENTITY.CD, 7, 8) == '86'
	
	rc.2013$BEDSCODE <- format(rc.2013$BEDSCODE, width=12, nsmall=0, zero.print='0')
	rc.2013$BEDSCODE <- gsub(' ', '0', rc.2013$BEDSCODE, fixed=TRUE)
	rc.2013$charter <- substr(rc.2013$BEDSCODE, 7, 8) == '86'
	
	#Remove the aggregate rows
	rc.2012 <- rc.2012[substr(rc.2012$ENTITY.CD, 9, 12) != '0000' & #Districts
						   	substr(rc.2012$ENTITY.CD, 1, 2) != '00' &    #Other aggregates
						   	substr(rc.2012$ENTITY.CD, 9, 12) != '0999',] #Out of district
	
	rc.2013 <- rc.2013[substr(rc.2013$BEDSCODE, 9, 12) != '0000' & #Districts
						   	substr(rc.2013$BEDSCODE, 1, 2) != '00' &    #Other aggregates
						   	substr(rc.2013$BEDSCODE, 9, 12) != '0999',] #Out of district
	
	for(i in 1:4) {
		rc.2012[,paste0('LEVEL', i, '..TESTED')] <- as.integer(rc.2012[,paste0('LEVEL', i, '..TESTED')])
		rc.2012[is.na(rc.2012[,paste0('LEVEL', i, '..TESTED')]), paste0('LEVEL', i, '..TESTED')] <- 0
		rc.2013[,paste0('P', i)] <- as.integer(rc.2013[,paste0('P', i)])
		rc.2013[is.na(rc.2013[,paste0('P', i)]), paste0('P', i)] <- 0
	}
	
	#Percet "passing" defined to be getting a 3 or 4
	if(pass == 4) {
		rc.2012$Pass2012 <- rc.2012[,'LEVEL4..TESTED']
	} else {
		rc.2012$Pass2012 <- apply(rc.2012[,paste0('LEVEL', pass:4, '..TESTED')], 1, sum)
	}
	if(pass == 4) {
		rc.2013$Pass2013 <- rc.2013$P4
	} else {
		rc.2013$Pass2013 <- apply(rc.2013[,paste0('P', pass:4)], 1, sum)
	}
	
	rc.2012 <- rc.2012[,c('ENTITY.CD','ENTITY.NAME','NUM.TESTED','MEAN.SCORE','Pass2012','charter')]
	rc.2013 <- rc.2013[,c('BEDSCODE','ITEM.DESC','COUNTY','BOCES.NAME','NTEST','NMEAN','Pass2013')]
	
	names(rc.2012) <- c('BEDSCODE','School','NumTested2012','Mean2012','Pass2012','Charter')
	names(rc.2013) <- c('BEDSCODE','GradeSubject','County','BOCES','NumTested2013','Mean2013','Pass2013')
	
	rc <- merge(rc.2012, rc.2013, by='BEDSCODE')
	
	rc$Mean2012 <- as.numeric(rc$Mean2012)
	rc$Mean2013 <- as.numeric(rc$Mean2013)
	rc$NumTested2012 <- as.integer(rc$NumTested2012)
	rc$NumTested2013 <- as.integer(rc$NumTested2013)
	rc$TotalTested <- rc$NumTested2012 + rc$NumTested2013
	
	# Remove any rows with missing values
	# Missing values are mostly due to there being fewer then 5 students tested
	rc <- rc[complete.cases(rc[,c('Mean2012','Mean2013','Pass2012','Pass2013')]),]
	
	return(rc)
}
