rm(list = ls())

setwd("~/Desktop/Datathon/")

library(readr)
library(MASS)
# library(lme4)
library(nnet)
library(glmnet)

data_mt <- read_csv("./data/match_team_player_complete_after_20100222.csv")
# data_mt <- read_csv("./data/match_team_player_narrow_complete_after_20100222.csv")

# View(data_mt)

complete_row_ind <- which(rowSums(is.na(data_mt)) == 0)
comp_data <- data_mt[complete_row_ind,]


col_names <- names(comp_data)


# outcome <- rep("H", nrow(comp_data))
# outcome[comp_data$home_team_goal < comp_data$away_team_goal] <- "A"
# outcome[comp_data$home_team_goal == comp_data$away_team_goal] <- "D"
# outcome <- factor(outcome, ordered = T)
# comp_data <- data.frame(outcome, comp_data)


col_names <- setdiff(col_names, c("match_id", "home_team_goal", "away_team_goal"))    # remove match id

sub_data <- data.frame(subset(comp_data, select = col_names))   

# convert character features to categorical or ordinal
cat_names <- c("country_name", "season")
ord_names <- c("outcome", "stage", col_names[19:26])

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
summary(sub_data)

##############
###   Remove stage and categorical team & player attributes
# sub_data <- sub_data[,-c(2, 19:26, 71:86)]
sub_data <- sub_data[,-c(2, 71:86)]

# ## Check pairwise correlation
# heatmap(cor(sub_data[,-1], method = "spearman"))
# library(ggplot2)
# cor_mat <- cor(sub_data[,(26:111)], method = "spearman")
# library(reshape2)
# melted_cormat <- melt(cor_mat)
# 
# ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + geom_tile()

# par(mar = c(2,2, 1,1))
# image(cor(sub_data[,(26:111)], method = "spearman"))  ### attributes related with gk are relatively more correlated



names(sub_data[,(26:111)])
# 
# attr_ind <- 634:ncol(sub_data)
# attr_ind <- 2:ncol(sub_data)
# sub_attr <- sub_data[,attr_ind]
# eig_vals <- eigen(cov(sub_attr))$values
# plot(eig_vals[1:10] / eig_vals[2:11])


###### split data into training (70%) and test (30%) sets

split_data <- function(data_matrix, p = 0.7) {
  nrow_data <- nrow(data_matrix)
  train_ind <- sample(1:nrow_data, floor(p * nrow_data))
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

train_X <- model.matrix(outcome ~ 0 + ., data = train_data)

glm_logit <- cv.glmnet(train_X, train_data$outcome, family = "multinomial", type = "class")

beta_hat <- coef(glm_logit, s = glm_logit$lambda.1se)

# find non-zero features for each level

rownames(beta_hat$H)[which(beta_hat$H > 0)]
rownames(beta_hat$H)[which(beta_hat$H < 0)]
rownames(beta_hat$A)[which(beta_hat$A > 0)]
rownames(beta_hat$A)[which(beta_hat$A < 0)]
rownames(beta_hat$D)[which(beta_hat$D != 0)]

test_X <- model.matrix(outcome ~ 0 + ., data = test_data)
# pred_probs <- predict(glm_logit, newdata = test_X, "probs")

pred_test_label <- predict(glm_logit, newx = test_X, s = glm_logit$lambda.min, type = "class")

table(factor(test_data$outcome, ordered = F), pred_test_label)
mean(factor(test_data$outcome, ordered = F) != pred_test_label)



tab_res <- table(factor(test_data$outcome, ordered = F), pred_test_label)

tab_2way <- rbind(tab_res[1,], tab_res[2,] + tab_res[3,])
(tab_2way[1,2] + tab_2way[2,1]) / (sum(tab_2way))


summary(test_data$outcome)


# save.image(file = "./data/result.RData")



load("./data/result.RData")











# ################################################################################
# ##########              Ordered logistic regression
# ################################################################################
# 
# 
# plr_model <- polr(outcome ~ ., data = train_data, method = "probit", Hess = T)
# summary(plr_model)
# 
# coef_res <- summary(plr_model)$coefficients
# z_stats <- coef_res[,'Value']/coef_res[,'Std. Error']
# p_stats <- (1 - pnorm(abs(z_stats), 0, 1)) * 2
# 
# plr_pred_probs <- predict(plr_model, test_data, type = "p")
# 
# plr_pred_labels <- predict(plr_model, test_data)
# 
# table(factor(test_data$outcome, ordered = F), plr_pred_labels)
# mean(factor(test_data$outcome, ordered = F) != plr_pred_labels)

