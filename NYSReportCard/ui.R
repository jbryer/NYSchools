source('reportCard.R')

require(shiny)
require(shinyIncubator)
require(ggplot2)

shinyUI(pageWithSidebar(
	# Application title
	headerPanel("New York State 2012 vs. 2013 ELA and Math Comparisons"),
	
	sidebarPanel(
		helpText(paste0('')),
		selectInput(inputId = "subject", label = "Subject:",
					choices = c('ELA', 'Math'), selected = 'ELA'),
		selectInput(input = 'grade', label = 'Grade:',
					choices = 3:8, selected = 8),
		radioButtons(input = 'outcome', label = 'Outcome:',
					 choices = c('Passing' = 'Pass',
					 			 'Mean' = 'Mean'),
					 selected='Passing'),
		conditionalPanel(
			"input.outcome == 'Pass'",
			sliderInput(inputId='passlevel', label='Passing Threshold:',
						min=2, max=4, step=1, value=3)
		),
		radioButtons(input = 'model', label='Model Fit:',
					 choices = c('Linear' = 'Linear',
					 			 'Quadratic' = 'Quadratic')),
		selectInput(input = 'county', label = 'County:',
					choices = c('All' = 'All', counties)),
		uiOutput('schools'),
		br()
	),
	
	mainPanel(
		tabsetPanel(
			tabPanel("Plot",
					 plotOutput("plot")
			),
			tabPanel("Model",
					 verbatimTextOutput("model"),
					 br(),
					 "Independent sample t-test of the residuals",
					 verbatimTextOutput("residuals")),
			tabPanel("Data",
					 dataTableOutput("table")),
			tabPanel("About",
					 includeMarkdown('About.md'))
		)
	)
))
