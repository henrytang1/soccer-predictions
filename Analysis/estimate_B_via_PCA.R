
################################################################################
######             Feature dimension reduction via PCA 
##
##    We consider two types of dimension reduction:
##       (1) For goal keeper: construct its own loading. For other three players,
##           construct their joint loadings (the gk attributes are removed for 
##           these players)
##       (2) For goal keeper: construct its own loading. For other three players,
##           construct each of their loadings (the gk attributes are removed for 
##           these players).
##
################################################################################


rm(list = ls())

setwd("~/Desktop/Datathon/")

library(readr)
library(MASS)
library(glmnet)

data_player <- read_csv("./data/player_attributes_w_position.csv")

attack_reponse <- data_player$attacking_work_rate
attack_reponse[!(attack_reponse %in% c("medium", "high", "low"))] <- NA
attack_reponse <- factor(attack_reponse, levels = c("low", "medium", "high"),
                         ordered = T)


defend_reponse <- data_player$defensive_work_rate
defend_reponse[!(defend_reponse %in% c("medium", "high", "low"))] <- NA
defend_reponse <- factor(defend_reponse, levels = c("low", "medium", "high"),
                         ordered = T)

aug_data_player <- data.frame(attack = attack_reponse, defend = defend_reponse,
                              data_player)

head(aug_data_player)




complete_row_ind <- which(rowSums(is.na(aug_data_player)) == 0)
comp_data <- aug_data_player[complete_row_ind,]


table(aug_data_player$attack[aug_data_player$position == "forward"])
table(aug_data_player$attack[aug_data_player$position == "midfielder"])
table(aug_data_player$attack[aug_data_player$position == "defender"])
table(aug_data_player$attack[aug_data_player$position == "goal keeper"])






### Select attacking features

sub_data <- comp_data[,-c(1:4, 7:9, 43)]

# sub_data <- comp_data[comp_data$position == "goal keeper", c(5:6, 10:42)]
# sub_data <- comp_data[comp_data$position != "goal keeper", c(5:6, 10:37)]   ## we do not use gk attributes
# sub_data <- comp_data[comp_data$position == "defender", c(5:6, 10:37)]

pc_res <- prcomp(sub_data, scale. = T)
screeplot(pc_res, main = "Scree-plot of the singular values")
cumsum(pc_res$sdev) / sum(pc_res$sdev)

# eig_res <- eigen(cor(sub_data))
k_PC <- 4

sparse_load <- varimax(pc_res$rotation[,1:k_PC])$loadings
rownames(sparse_load) <- colnames(sub_data)


mat_gk <- cbind(load = matrix(sparse_load, nrow(sparse_load), k_PC), 
                     center = pc_res$center, scale = pc_res$scale)

mat_gk <- rbind(mat_gk, matrix(0, 5, k_PC+2))

rownames(mat_gk) <- names(comp_data)[c(5:6, 10:42)]

mat_gk[31:35,k_PC+2] <- 1

# write.csv(mat_gk, "./data/loading_all_four.csv", row.names = T)








# Z_mat <- as.matrix(sub_data) %*% sparse_load
# 
# apply(Z_mat[comp_data$position == "forward",], 2, mean)
# apply(Z_mat[comp_data$position == "midfielder",], 2, mean)
# apply(Z_mat[comp_data$position == "defender",], 2, mean)
# apply(Z_mat[comp_data$position == "goal keeper",], 2, mean)

