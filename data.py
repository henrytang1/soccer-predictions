import numpy as np
import pandas as pd
from datetime import timedelta

# get closest match from "df2" to a row from "match"
# if no earlier time exists in df2, then match remains unchanged
def closest_player_time(match, **kwds):
    df2 = kwds['df2']
    num = kwds['num']
    loc = kwds['loc']
    corresponding = df2.loc[(df2[f'player_id'] == match[f'{loc}_player_{num}'])]

    deltas = match.date - corresponding.date
    corresponding = corresponding.loc[deltas >= timedelta(0)]
    deltas = deltas.loc[deltas >= timedelta(0)]

    try:
        prev_data = corresponding.loc[deltas.idxmin()]
        new_time = prev_data.date
    except ValueError:  # no items
        new_time = match.date
    
    match.date = new_time
    return match

# get closest match from "df2" to a row from "match"
# if no earlier time exists in df2, then match remains unchanged
def closest_team_time(match, **kwds):
    df2 = kwds['df2']
    loc = kwds['loc']
    corresponding = df2.loc[(df2[f'team_id'] == match[f'{loc}_team_id'])]

    deltas = match.date - corresponding.date
    corresponding = corresponding.loc[deltas >= timedelta(0)]
    deltas = deltas.loc[deltas >= timedelta(0)]

    try:
        prev_data = corresponding.loc[deltas.idxmin()]
        new_time = prev_data.date
    except ValueError:  # no items
        new_time = match.date
    
    match.date = new_time
    return match

def main():
    country = pd.read_csv('country.csv')
    league = pd.read_csv('league.csv')

    player = pd.read_csv('player.csv')
    player['birthday'] = pd.to_datetime(player['birthday'])
    old_player = player.copy()

    match = pd.read_csv('match.csv')
    match['date'] = pd.to_datetime(match['date'])
    old_match = match.copy()

    team_attributes = pd.read_csv('team_attributes.csv')
    team_attributes['date'] = pd.to_datetime(team_attributes['date'])
    old_team_attributes = team_attributes.copy()

    player_attributes = pd.read_csv('player_attributes.csv')
    player_attributes['date'] = pd.to_datetime(player_attributes['date'])
    old_player_attributes = player_attributes.copy()

    ####################### Merge Country and League Data #######################
    country.rename(columns={'name':'country_name'}, inplace=True)
    match = match.merge(country, how='left', on='country_id')
    league.rename(columns={'name':'league_name'}, inplace=True)
    match = match.merge(league[['league_id','league_name']], how='left', on='league_id')

    ####################### Merge Team Data #######################
    loc = 'home'
    match = match.apply(closest_team_time, df2=team_attributes, loc = loc, axis=1)

    team_attributes.columns = f'{loc}_' + old_team_attributes.columns.values
    match = match.merge(team_attributes, how='left', left_on=[f'{loc}_team_id', 'date'], right_on=[f'{loc}_team_id', f'{loc}_date']).drop(f'{loc}_date', axis=1)

    match.loc[match.match_id.isin(old_match.match_id), ['date']] = old_match[['date']]


    team_attributes = old_team_attributes.copy()
    loc = 'away'
    match = match.apply(closest_team_time, df2=team_attributes, loc = loc, axis=1)

    team_attributes.columns = f'{loc}_' + old_team_attributes.columns.values
    match = match.merge(team_attributes, how='left', left_on=[f'{loc}_team_id', 'date'], right_on=[f'{loc}_team_id', f'{loc}_date']).drop(f'{loc}_date', axis=1)

    match.loc[match.match_id.isin(old_match.match_id), ['date']] = old_match[['date']]

    # ####################### Merge Player Data #######################
    loc = 'home'
    for i in range(1, 12):
        print(loc, i)
        # to reset column names
        player_attributes = old_player_attributes.copy()
        player = old_player.copy()

        # replace dates with dates that match player_attributes
        match = match.apply(closest_player_time, df2=player_attributes, num=i, loc=loc, axis=1)

        # rename columns and combine
        player_attributes.columns = f'{loc}_' + old_player_attributes.columns.values + f'_{i}'
        match = match.merge(player_attributes, how='left', left_on=[f'{loc}_player_{i}', 'date'], 
            right_on=[f'{loc}_player_id_{i}', f'{loc}_date_{i}']).drop([f'{loc}_player_id_{i}', f'{loc}_date_{i}'], axis=1)
        
        player.columns = f'{loc}_' + old_player.columns.values + f'_{i}'
        match = match.merge(player, how='left', left_on=[f'{loc}_player_{i}'], 
            right_on=[f'{loc}_player_id_{i}']).drop([f'{loc}_player_id_{i}'], axis=1)

        match.loc[match.match_id.isin(old_match.match_id), ['date']] = old_match[['date']]

    loc = 'away'
    for i in range(1, 12):
        print(loc, i)
        # to reset column names
        player_attributes = old_player_attributes.copy()
        player = old_player.copy()

        # replace dates with dates that match player_attributes
        match = match.apply(closest_player_time, df2=player_attributes, num=i, loc=loc, axis=1)

        # rename columns and combine
        player_attributes.columns = f'{loc}_' + old_player_attributes.columns.values + f'_{i}'
        match = match.merge(player_attributes, how='left', left_on=[f'{loc}_player_{i}', 'date'], 
            right_on=[f'{loc}_player_id_{i}', f'{loc}_date_{i}']).drop([f'{loc}_player_id_{i}', f'{loc}_date_{i}'], axis=1)
        
        player.columns = f'{loc}_' + old_player.columns.values + f'_{i}'
        match = match.merge(player, how='left', left_on=[f'{loc}_player_{i}'], 
            right_on=[f'{loc}_player_id_{i}']).drop([f'{loc}_player_id_{i}'], axis=1)

        match.loc[match.match_id.isin(old_match.match_id), ['date']] = old_match[['date']]

    match.to_csv('match_team_player.csv', index=False)

if __name__ == "__main__":
    # res = pd.read_csv('match_team_player.csv')
    # print(len(res.columns))
    # col = []
    # for i in range(1, 12):
    #     col += [f'home_player_id_{i}']
    #     col += [f'away_player_id_{i}']
    # res = res.drop(col, axis=1)
    # print(len(res.columns))
    # res.to_csv('match_team_player_new.csv', index=False)
    # exit()
    main()