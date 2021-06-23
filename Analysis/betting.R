rm(list = ls())

setwd("/Users/yuxuan/Desktop/datathon")

library(readr)
library(MASS)
# library(lme4)
library(nnet)
library(glmnet)

comp_data<- read_csv("match_team_player_complete_withodds.csv")


col_names <- names(comp_data)
col_names <- setdiff(col_names, c("stage", "home_team_goal", "away_team_goal"))    # remove match id

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




# split data into training (70%) containing missing odds and test (30%) sets

split_data_for_odds <- function(data_matrix, p = 0.7) {
  nrow_data <- nrow(data_matrix)
  train_ind_1 = which(apply(data_matrix, 1, function(x){any(is.na(x))}))
  train_ind_2 <- sample(setdiff(1:nrow_data, train_ind_1), 
                        floor(0.7*nrow_data) - length(train_ind_1) )
  train_ind = c(train_ind_1, train_ind_2)
  test_ind <- setdiff(1:nrow_data, train_ind)
  return(list(train = data_matrix[train_ind,], test = data_matrix[test_ind,]))
}

set.seed(2021)

split_H <- split_data_for_odds(subset(sub_data, outcome == "H"))
split_A <- split_data_for_odds(subset(sub_data, outcome == "A"))
split_D <- split_data_for_odds(subset(sub_data, outcome == "D"))

train_data <- rbind(split_H$train, split_D$train, split_A$train)
test_data <- rbind(split_H$test, split_D$test, split_A$test)

matchid_train = train_data$match_id
matchid_test = test_data$match_id
train_data$match_id = NULL
test_data$match_id = NULL

table(train_data$outcome)
table(test_data$outcome)


train_X <- model.matrix(outcome ~ ., data = train_data[,-(58:60)])
test_X <- model.matrix(outcome ~ ., data = test_data[,-(58:60)])

decision <- function(h, a, d){
  h = as.numeric(h)
  a = as.numeric(a)
  d = as.numeric(d)
  index = which.max(c(h, a, d, 0))
  d = c('H', 'A', 'D', 'N')
  d[index]
}

all_decisions <- function(H, A, D, odds){
  H = as.numeric(as.matrix(H))
  A = as.numeric(as.matrix(A))
  D = as.numeric(as.matrix(D))
  n = length(H)
  decisions = character(n)
  profit = numeric(n)
  for (i in 1:n){
    decisions[i] = decision(H[i], A[i], D[i])
    if (decisions[i] == 'N') profit[i] = 0 else{
      if (odds$outcome[i] == decisions[i]){ 
        if (decisions[i] == 'H') profit[i] = odds$max_odds_H[i] - 1
        if (decisions[i] == 'A') profit[i] = odds$max_odds_A[i] - 1
        if (decisions[i] == 'D') profit[i] = odds$max_odds_D[i] - 1
      }else{
        profit[i] = -1
      }
    }
  }
  list(decisions = decisions, profit = profit)
}

summary_betting <- function(profits, decisions, outcome){
  print(paste('overall profit ', mean(profits)))
  print(paste('positive profit ratio ', mean(profits>0)))
  print("cross table: ")
  print(table(outcome, profits>0))
  print("cross table: ")
  print(table(outcome, decisions))
  print(paste("H: overall profit ", mean(profits[outcome == 'H'])))
  print(paste("D: overall profit ", mean(profits[outcome == 'D'])))
  print(paste("A: overall profit ", mean(profits[outcome == 'A'])))
}
################################################################################
##########             (Multinomial) GLMNET
################################################################################
glm_logit <- cv.glmnet(train_X[,-1], 
                       train_data$outcome,
                       family = "multinomial", nfolds = 5, 
                       trace.it = 1)

pred_probs <- predict(glm_logit, newx = test_X[,-1], s = glm_logit$lambda.min, type = "response")
pred_labels <- predict(glm_logit, newx = test_X[,-1], s = glm_logit$lambda.min, type = "class")

pred_probs = drop(pred_probs)


table(factor(test_data$outcome, ordered = F), pred_labels)
mean(factor(test_data$outcome, ordered = F) != pred_labels)

odds = test_data[,58:60]
odds$outcome = test_data$outcome

odds$prob_H_multi = pred_probs[,1]
odds$prob_D_multi = pred_probs[,2]
odds$prob_A_multi = pred_probs[,3]
odds$gain_H_multi = odds$max_odds_H  * odds$prob_H_multi - 1
odds$gain_A_multi = odds$max_odds_A  * odds$prob_A_multi- 1
odds$gain_D_multi = odds$max_odds_D  * odds$prob_D_multi - 1

r = all_decisions(odds$gain_H_multi, odds$gain_A_multi, odds$gain_D_multi, odds)
odds$decision_multi = r$decisions
odds$profit_multi = r$profit
summary_betting(odds$profit_multi, odds$decision_multi, odds$outcome)



################################################################################
##########             (binomial) GLMNET
################################################################################
index = which(train_data$outcome != levels(train_data$outcome)[2])
glm_bin <- cv.glmnet(train_X[index,-1], 
                       train_data$outcome[index] == levels(train_data$outcome)[3],
                       family = "binomial", nfolds = 5, 
                       trace.it = 1)

pred_probs_bin <- predict(glm_bin, newx = test_X[,-1], s = glm_logit$lambda.min, type = "response")
pred_labels_bin <- predict(glm_bin, newx = test_X[,-1], s = glm_logit$lambda.min, type = "class")


odds$prob_H_b = drop(pred_probs_bin) * 0.75
odds$prob_A_b = drop(1-pred_probs_bin) * 0.75
odds$gain_H_b = (odds$max_odds_H ) * odds$prob_H_b - 1
odds$gain_A_b = (odds$max_odds_A ) * odds$prob_A_b - 1
odds$gain_D_b = (odds$max_odds_D ) * 0.25 - 1

r = all_decisions(odds$gain_H_b, odds$gain_A_b, odds$gain_D_b, odds)
odds$decision_b3 = r$decisions
odds$profit_b3 = r$profit
summary_betting(odds$profit_b3, odds$decision_b3, odds$outcome)

r = all_decisions(odds$gain_H_b, odds$gain_A_b, pmin(-1, odds$gain_D_b), odds)
odds$decision_b2 = r$decisions
odds$profit_b2 = r$profit
summary_betting(odds$profit_b2, odds$decision_b2, odds$outcome)

