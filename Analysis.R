source('package.R')
package(c('ggplot2','reshape2','psych','Hmisc','shiny','xtable'))

# To run locally (if the entire repository has been downloaded):
shiny::runApp('NYSReportCard')
shiny::runApp('NYSEnrollment')

# Or run from Github
shiny::runGitHub('NYSchools','jbryer',subdir='NYSReportCard')
shiny::runGitHub('NYSchools','jbryer',subdir='NYSEnrollment')

# Data preparation. This will download some large data files from NYSED.gov
# website and create Rdata files in each of the Shiny app directories.
source('DataPrep.R')

################################################################################
# Analysis of the differences between 2012 and 2013 ELA and Math school outcomes
load('NYSReportCard/NYSReportCardCache.Rda')
source('NYSReportCard/reportCard.R')

se <- function(x) { sqrt(var(x)/length(x)) }

# Create a table with results of each residual analysis
tabout <- data.frame()
for(subject in c('ELA','Math')) {
	for(grade in 3:8) {
		thedata <- reportCard(subject, grade)
		
		r <- cor(thedata[,'Pass2012'], thedata[,'Pass2013'])
		lm.out <- lm(Pass2013 ~ Pass2012, data=thedata, weights=thedata[,'TotalTested'])
		lm.sum <- summary(lm.out)
		thedata$resid <- resid(lm.out)
		t.out <- t.test(resid ~ Charter, data=thedata)
		lm2.out <- lm(Pass2013 ~ I(Pass2012 ^ 2), data=thedata, weights=thedata[,'TotalTested'])
		lm2.sum <- summary(lm2.out)
		thedata$resid2 <- resid(lm2.out)
		t2.out <- t.test(resid2 ~ Charter, data=thedata)
		
		tabout <- rbind(tabout, data.frame(
			subject=subject, 
			grade=grade, 
			r=r, 
			r.squared=lm.sum$r.squared,
			public.resid=unname(t.out$estimate['mean in group FALSE']),
			charter.resid=unname(t.out$estimate['mean in group TRUE']),
			diff=unname(diff(t.out$estimate)),
			p=t.out$p.value,
			r.squared.quad=lm2.sum$r.squared,
			public.resid.quad=unname(t2.out$estimate['mean in group FALSE']),
			charter.resid.quad=unname(t2.out$estimate['mean in group TRUE']),
			diff.quad=unname(diff(t2.out$estimate)),
			p.quad=t2.out$p.value,
			stringsAsFactors=FALSE))
	}
}

# Linear models
tabout[,c('subject','grade','r','r.squared','public.resid','charter.resid','diff','p')]

# Quadratic models
tabout[,c('subject','grade','r.squared.quad','public.resid.quad',
		  'charter.resid.quad','diff.quad','p.quad')]

names(nysrc2012)
names(nysrc2013)

ela7 <- reportCard('ELA', 7)
head(ela7)

cor(ela7$Pass2013, ela7$Pass2012, use='complete.obs')

ela7.lm.out <- lm(Pass2013 ~ Pass2012, data=ela7, weights=ela7$TotalTested)
summary(ela7.lm.out) 

ela7.lm2.out <- lm(Pass2013 ~ I(Pass2012 ^ 2), data=ela7, weights=ela7$TotalTested)
summary(ela7.lm2.out)

ggplot(ela7, aes(x=Pass2012, y=Pass2013)) + 
	geom_point(data=ela7[!ela7$Charter,], aes(color=Charter), alpha=.3) + 
	geom_smooth(method='lm', formula=y~poly(x,2,raw=TRUE)) +
	geom_point(data=ela7[ela7$Charter,], aes(color=Charter), alpha=1, size=2) +
	xlab('Percent Pass 2012') + ylab('Percent Pass 2013') + coord_equal()

ela7$resid <- resid(ela7.lm.out)
ela7$resid2 <- resid(ela7.lm2.out)

mean(ela7$resid); se(ela7$resid)
ggplot(ela7, aes(x=resid, color=Charter)) + geom_density()

mean(ela7$resid2); se(ela7$resid2)
ggplot(ela7, aes(x=resid2, color=Charter)) + geom_density()

t.test(resid ~ Charter, data=ela7)
t.test(resid2 ~ Charter, data=ela7)

# Boxplots of the residuals. Note that each school is weighted equally here
ggplot(ela7, aes(y=resid, x=Charter, color=Charter)) + 
	geom_boxplot() + 
	geom_hline(yintercept=0, color='blue') +
	ylab('Residual')

ggplot(ela7, aes(y=resid2, x=Charter, color=Charter)) + 
	geom_boxplot() + 
	geom_hline(yintercept=0, color='blue') +
	ylab('Residual')


################################################################################
# New York State 2013 PreK-12 School Enrollments

load('NYSCharters/NYSEnrollment.Rda')
names(nysenrollment)

district.name <- 'Albany City SD'

all.charters <- nysenrollment[['All']]$charter[, c('District','DistrictName',
							'SUBGROUP','CHARTER.SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
all.publics <- nysenrollment[['All']]$publics[, c('District','DistrictName',
							'SUBGROUP','SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
swd.charters <- nysenrollment[['SWD']]$charter[, c('District','DistrictName',
							'SUBGROUP','CHARTER.SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
swd.publics <- nysenrollment[['SWD']]$publics[, c('District','DistrictName',
							'SUBGROUP','SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
lep.charters <- nysenrollment[['LEP']]$charter[, c('District','DistrictName',
							'SUBGROUP','CHARTER.SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
lep.publics <- nysenrollment[['LEP']]$publics[, c('District','DistrictName',
							'SUBGROUP','SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]

all.charters <- all.charters[which(all.charters$DistrictName == district.name),]
all.publics <- all.publics[which(all.publics$DistrictName == district.name),]
swd.charters <- swd.charters[which(swd.charters$DistrictName == district.name),]
swd.publics <- swd.publics[which(swd.publics$DistrictName == district.name),]
lep.charters <- lep.charters[which(swd.charters$DistrictName == district.name),]
lep.publics <- lep.publics[which(swd.publics$DistrictName == district.name),]

thedata <- as.data.frame(rbind(
	c(Subgroup='All', apply(all.publics[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
					 paste0('GRADE.', 1:12))], 2, sum)),
	c(Subgroup='All', apply(all.charters[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
					  paste0('GRADE.', 1:12))], 2, sum)),
	c(Subgroup='SWD', apply(swd.publics[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
								  paste0('GRADE.', 1:12))], 2, sum)),
	c(Subgroup='SWD', apply(swd.charters[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
								   paste0('GRADE.', 1:12))], 2, sum)),
	c(Subgroup='LEP', apply(lep.publics[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
										   paste0('GRADE.', 1:12))], 2, sum)),
	c(Subgroup='LEP', apply(lep.charters[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
											paste0('GRADE.', 1:12))], 2, sum))	
))
thedata$Charter <- rep(c('Public', 'Charter'), 3)
thedata.melted <- melt(thedata, id=c('Charter','Subgroup'))
names(thedata.melted) <- c('Charter','Subgroup','Grade','Enrollment')
levels(thedata.melted$Grade) <- c('PreK', 'K', 1:12)
thedata.melted$Enrollment <- as.integer(thedata.melted$Enrollment)
thedata.melted$Subgroup <- factor(thedata.melted$Subgroup, levels=c('All','SWD','LEP'),
	 	labels=c('All Students','Students with Disabilities','Limited English Proficiency'))
number_ticks <- function(n) { function(limits) pretty(limits, n) }

ggplot(thedata.melted, aes(x=Grade, group=Charter, fill=Charter, y=Enrollment, 
								ymax=Enrollment, label=Enrollment)) +
	geom_bar(stat='identity', position='dodge') +
	geom_text(angle=90, position=position_dodge(width=0.9), hjust=1.1, size=2.5) +
	scale_y_continuous(breaks=number_ticks(10)) +
	facet_wrap(~ Subgroup, ncol=1, scales='free_y')


charters <- nysenrollment[['All']]$charter[,
		c('District','DistrictName','SUBGROUP','CHARTER.SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
publics <- nysenrollment[['All']]$publics[,
		c('District','DistrictName','SUBGROUP','SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
charters <- charters[which(charters$DistrictName == district.name),]
publics <- publics[which(publics$DistrictName == district.name),]
charters$Charter <- TRUE
publics$Charter <- FALSE
names(charters)[which(names(charters) == 'CHARTER.SCHOOL.NAME')] <- 'SCHOOL.NAME'
charters$DistrictName <- NULL
publics$DistrictName <- NULL
charters$District <- NULL
publics$District <- NULL
charters$SUBGROUP <- NULL
publics$SUBGROUP <- NULL

thedata.melted2 <- melt(thedata, id=c('SCHOOL.NAME','Charter'))
names(thedata.melted2) <- c('School', 'Charter', 'Grade', 'Enrollment')
levels(thedata.melted2$Grade) <- c('PreK', 'K', 1:12)

tmp <- thedata.melted2[thedata.melted2$Grade %in% c('PreK','K',1:5),]
tmp <- aggregate(tmp$Enrollment, by=list(tmp$School), FUN=sum)
tmp <- tmp[tmp$x > 0,]$Group.1
ggplot(thedata.melted2[thedata.melted2$Grade %in% c('PreK','K',1:5) &
					   thedata.melted2$School %in% tmp,], 
	   aes(x=School, group=Charter, fill=Charter, y=Enrollment)) +
	geom_bar(stat='identity', position='dodge') +
	facet_wrap(~ Grade, nrow=1) + coord_flip()

tmp <- thedata.melted2[thedata.melted2$Grade %in% c(6:8),]
tmp <- aggregate(tmp$Enrollment, by=list(tmp$School), FUN=sum)
tmp <- tmp[tmp$x > 0,]$Group.1
ggplot(thedata.melted2[thedata.melted2$Grade %in% c(6:8) & 
					   thedata.melted2$School %in% tmp,], 
	   aes(x=School, group=Charter, fill=Charter, y=Enrollment)) +
	geom_bar(stat='identity', position='dodge') +
	facet_wrap(~ Grade, nrow=1) + coord_flip()

tmp <- thedata.melted2[thedata.melted2$Grade %in% c(9:12),]
tmp <- aggregate(tmp$Enrollment, by=list(tmp$School), FUN=sum)
tmp <- tmp[tmp$x > 0,]$Group.1
ggplot(thedata.melted2[thedata.melted2$Grade %in% c(9:12) &
					   thedata.melted2$School %in% tmp,], 
	   aes(x=School, group=Charter, fill=Charter, y=Enrollment)) +
	geom_bar(stat='identity', position='dodge') +
	facet_wrap(~ Grade, nrow=1) + coord_flip()


