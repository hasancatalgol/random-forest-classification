library(shiny)
source("random-forest-model.r", local = TRUE)

ui <- fluidPage(
  titlePanel("Bank Marketing - Random Forest Dashboard"),
  sidebarLayout(
    sidebarPanel(
      h4("Model Performance"),
      verbatimTextOutput("accuracy"),
      verbatimTextOutput("precision"),
      verbatimTextOutput("recall"),
      verbatimTextOutput("f1")
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

server <- function(input, output) {
  output$accuracy <- renderText({ paste("Accuracy:", round(rf_dashboard$accuracy * 100, 2), "%") })
  output$precision <- renderText({ paste("Precision:", round(rf_dashboard$precision * 100, 2), "%") })
  output$recall <- renderText({ paste("Recall:", round(rf_dashboard$recall * 100, 2), "%") })
  output$f1 <- renderText({ paste("F1 Score:", round(rf_dashboard$f1 * 100, 2), "%") })

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
}

shinyApp(ui, server)