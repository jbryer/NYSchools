require(shiny)
require(shinyIncubator)
require(ggplot2)
require(reshape2)

load('NYSEnrollment.Rda')

tmp <- nysenrollment[['All']]$charter
charterDistricts <- tmp[!duplicated(tmp$District),c('District','DistrictName')]
districts <- charterDistricts$District
names(districts) <- charterDistricts$DistrictName
rm(tmp)

shinyUI(pageWithSidebar(
	# Application title
	headerPanel("New York State 2013 PreK-12 School Enrollments"),
	
	sidebarPanel(
		helpText(paste0('')),
		selectInput(inputId = "group", label = "Grouping:",
					choices = c('All Students'='All', 
 								'Gender'='Gender',
 								'Race/Ethnicity'='Race',
								'Economically Disadvantaged'='Economically',
								'Limited English Proficiency'='LEP',
								'Students with Disabilities'='SWD'), 
					selected = 'All'),
		conditionalPanel(
			"input.group == 'Gender'",
			selectInput(inputId='gender', label='Gender',
						choices=unique(nysenrollment[['Gender']]$charters$SUBGROUP))
		),
		conditionalPanel(
			"input.group == 'Race'",
			selectInput(inputId='race', label='Race/Ethnicity',
						choices=unique(nysenrollment[['Race']]$charters$SUBGROUP))
		),
		selectInput(input = 'grade', label = 'Grade Level:',
					choices = c('All Grades' = 'All',
								'Elementary' = 'Elementary',
								'Middle School' = 'Middle',
								'High School' = 'High')),
		selectInput(input='district', label='District:',
			choices = c('All Districts' = 'All', districts)),
		br()
	),
	
	mainPanel(
		tabsetPanel(
			tabPanel("Plot",
					 plotOutput("plot", height='600px')
			),
			tabPanel("Summary",
					 tableOutput('summary')),
			tabPanel("Data",
					 dataTableOutput("data")),
			tabPanel("About",
					 includeMarkdown('About.md'))
		)
	)
))
