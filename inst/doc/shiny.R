## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  out.width = "100%"
)

## ----shinyextended, eval=FALSE------------------------------------------------
#  library(shiny)
#  library(bslib)
#  library(mirai)
#  
#  ui <- page_fluid(
#    p("The time is ", textOutput("current_time", inline = TRUE)),
#    hr(),
#    numericInput("n", "Sample size (n)", 100),
#    numericInput("delay", "Seconds to take for plot", 5),
#    input_task_button("btn", "Plot uniform distribution"),
#    plotOutput("plot")
#  )
#  
#  server <- function(input, output, session) {
#    output$current_time <- renderText({
#      invalidateLater(1000)
#      format(Sys.time(), "%H:%M:%S %p")
#    })
#  
#    extended_task <- ExtendedTask$new(
#      function(x, y) mirai({Sys.sleep(y); runif(x)}, environment())
#    ) |> bind_task_button("btn")
#  
#    observeEvent(input$btn, extended_task$invoke(input$n, input$delay))
#  
#    output$plot <- renderPlot(hist(extended_task$result()))
#  
#  }
#  
#  app <- shinyApp(ui = ui, server = server)
#  
#  # run app using 2 local daemons
#  with(daemons(2), runApp(app))

## ----shinystep1, eval=FALSE---------------------------------------------------
#  input_task_button("btn", "Plot uniform distribution")

## ----shinystep2, eval=FALSE---------------------------------------------------
#  extended_task <- ExtendedTask$new(
#      function(x, y) mirai({Sys.sleep(y); runif(x)}, environment())
#    ) |> bind_task_button("btn")

## ----shinystep3, eval=FALSE---------------------------------------------------
#  observeEvent(input$btn, extended_task$invoke(input$n, input$delay))

## ----shinystep4, eval=FALSE---------------------------------------------------
#  output$plot <- renderPlot(hist(extended_task$result()))

## ----shinyextend2, eval=FALSE-------------------------------------------------
#  library(shiny)
#  library(mirai)
#  library(bslib)
#  library(ggplot2)
#  library(aRtsy)
#  
#  # function definitions
#  
#  run_task <- function(calc_time) {
#    Sys.sleep(calc_time)
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
#  # modules for individual plots
#  
#  plotUI <- function(id, calc_time) {
#    ns <- NS(id)
#    card(
#      strong(paste0("Plot (calc time = ", calc_time, " secs)")),
#      input_task_button(ns("resample"), "Resample"),
#      plotOutput(ns("plot"), height="400px", width="400px")
#    )
#  }
#  
#  plotServer <- function(id, calc_time) {
#    force(id)
#    force(calc_time)
#    moduleServer(
#      id,
#      function(input, output, session) {
#        extended_task <- ExtendedTask$new(
#          function(...) mirai(run(x), ...)
#        ) |> bind_task_button("resample")
#  
#        observeEvent(input$resample,
#                     extended_task$invoke(x = calc_time, run = run_task))
#  
#        output$plot <- renderPlot(plot_result(extended_task$result()))
#  
#      }
#    )
#  }
#  
#  # ui and server
#  
#  ui <- page_sidebar(fillable = FALSE,
#    sidebar = sidebar(
#      numericInput("calc_time", "Calculation time (secs)", 5),
#      actionButton("add", "Add", class="btn-primary"),
#    ),
#    layout_column_wrap(id = "results", width = "400px", fillable = FALSE)
#  )
#  
#  server <- function(input, output, session) {
#  
#    observeEvent(input$add, {
#      id <- nanonext::random(4)
#      insertUI("#results", where = "beforeEnd", ui = plotUI(id, input$calc_time))
#      plotServer(id, input$calc_time)
#    })
#  }
#  
#  app <- shinyApp(ui, server)
#  
#  # run app using 3 local daemons
#  with(daemons(3), runApp(app))

## ----shinystep21, eval=FALSE--------------------------------------------------
#  input_task_button(ns("resample"), "Resample")

## ----shinystep22, eval=FALSE--------------------------------------------------
#  extended_task <- ExtendedTask$new(
#    function(x, run = run_task) mirai(run(x), environment())
#  ) |> bind_task_button("resample")

## ----shinystep23, eval=FALSE--------------------------------------------------
#  observeEvent(input$resample, extended_task$invoke(calc_time))

## ----shinystep24, eval=FALSE--------------------------------------------------
#  output$plot <- renderPlot(plot_result(extended_task$result()))

## ----shinypromises, eval=FALSE------------------------------------------------
#  library(shiny)
#  library(mirai)
#  
#  flip_coin <- function(...) {
#    Sys.sleep(0.1)
#    rbinom(n = 1, size = 1, prob = 0.501)
#  }
#  
#  ui <- fluidPage(
#    div("Is the coin fair?"),
#    actionButton("task", "Flip 1000 coins"),
#    textOutput("status"),
#    textOutput("outcomes")
#  )
#  
#  server <- function(input, output, session) {
#  
#    # Keep running totals of heads, tails, and task errors
#    flips <- reactiveValues(heads = 0, tails = 0, flips = 0)
#  
#    # Button to submit a batch of coin flips
#    observeEvent(input$task, {
#      flips$flips <- flips$flips + 1000
#      m <- mirai_map(1:1000, flip_coin, .promise = \(x)
#        if (x) flips$heads <- flips$heads + 1 else flips$tails <- flips$tails + 1)
#    })
#  
#    # Print time and task status
#    output$status <- renderText({
#      input$task
#      invalidateLater(millis = 1000)
#      time <- format(Sys.time(), "%H:%M:%S")
#      sprintf("%s %s flips submitted", time, flips$flips)
#    })
#  
#    # Print number of heads and tails
#    output$outcomes <- renderText(
#      sprintf("%s heads %s tails", flips$heads, flips$tails)
#    )
#  
#  }
#  
#  app <- shinyApp(ui = ui, server = server)
#  
#  # run app using 8 local daemons, without dispatcher as tasks are the same length
#  with(daemons(8, dispatcher = FALSE), {
#    # pre-load flip_coin function on all daemons for efficiency
#    everywhere({}, flip_coin = flip_coin)
#    runApp(app)
#  })

## ----shiny, eval=FALSE--------------------------------------------------------
#  library(mirai)
#  library(shiny)
#  library(ggplot2)
#  library(aRtsy)
#  
#  # function definitions
#  
#  run_task <- function() {
#    Sys.sleep(5)
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
#      sprintf("%d task%s in progress at %s",
#              tasks, if (tasks > 1L) "s" else "", format.POSIXct(Sys.time()))
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
#    # create empty mirai queue
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
#  app <- shinyApp(ui = ui, server = server)
#  
#  # run app using 3 local daemons
#  with(daemons(3), runApp(app))

