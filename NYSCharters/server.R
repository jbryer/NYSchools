require(shiny)
require(shinyIncubator)
require(ggplot2)
require(reshape2)

theme_update(panel.background=element_blank(), 
			 panel.grid.major=element_blank(), 
			 panel.border=element_blank())

text.size <- 3.5

if(file.exists('NYSEnrollment.Rda')) {
	load('NYSEnrollment.Rda')
} else {
	source('dataload.R')
	save(nysenrollment, district.codes, grade.cols, file='NYSEnrollment.Rda')
}

groups <- c('All'='All Students', 
			'Gender'='Gender',
			'Race'='Race/Ethnicity',
			'Economically'='Economically Disadvantaged',
			'LEP'='Limited English Proficiency',
			'SWD'='Students with Disabilities')

number_ticks <- function(n) { function(limits) pretty(limits, n) }

shinyServer(function(input, output) {
	output$table <- renderTable({
	})
	
	getData <- function(input, includeDistrict=FALSE) {
		charters <- nysenrollment[[input$group]]$charter[,
				c('District','DistrictName','SUBGROUP','CHARTER.SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
		publics <- nysenrollment[[input$group]]$publics[,
				c('District','DistrictName','SUBGROUP','SCHOOL.NAME','TOTAL.ENROLLMENT',grade.cols)]
		if(input$group == 'Gender') {
			charters <- charters[charters$SUBGROUP == input$gender,]
			publics <- publics[publics$SUBGROUP == input$gender,]
		}
		if(input$group == 'Race') {
			charters <- charters[charters$SUBGROUP == input$race,]
			publics <- publics[publics$SUBGROUP == input$race,]
		}
		districtName <- 'All Districts'
		if(!is.null(input$district)) {
			if(input$district != 'All') {
				charters <- charters[charters$District == input$district,]
				publics <- publics[publics$District == input$district,]
				districtName <- district.codes[district.codes$Code == input$district,'DistrictName']
			}
		}
		if(!includeDistrict) {
			charters$DistrictName <- NULL
			publics$DistrictName <- NULL
		}
		charters$District <- NULL
		publics$District <- NULL
		charters$SUBGROUP <- NULL
		publics$SUBGROUP <- NULL
		
		charters$Charter <- TRUE
		publics$Charter <- FALSE
		names(charters)[which(names(charters) == 'CHARTER.SCHOOL.NAME')] <- 'SCHOOL.NAME'
		
		return(list(districtName=districtName, charters=charters, publics=publics))
	}
	
	output$plot <- renderPlot({
		thedata <- getData(input)
		charters <- thedata$charters
		publics <- thedata$publics
		districtName <- thedata$districtName
		
		if(input$grade == 'All') {
			thedata <- as.data.frame(rbind(
				apply(publics[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
								 paste0('GRADE.', 1:12))], 2, sum),
				apply(charters[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
								  paste0('GRADE.', 1:12))], 2, sum)
			))
			thedata$Charter <- c('Public', 'Charter')
			thedata.melted <- melt(thedata, id='Charter')
			names(thedata.melted) <- c('Charter','Grade','Enrollment')
			levels(thedata.melted$Grade) <- c('PreK', 'K', 1:12)
			
			p <- ggplot(thedata.melted, aes(x=Grade, group=Charter, fill=Charter, y=Enrollment, 
									  ymax=Enrollment, label=Enrollment)) +
				geom_bar(stat='identity', position='dodge') +
				geom_text(angle=90, position=position_dodge(width=0.9), hjust=1.1, size=text.size) +
				scale_y_continuous(breaks=number_ticks(10))
		} else {
			thedata.melted2 <- melt(rbind(publics, charters)[,-2], id=c('SCHOOL.NAME','Charter'))
			names(thedata.melted2) <- c('School', 'Charter', 'Grade', 'Enrollment')
			levels(thedata.melted2$Grade) <- c('PreK', 'K', 1:12)
			
			if(input$grade == 'Elementary') {
				p <- ggplot(thedata.melted2[thedata.melted2$Grade %in% c('PreK','K',1:5),], 
							aes(x=School, group=Charter, fill=Charter, y=Enrollment)) +
					geom_bar(stat='identity', position='dodge') +
					facet_wrap(~ Grade, nrow=1) + coord_flip()
			} else if(input$grade == 'Middle') {
				p <- ggplot(thedata.melted2[thedata.melted2$Grade %in% c(6:8),], 
							aes(x=School, group=Charter, fill=Charter, y=Enrollment)) +
					geom_bar(stat='identity', position='dodge') +
					facet_wrap(~ Grade, nrow=1) + coord_flip()
			} else if(input$grade == 'High') {
				p <- ggplot(thedata.melted2[thedata.melted2$Grade %in% c(9:12),], 
							aes(x=School, group=Charter, fill=Charter, y=Enrollment)) +
					geom_bar(stat='identity', position='dodge') +
					facet_wrap(~ Grade, nrow=1) + coord_flip()
			}
		}
		
		groupName <- groups[input$group]
		if(input$group == 'Gender') {
			groupName <- paste0(groupName, ': ', input$gender)
		} else if(input$group == 'Race') {
			groupName <- paste0(groupName, ': ', input$race)
		}
		p <- p + ggtitle(paste0('Public/Charter School Enrollment by Grade\n',
								'2012-2013 School Year - ', districtName, '\n',
								groupName))
		print(p)
		
	}, height=400, width=800)
	
	output$summary <- renderTable({
		thedata <- getData(input)
		charters <- thedata$charters
		publics <- thedata$publics
		districtName <- thedata$districtName
		
		thedata <- as.data.frame(cbind(
			Public=apply(publics[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
							 paste0('GRADE.', 1:12))], 2, sum),
			Charter=apply(charters[,c('PRE.K.FULL.DAY','KINDERGARTEN.FULL.DAY.',
							  paste0('GRADE.', 1:12))], 2, sum)
		))
		row.names(thedata) <- c('PreK', 'K', paste0('Grade ', 1:12))
		total <- sum(thedata)
		thedata['Total',] <- c(sum(thedata$Public), sum(thedata$Charter))
		thedata['Percent',] <- c(round(thedata[nrow(thedata),1] / total * 100),
								 round(thedata[nrow(thedata),2] / total * 100))
		thedata$Public <- prettyNum(thedata$Public, big.mark=',')
		thedata$Charter <- prettyNum(thedata$Charter, big.mark=',')
		thedata[nrow(thedata),] <- paste0(thedata[nrow(thedata),], '%')
		return(thedata)
	}, include.rownames=TRUE)
	
	output$data <- renderDataTable({
		thedata <- getData(input, includeDistrict=TRUE)
		charters <- thedata$charters
		publics <- thedata$publics
		districtName <- thedata$districtName
		schools <- rbind(
			charters[,c('SCHOOL.NAME','Charter','DistrictName','TOTAL.ENROLLMENT')],
			publics[,c('SCHOOL.NAME','Charter','DistrictName','TOTAL.ENROLLMENT')]
		)
		schools <- schools[order(schools$SCHOOL.NAME),]
		return(schools)
	})
})
