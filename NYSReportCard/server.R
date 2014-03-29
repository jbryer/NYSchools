source('reportCard.R')

require(shiny)
require(shinyIncubator)
require(ggplot2)

theme_update(panel.background=element_blank(), 
			 panel.grid.major=element_blank(), 
			 panel.border=element_blank())

shinyServer(function(input, output) {
	getData <- function(input) {
		pass <- 3
		if(!is.null(input$passlevel)) {
			pass <- as.integer(input$passlevel)
		}
		suppressWarnings(rc <- reportCard(input$subject, input$grade, pass=pass))
		if(input$county != 'All') {
			rc <- rc[rc$County == input$county,]
		}
		return(rc)
	}
	
	getModel <- function(input, rc) {
		if(input$outcome == 'Mean') {
			if(input$model == 'Linear') {
				lm.out <- lm(Mean2013 ~ Mean2012, data=rc, weights=rc$TotalTested)
			} else {
				lm.out <- lm(Mean2013 ~ I(Mean2012 ^ 2), data=rc, weights=rc$TotalTested)
			}
		} else {
			if(input$model == 'Linear') {
				lm.out <- lm(Pass2013 ~ Pass2012, data=rc, weights=rc$TotalTested)
			} else {
				lm.out <- lm(Pass2013 ~ I(Pass2012 ^ 2), data=rc, weights=rc$TotalTested)
			}
		}
		
	}
	
	output$table <- renderDataTable({
		getData(input)
	})
	
	output$county <- renderText({
		input$county
	})
	
	output$plot <- renderPlot({
		rc <- getData(input)
		if(input$outcome == 'Mean') {
			p <- ggplot(rc, aes(x=Mean2012, y=Mean2013, color=Charter)) + 
				geom_point(data=rc[!rc$Charter,], aes(size=TotalTested), alpha=.3)
			if(nrow(rc[rc$Charter,]) > 0) {
				p <- p + geom_point(data=rc[rc$Charter,], alpha=1, size=2)
			}
			p <- p + xlab('Mean Score 2012') + ylab('Mean Score 2013')
		} else {
			p <- ggplot(rc, aes(x=Pass2012, y=Pass2013)) + 
				geom_point(data=rc[!rc$Charter,], aes(color=Charter), alpha=.3)
			if(nrow(rc[rc$Charter,]) > 0) {
				p <- p + geom_point(data=rc[rc$Charter,], aes(color=Charter), alpha=1, size=2)
			}
			p <- p + xlab('Percent Pass 2012') + ylab('Percent Pass 2013') + coord_equal()
			p <- p + xlim(c(0,100)) + ylim(c(0,100))
		}
		if(input$model == 'Linear') {
			p <- p + geom_smooth(method='lm', formula=y~x, fill=NA)
		} else {
			p <- p + geom_smooth(method='lm', formula=y~poly(x,2,raw=TRUE), fill=NA)
		}
		p <- p + ggtitle(paste0('Grade ', input$grade, ' ', input$subject))
		if(!is.null(input$school)) {
			if(input$school != 'None') {
				sc <- rc[rc$School == input$school,]
				p <- p + geom_point(data=sc, size=4, color='red')
	# 			p <- p + geom_text(data=sc, aes(label=strwrap(School, width=15)), 
	# 							   color='red', vjust=-1, size=2)
			}
		}
		print(p)
		
	}, height='auto', width='auto')
	
	output$model <- renderPrint({
		rc <- getData(input)
		lm.out <- getModel(input, rc)
		summary(lm.out)
	})
	
	output$residuals <- renderPrint({
		rc <- getData(input)
		lm.out <- getModel(input, rc)
		rc$resid <- resid(lm.out)
		t.test(resid ~ Charter, data=rc)
	})
	
	output$schools <- renderUI({
		rc <- getData(input)
		sc <- unique(rc$School)
		sc <- sc[order(sc)]
		selectInput(input = 'school', label = 'School:',
					choices = c(' ' = 'None', sc))
	})
})
