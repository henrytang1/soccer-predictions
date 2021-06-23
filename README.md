# soccer-predictions
This contains the code, data, and final report. The goal of this project is to figure out which characteristics of players and teams are the most impactful on team success.

## Report
`report.pdf` contains the final report.

## Data
All the original csv files are included in this folder.

`match_team_player_complete.csv` contains the combined data. This is our final merged dataset, that is used as input into our various models.
- Each column of the form *loc_attribute*, refers to the *attribute* of the *loc* team.
- Each column of the form *home_attribute_i*, refers to the *attribute* of player *i* on the *loc* team.

All other csv files are intermediate files generated, and used by the various code files.

## Code
### Preprocessing
`preprocess_data.py` is the initial script to generate a merged dataset, by appending additional player and team features onto each row, where each row corresponds to a match.

`data_clean.ipynb` and `data_clean_with_player_location.ipynb` contains additional code to further process the dataset, and sort the various player attributes in order.

### Analysis
All scripts written in R are for the purpose of data analysis.

`NeuralNetworkClassifier.ipynb` contains the code for the fully connected neural network classifier.
