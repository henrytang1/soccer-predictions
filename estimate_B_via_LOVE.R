
################################################################################
######        Select significant features by LOVE 
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
setwd("~/Documents/Mike/Projects/LOVE/Simulation/LOVE-code-2020-05-13/")
source("LOVE.R")
source("EstNonpure.R")
source("EstPure.R")
source("EstOmega.R")
source("Tuning.R")


sub_data <- comp_data[,-c(1:4, 7:9, 43)]

# sub_data <- comp_data[comp_data$position == "goal keeper", c(5:6, 10:42)]
# sub_data <- comp_data[comp_data$position != "goal keeper", c(5:6, 10:37)]   ## we do not use gk attributes
# sub_data <- comp_data[comp_data$position == "forward", c(5:6, 10:37)]

set.seed(2021)

LOVE_res <- LOVE(sub_data, delta = seq(0.1, 2, 0.05), HT = F, mu = 0.5)

A_hat <- LOVE_res$A
rownames(A_hat) <- names(sub_data)
round(A_hat, 1)

A_hat_inv <- A_hat %*% solve(crossprod(A_hat))


mat_gk <- cbind(load = A_hat_inv, center = apply(sub_data, 2, mean), scale = apply(sub_data, 2, sd))
rownames(mat_gk) <- names(comp_data)[c(5:6, 10:42)]


# setwd("~/Desktop/Datathon/")
# write.csv(mat_gk, "./data/loading_all_four_LOVE.csv", row.names = T)
# write.csv(A_hat, "./data/loading_LOVE.csv", row.names = T)


