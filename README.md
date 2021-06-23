# soccer-predictions
The goal of this project is to figure out which characteristics of players and teams are the most impactful on team success.

## Report
`report.pdf` contains the final report.

## Data
All the original csv files, as well as combined data files, can be found in the `Data` folder.

`match_team_player_complete.csv` contains the combined data. This is our final merged dataset, that is used as input into our various models.
- Each column of the form *loc_attribute*, refers to the *attribute* of the *loc* team.
- Each column of the form *home_attribute_i*, refers to the *attribute* of player *i* on the *loc* team.

All other csv files are intermediate files generated, and used by the various code files.

## Scraper
The code in `Scraper` is used to extract additional data from https://www.fifaindex.com.

## Code
All preprocessing and analysis code is found in the `Code` folder.

### Preprocessing
`preprocess_data.py` is the initial script to generate a merged dataset, by appending additional player and team features onto each row, where each row corresponds to a match.

`data_clean.ipynb` and `data_clean_with_player_location.ipynb` contains additional code to further process the dataset, and sort the various player attributes in order.

### Analysis
All scripts written in R are for the purpose of data analysis.

`NeuralNetworkClassifier.ipynb` contains the code for the fully connected neural network classifier.
