rm(list = ls())

setwd("~/Desktop/Datathon/")

library(readr)
library(MASS)
# library(lme4)
library(nnet)
library(glmnet)

# data_mt <- read_csv("./data/match_team_player_latent.csv")
# data_mt <- read_csv("./data/match_team_player_latent_allfour.csv")
data_mt <- read_csv("./data/match_team_player_latent_love.csv")
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


col_names <- setdiff(col_names, c("X1", "match_id", "home_team_goal", "away_team_goal"))    # remove match id

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
# summary(sub_data)

##############
###   Remove stage and categorical team attributes
# sub_data <- sub_data[,-c(2, 19:26)]
sub_data <- sub_data[,-c(2)]

# sub_names <- names(sub_data)

# ## Check pairwise correlation

# heatmap(cor(sub_data[,18:49], method = "spearman"))
# image(cor(sub_data[,18:49], method = "spearman"))
# heatmap(cor(sub_data[,(634:ncol(sub_data))], method = "spearman"))  ### attributes related with gk are relatively more correlated
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

# table(train_data$outcome)
# table(test_data$outcome)





################################################################################
##########             (Multinomial) GLMNET
################################################################################

train_X <- model.matrix(outcome ~ 0 + ., data = train_data)

glm_logit <- cv.glmnet(train_X, train_data$outcome, family = "multinomial", type.measure = "class")

beta_hat <- coef(glm_logit, s = glm_logit$lambda.1se)

# find non-zero features for each level

coef_H_pos <- rownames(beta_hat$H)[which(beta_hat$H > 0)]
coef_H_neg <- rownames(beta_hat$H)[which(beta_hat$H < 0)]
coef_A_pos <- rownames(beta_hat$A)[which(beta_hat$A > 0)]
coef_A_neg <- rownames(beta_hat$A)[which(beta_hat$A < 0)]
coef_D <- rownames(beta_hat$D)[which(beta_hat$D != 0)]

# setdiff(coef_H_pos, coef_A_pos)
# setdiff(coef_A_pos, coef_H_pos)


test_X <- model.matrix(outcome ~ 0 + ., data = test_data)
# pred_probs <- predict(glm_logit, newx = test_X, s = glm_logit$lambda.min, type = "response")[,,1]


conf_mat <- confusion.glmnet(glm_logit, newx = test_X, newy = factor(test_data$outcome, ordered = F), 
                 family = "multinomial", s = glm_logit$lambda.min)



# pred_test_label <- predict(glm_logit$fit.preval, newx = test_X, s = glm_logit$lambda.min, type = "class")
# table(factor(test_data$outcome, ordered = F), pred_test_label)
# 
# mean(factor(test_data$outcome, ordered = F) != pred_test_label)

# save.image(file = "./data/result.RData")


# tab_res <- table(factor(test_data$outcome, ordered = F), pred_test_label)
# 
# tab_2way <- rbind(tab_res[1,], tab_res[2,] + tab_res[3,])
# (tab_2way[1,2] + tab_2way[2,1]) / (sum(tab_2way))
# 
# 
# summary(test_data$outcome)



################################################################################
####                          Interpret the results
################################################################################




# load_name <- "~/Desktop/Datathon/data/loading_all_four.csv"
# load_name <- "~/Desktop/Datathon/data/loading_other_three.csv"
load_name <- "~/Desktop/Datathon/data/loading_LOVE.csv"
load_all <- read_csv(load_name)

# load_mat <- as.matrix(load_all[,2:(ncol(load_all)-2)])
load_mat <- as.matrix(load_all[,2:(ncol(load_all))])

rownames(load_mat) <- load_all$X1

round(load_mat,1)

get_latent_name <- function(load_mat, numb_top_feature = 5) {
  lapply(1:ncol(load_mat), FUN = function(i, v_name, k) {
    v = load_mat[,i]
    v_order_dec <- order(abs(v), decreasing = T)
    v_name[v_order_dec][1:k]
  }, v_name = rownames(load_mat), k = numb_top_feature)
}

top_feature_list <- get_latent_name(load_mat, 10)

# factor_names <- c("attack", "defence")
# factor_names <- c("attack", "defence", "goal keep", "midfield")
factor_names <- c("attack", "midfield", "defence", "goal keep")

names(top_feature_list) <- factor_names
n_factor <- length(top_feature_list)


get_coef_mat <- function(beta_vec, n_factor, factor_names, offset = 29) {
  A_mat <- matrix(beta_vec[offset:nrow(beta_vec),1], ncol = n_factor, byrow = T)
  colnames(A_mat) <- factor_names
  rownames(A_mat) <- c(paste("home", c("forward", "midfielder", "defender", "goal keeper")),
                       paste("away", c("forward", "midfielder", "defender", "goal keeper")))
  A_mat
}

coef_mat_H <- get_coef_mat(beta_hat$H, n_factor, names(top_feature_list))
coef_mat_A <- get_coef_mat(beta_hat$A, n_factor, names(top_feature_list))

round(cbind(coef_mat_H, coef_mat_A), 2)

library(xtable)
xtable(round(cbind(coef_mat_H, coef_mat_A), 2))


A_mat_inv <-  load_mat %*% solve(crossprod(load_mat))

attr_coef_H <- coef_mat_H %*% t(A_mat_inv)

get_latent_name(t(attr_coef_H), 5)









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
# round(p_stats[which(p_stats <= 0.1)], 3)
# round(coef_res[which(p_stats <= 0.1), 1], 2)
# 
# 
# plr_pred_probs <- predict(plr_model, test_data, type = "p")
# 
# plr_pred_labels <- predict(plr_model, test_data)
# 
# table(factor(test_data$outcome, ordered = F), plr_pred_labels)
# mean(factor(test_data$outcome, ordered = F) != plr_pred_labels)
