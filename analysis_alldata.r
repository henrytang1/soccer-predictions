rm(list = ls())

setwd("/Users/yuxuan/Desktop/datathon")

library(readr)
library(MASS)
# library(lme4)
library(nnet)
library(glmnet)

data_mt <- read_csv("match_team_player_complete.csv")



complete_row_ind <- which(rowSums(is.na(data_mt)) == 0)
comp_data <- data_mt[complete_row_ind,]


col_names <- names(comp_data)
col_names <- setdiff(col_names, c("match_id", "country_name", "season", "home_team_goal", "away_team_goal", "stage"))    # remove match id

sub_data <- data.frame(subset(comp_data, select = col_names))   

# convert character features to categorical or ordinal
cat_names <- c("country_name", "season")
#ord_names <- c("outcome", "stage", col_names[19:26], 71:86)
ord_names <- c("outcome", "stage", col_names[18:25])

for (t in 1:ncol(sub_data)) {
  col_t <- sub_data[,t]
  name_t <- col_names[t]
  if (name_t %in% c(cat_names, ord_names)) {
    if (name_t %in% cat_names)
      sub_data[,t] <- factor(col_t, ordered = F)
    else 
      sub_data[,t] <- factor(col_t, ordered = T)
  }
}

# sub_data[sapply(sub_data, is.character)] <- lapply(sub_data[sapply(sub_data, is.character)], 
#                                        as.ordered)


##############



# split data into training (70%) and test (30%) sets

split_data <- function(data_matrix, p = 0.7) {
  nrow_data <- nrow(data_matrix)
  train_ind <- sample(1:nrow_data, floor(0.7 * nrow_data))
  test_ind <- setdiff(1:nrow_data, train_ind)
  return(list(train = data_matrix[train_ind,], test = data_matrix[test_ind,]))
}

set.seed(2021)

split_H <- split_data(subset(sub_data, outcome == "H"))
split_A <- split_data(subset(sub_data, outcome == "A"))
split_D <- split_data(subset(sub_data, outcome == "D"))

train_data <- rbind(split_H$train, split_D$train, split_A$train)
test_data <- rbind(split_H$test, split_D$test, split_A$test)

table(train_data$outcome)
table(test_data$outcome)




################################################################################
##########             (Multinomial) GLMNET
################################################################################
train_X <- model.matrix(outcome ~ ., data = train_data)
test_X <- model.matrix(outcome ~ ., data = test_data)

a = Sys.time()
glm_logit <- cv.glmnet(train_X[,-1], train_data$outcome, family = "multinomial", nfolds = 5, 
                       trace.it = 1, alpha = 0.5)
Sys.time() - a # 9mins


pred_test_label <- predict(glm_logit, newx = test_X[,-1], s = glm_logit$lambda.min, type = "class")

table(factor(test_data$outcome, ordered = F), pred_test_label)
mean(factor(test_data$outcome, ordered = F) != pred_test_label)



