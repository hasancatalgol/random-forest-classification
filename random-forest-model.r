# random-forest-model.r

library(tidyverse)
library(randomForest)
library(caret)
library(ggplot2)
library(reshape2)
library(pROC)

# Create a list to hold model data
rf_dashboard <- new.env()

# Load and preprocess data
rf_dashboard$df <- read_delim("data/bank-additional-full.csv", delim = ";") %>%
  mutate(across(where(is.character), as.factor),
         y = as.factor(y))

# Split data
set.seed(123)
train_index <- createDataPartition(rf_dashboard$df$y, p = 0.8, list = FALSE)
rf_dashboard$train <- rf_dashboard$df[train_index, ]
rf_dashboard$test <- rf_dashboard$df[-train_index, ]

# Define training logic (called on demand)
rf_dashboard$train_model <- function(ntree = 100) {
  rf_dashboard$rf_model <- randomForest(y ~ ., data = rf_dashboard$train, ntree = ntree, importance = TRUE)
  rf_dashboard$preds <- predict(rf_dashboard$rf_model, rf_dashboard$test)
  rf_dashboard$probs <- predict(rf_dashboard$rf_model, rf_dashboard$test, type = "prob")
  rf_dashboard$conf_mat <- confusionMatrix(rf_dashboard$preds, rf_dashboard$test$y)
  rf_dashboard$importance_df <- as.data.frame(importance(rf_dashboard$rf_model))
  rf_dashboard$accuracy <- mean(rf_dashboard$preds == rf_dashboard$test$y)
  rf_dashboard$precision <- posPredValue(rf_dashboard$preds, rf_dashboard$test$y, positive = "yes")
  rf_dashboard$recall <- sensitivity(rf_dashboard$preds, rf_dashboard$test$y, positive = "yes")
  rf_dashboard$f1 <- (2 * rf_dashboard$precision * rf_dashboard$recall) / (rf_dashboard$precision + rf_dashboard$recall)
}