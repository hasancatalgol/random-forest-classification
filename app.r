# app.r
library(shiny)

ui <- fluidPage(
  titlePanel("Bank Marketing - Random Forest Dashboard"),
  sidebarLayout(
    sidebarPanel(
      numericInput("ntree", "Number of Trees:", value = 10, min = 10, max = 1000, step = 1),
      actionButton("train_btn", "Train Model"),
      hr(),
      h4("Model Performance"),
      verbatimTextOutput("accuracy"),
      verbatimTextOutput("precision_yes"),
      verbatimTextOutput("recall_yes"),
      verbatimTextOutput("f1_yes"),
      verbatimTextOutput("precision_no"),
      verbatimTextOutput("recall_no")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Confusion Matrix", plotOutput("conf_matrix_heatmap")),
        tabPanel("Feature Importance", tableOutput("importance_plot")),
        tabPanel("Predictions", tableOutput("pred_table")),
        tabPanel("ROC Curve", plotOutput("roc"))
      )
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$train_btn, {
    rf_dashboard$train_model(ntree = input$ntree)
    output$accuracy <- renderText({ paste("Accuracy:", round(rf_dashboard$accuracy * 100, 2), "%") })
    output$precision_yes <- renderText({ paste("Precision (yes):", round(rf_dashboard$precision_yes * 100, 2), "%") })
    output$recall_yes <- renderText({ paste("Recall (yes):", round(rf_dashboard$recall_yes * 100, 2), "%") })
    output$f1_yes <- renderText({ paste("F1 Score (yes):", round(rf_dashboard$f1_yes * 100, 2), "%") })
    output$precision_no <- renderText({ paste("Precision (no):", round(rf_dashboard$precision_no * 100, 2), "%") })
    output$recall_no <- renderText({ paste("Recall (no):", round(rf_dashboard$recall_no * 100, 2), "%") })

    output$conf_matrix_heatmap <- renderPlot({
      cm_df <- as.data.frame(rf_dashboard$conf_mat$table)
      names(cm_df) <- c("Prediction", "Reference", "Freq")
      ggplot(cm_df, aes(x = Reference, y = Prediction, fill = Freq)) +
        geom_tile() +
        geom_text(aes(label = Freq), color = "white", size = 6) +
        scale_fill_gradient(low = "#56B1F7", high = "#132B43") +
        labs(title = "Confusion Matrix Heatmap") +
        theme_minimal()
    })

    output$importance_plot <- renderTable({
      rf_dashboard$importance_df
    })

    output$pred_table <- renderTable({
      df <- data.frame(Actual = rf_dashboard$test$y, Predicted = rf_dashboard$preds)
      display_df <- head(df, 6)
      colnames(display_df) <- c("Actual", "Predicted")
      display_df
    }, caption = paste("Showing 6 of", nrow(rf_dashboard$test), "records"))

    output$roc <- renderPlot({
      if ("yes" %in% colnames(rf_dashboard$probs)) {
        roc_obj <- roc(rf_dashboard$test$y, rf_dashboard$probs[, "yes"])
        plot(roc_obj, col = "blue", main = "ROC Curve")
      }
    })
  })
}

# Create a list to hold model data and methods
rf_dashboard <- new.env()

# Load and preprocess data
rf_dashboard$df <- read.delim("data/bank-additional-full.csv", sep = ";") %>%
  dplyr::mutate(across(where(is.character), as.factor),
                y = as.factor(y))

# Split data
set.seed(123)
train_index <- caret::createDataPartition(rf_dashboard$df$y, p = 0.8, list = FALSE)
rf_dashboard$train <- rf_dashboard$df[train_index, ]
rf_dashboard$test <- rf_dashboard$df[-train_index, ]

# Train model method
rf_dashboard$train_model <- function(ntree = 3) {
  rf_dashboard$rf_model <- randomForest::randomForest(y ~ ., data = rf_dashboard$train, ntree = ntree, importance = TRUE)
  rf_dashboard$preds <- predict(rf_dashboard$rf_model, rf_dashboard$test)
  rf_dashboard$probs <- predict(rf_dashboard$rf_model, rf_dashboard$test, type = "prob")
  rf_dashboard$conf_mat <- caret::confusionMatrix(rf_dashboard$preds, rf_dashboard$test$y)
  rf_dashboard$importance_df <- as.data.frame(randomForest::importance(rf_dashboard$rf_model))

  # Global metrics
  rf_dashboard$accuracy <- mean(rf_dashboard$preds == rf_dashboard$test$y)

  # Per-class metrics
  rf_dashboard$precision_yes <- caret::posPredValue(rf_dashboard$preds, rf_dashboard$test$y, positive = "yes")
  rf_dashboard$recall_yes <- caret::sensitivity(rf_dashboard$preds, rf_dashboard$test$y, positive = "yes")
  rf_dashboard$f1_yes <- 2 * rf_dashboard$precision_yes * rf_dashboard$recall_yes / (rf_dashboard$precision_yes + rf_dashboard$recall_yes)

  rf_dashboard$precision_no <- caret::posPredValue(relevel(rf_dashboard$preds, ref = "no"), relevel(rf_dashboard$test$y, ref = "no"), positive = "no")
  rf_dashboard$recall_no <- caret::sensitivity(relevel(rf_dashboard$preds, ref = "no"), relevel(rf_dashboard$test$y, ref = "no"), positive = "no")
}


shinyApp(ui, server)