rm(list = ls())

setwd("~/Desktop/Datathon/")

library(readr)
data_mtp <- read_csv("./data/match_team_player.csv")
View(data_mtp)


####### initial exploratory 

dim(data_mtp)     #  25979  1031
names(data_mtp)    

# The first 106 columns are features for one match and the two teams in this match
# the remaining columns are the attributes of 22 (starting lineup) players involved
# in this match
data_mt <- data_mtp[,1:106]

names(data_mt)
# View(data_mt)

# Among the first 106 columns, 11th - 32th columns contain players' id.
#                              33th - 62th columns contain betting odds.
#                              63th column is country_name
#                              64th column is league_name
#                              the remaining columns are team attributes


# View(subset(data_mt[,63:106]))

# For team attributes that have numerical values, we only use the numerical column.
# Check which attributes should be retained with numerical columns only.

# "home_buildUpPlayDribblingClass" and "away_buildUpPlayDribblingClass" have too few numerical values.
# "home_buildUpPlayPositioningClass", "away_buildUpPlayPositioningClass", 
# "home_chanceCreationPositioningClass", "awy_chanceCreationPositioningClass",
# "home_defenceDefenderLineClass", "away_defenceDefenderLineClass"
# only have categorical classes.

cat_attr_names <- c("home_buildUpPlayDribblingClass", "away_buildUpPlayDribblingClass",
                    "home_buildUpPlayPositioningClass", "away_buildUpPlayPositioningClass",
                    "home_chanceCreationPositioningClass", "away_chanceCreationPositioningClass",
                    "home_defenceDefenderLineClass", "away_defenceDefenderLineClass")

discard_attr_name <- c("home_buildUpPlayDribbling", "away_buildUpPlayDribbling")
names(data_mt)

# Select team attributes that we use in the analysis
cat_attr_ind <- which(names(data_mt) %in% cat_attr_names)
discard_attr_ind <- which(names(data_mt) %in% discard_attr_name)

other_team_attr_ind <- setdiff(65:106, c(cat_attr_ind, discard_attr_ind))
num_attr_ind <- other_team_attr_ind[2 * (1:(length(other_team_attr_ind)/2)) - 1]


# We also exclude columns contaitning player id and betting odds
feature_ind <- c(1:10, 63, 64, c(num_attr_ind, cat_attr_ind))

sub_data_mt <- subset(data_mt, select = feature_ind)

# We only include names of country and league by excluding their id's. We also exclude
# the home / away team id. The date column is excluded as well as its information is 
# contained in the stage column. 

feature_ind <- setdiff(feature_ind, c(1, 2, 5, 7, 8))
sub_data_mt <- subset(data_mt, select = feature_ind)

View(sub_data_mt)
dim(sub_data_mt)

# Rearrange columns and convert match results to a categorical response

response <- rep(0, nrow(sub_data_mt))
response[sub_data_mt$home_team_goal > sub_data_mt$away_team_goal] <- 1
response[sub_data_mt$home_team_goal < sub_data_mt$away_team_goal] <- -1

response <- factor(response, levels = c(1, 0, -1), labels = c("H", "D", "A"))

final_data_mt <- data.frame(outcome = response, sub_data_mt)

# View(final_data_mt)

summary(final_data_mt)

# the last 8 columns are either categorical or ordinal variables, convert them 
# to either ordinal or categorical factors
names(final_data_mt)[25:32]

list_factor_name <- c()

for (t in 25:32) {
  col_t <- final_data_mt[,t]
  list_factor_name[[t-24]] <- levels(factor(col_t))
  factor_col_t <- factor(col_t, ordered = T)
  final_data_mt[,t] <- factor(factor_col_t, labels = 1:length(levels(factor_col_t)))
}

final_data_mt$stage <- factor(final_data_mt$stage, ordered = T)
final_data_mt$country_name <- factor(final_data_mt$country_name)
final_data_mt$league_name <- factor(final_data_mt$league_name)
final_data_mt$season <- factor(final_data_mt$season)

summary(final_data_mt)


write.csv(final_data_mt, "./data/final_match_team.csv", row.names = F)

