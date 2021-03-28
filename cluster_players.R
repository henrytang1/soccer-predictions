rm(list = ls())

setwd("~/Desktop/Datathon/")

library(readr)
library(MASS)
library(glmnet)

data_player <- read_csv("./data/player_attributes.csv")


complete_row_ind <- which(rowSums(is.na(data_player)) == 0)
comp_data <- data_player[complete_row_ind,]

names(comp_data)

# remove player_id, date and preferred_foot
data_mat <- comp_data[,-c(1, 2, 5, 6, 7)]

summary(data_mat)


################################################################################
####                             K means 
################################################################################

library(e1071)

set.seed(2021)
# cmeans_result <- cmeans(data_mat, centers = 4)
kmeans_result <- kmeans(data_mat, centers = 4)

group_1 <- which(kmeans_result$cluster == 1)  # midfieder
group_2 <- which(kmeans_result$cluster == 2)  # forward
group_3 <- which(kmeans_result$cluster == 3)  # goal keeper
group_4 <- which(kmeans_result$cluster == 4)  # defender

round(kmeans_result$centers, 0)

# labeled_comp_data <- data.frame(comp_data, position = members)

aug_members <- rep(NA, nrow(data_player))
aug_members[complete_row_ind] = kmeans_result$cluster
aug_members <- factor(aug_members, levels = c(1, 2, 3, 4),
                      labels = c("midfielder", "forward", "goal keeper", "defender"))

aug_player_attribute <- data.frame(data_player, position = aug_members)


# write.csv(aug_player_attribute, file = "./data/player_attributes_w_position.csv",
#           row.names = F)





names(aug_player_attribute)


sub_data <- aug_player_attribute[,-c(1,2,5:7,41)]
names(sub_data)

complete_row_ind <- which(rowSums(is.na(aug_player_attribute)) == 0)
comp_data <- sub_data[complete_row_ind,]


pc_res <- princomp(comp_data)

PC_mat <- pc_res$scores[,1:2]

PC_data <- data.frame(position = aug_player_attribute$position[complete_row_ind], PC_mat)


library(ggplot2)

rowind <- sample(1:nrow(PC_data), floor(0.25 * nrow(PC_data)))

ggplot(PC_data[rowind,], aes(x = Comp.1, y = Comp.2)) + geom_point(aes(color = position), alpha = 0.6) +
  xlab("PC1") + ylab("PC2")








# sub_data <- data_mat[-group_3,-(31:35)]
# sub_kmeans_result <- kmeans(sub_data, centers = 3)
# round(sub_kmeans_result$centers, 0)
# sub_group_1 <- which(sub_kmeans_result$cluster == 1)
# sub_group_2 <- which(sub_kmeans_result$cluster == 2)
# sub_group_3 <- which(sub_kmeans_result$cluster == 3)
# 
# aug_members <- rep(NA, nrow(data_player))
# aug_members[complete_row_ind] = 4
# aug_members[complete_row_ind][-group_3] = sub_kmeans_result$cluster
# aug_members <- factor(aug_members, levels = c(1, 2, 4, 3),
#                       labels = c("midfielder", "forward", "goal keeper", "defender"))
# 
# aug_player_attribute <- data.frame(data_player, position = aug_members)
# 
# 
# 
# 
# 
# id_f <- aug_player_attribute$position == "forward"
# id_m <- aug_player_attribute$position == "midfielder"
# id_d <- aug_player_attribute$position == "defender"
# id_gk <- aug_player_attribute$position == "goal keeper"
# 
# 
# length(intersect(aug_player_attribute[id_f,]$player_id,  aug_player_attribute[id_m,]$player_id))
# length(intersect(aug_player_attribute[id_f,]$player_id,  aug_player_attribute[id_d,]$player_id))
# length(intersect(aug_player_attribute[id_m,]$player_id,  aug_player_attribute[id_d,]$player_id))
# length(intersect(aug_player_attribute[id_f | id_m | id_d,]$player_id,  aug_player_attribute[id_gk,]$player_id))









