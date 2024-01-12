## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  out.width = "100%"
)

## ----shiny, eval=FALSE--------------------------------------------------------
#  library(mirai)
#  library(shiny)
#  library(ggplot2)
#  library(aRtsy)
#  
#  run_task <- function() {
#    Sys.sleep(5L)
#    list(
#      colors = aRtsy::colorPalette(name = "random", n = 3),
#      angle = runif(n = 1, min = - 2 * pi, max = 2 * pi),
#      size = 1,
#      p = 1
#    )
#  }
#  
#  plot_result <- function(result) {
#    do.call(what = canvas_phyllotaxis, args = result)
#  }
#  
#  status_message <- function(tasks) {
#    if (tasks == 0L) {
#      "All tasks completed."
#    } else {
#      sprintf("%d task%s in progress at %s", tasks, if (tasks > 1L) "s" else "", format.POSIXct(Sys.time()))
#    }
#  }
#  
#  ui <- fluidPage(
#    actionButton("task", "Submit a task (5 seconds)"),
#    textOutput("status"),
#    plotOutput("result")
#  )
#  
#  server <- function(input, output, session) {
#    # reactive values and outputs
#    reactive_result <- reactiveVal(ggplot())
#    reactive_status <- reactiveVal("No task submitted yet.")
#    output$result <- renderPlot(reactive_result(), height = 600, width = 600)
#    output$status <- renderText(reactive_status())
#    poll_for_results <- reactiveVal(FALSE)
#  
#    # mirai setup - 5 local daemons with dispatcher
#    daemons(5L)
#    onStop(function() daemons(0L))
#    q <- list()
#  
#    # button to submit a task
#    observeEvent(input$task, {
#      q[[length(q) + 1L]] <<- mirai(run_task(), run_task = run_task)
#      poll_for_results(TRUE)
#    })
#  
#    # event loop to collect finished tasks
#    observe({
#      req(poll_for_results())
#      invalidateLater(millis = 250)
#      if (length(q)) {
#        if (!unresolved(q[[1L]])) {
#          reactive_result(plot_result(q[[1L]][["data"]]))
#          q[[1L]] <<- NULL
#        }
#        reactive_status(status_message(length(q)))
#      } else {
#        poll_for_results(FALSE)
#      }
#    })
#  }
#  
#  shinyApp(ui = ui, server = server)

## ----shinypromises, eval=FALSE------------------------------------------------
#  library(shiny)
#  library(promises) # for promise pipe
#  
#  daemons(4L) # handle 4 simulateneous computes
#  
#  ui <- fluidPage(
#    fluidRow(
#      plotOutput("one"),
#      plotOutput("two"),
#    ),
#    fluidRow(
#      plotOutput("three"),
#      plotOutput("four"),
#    )
#  )
#  
#  make_plot <- function(time) {
#    Sys.sleep(time)
#    runif(10)
#  }
#  
#  args <- list(make_plot = make_plot, time = 2)
#  
#  server <- function(input, output, session) {
#    output$one <- renderPlot(mirai(make_plot(time), .args = args) %...>% plot())
#    output$two <- renderPlot(mirai(make_plot(time), .args = args) %...>% plot())
#    output$three <- renderPlot(mirai(make_plot(time), .args = args) %...>% plot())
#    output$four <- renderPlot(mirai(make_plot(time), .args = args) %...>% plot())
#    session$onSessionEnded(stopApp)
#  }
#  
#  shinyApp(ui = ui, server = server)

