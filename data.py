import numpy as np
import pandas as pd
from datetime import timedelta
from Scraper.get_pos import get_poss

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
        new_idx = prev_data.idx
    except ValueError:  # no items
        new_idx = -1
    
    match.idx = new_idx
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
        new_idx = prev_data.idx
    except ValueError:  # no items
        new_idx = -1
    
    match.idx = new_idx
    return match

def main():
    country = pd.read_csv('country.csv')
    league = pd.read_csv('league.csv')

    player = pd.read_csv('player.csv')
    player['birthday'] = pd.to_datetime(player['birthday'])
    old_player = player.copy()

    match = pd.read_csv('match.csv')
    match['date'] = pd.to_datetime(match['date'])
    idx = []
    for i in range(len(match.index)):
        idx += [-1]
    match.insert(0, "idx", idx)
    old_match = match.copy()

    team_attributes = pd.read_csv('team_attributes.csv')
    team_attributes['date'] = pd.to_datetime(team_attributes['date'])
    idx = []
    for i in range(len(team_attributes.index)):
        idx += [i]
    team_attributes.insert(0, "idx", idx)
    old_team_attributes = team_attributes.copy()

    player_attributes = pd.read_csv('player_attributes_w_position.csv')
    player_attributes['date'] = pd.to_datetime(player_attributes['date'])
    idx = []
    for i in range(len(player_attributes.index)):
        idx += [i]
    player_attributes.insert(0, "idx", idx)
    old_player_attributes = player_attributes.copy()
    
    ####################### Merge Country and League Data #######################
    country.rename(columns={'name':'country_name'}, inplace=True)
    match = match.merge(country, how='left', on='country_id')
    league.rename(columns={'name':'league_name'}, inplace=True)
    match = match.merge(league[['league_id','league_name']], how='left', on='league_id')

    ####################### Merge Team Data #######################
    loc = 'home'
    match = match.assign(idx=-1)
    match = match.apply(closest_team_time, df2=team_attributes, loc = loc, axis=1)

    team_attributes.columns = f'{loc}_' + old_team_attributes.columns.values
    team_attributes = team_attributes.rename(columns = {f'{loc}_team_id':f'{loc}_team_id_copy'})
    match = match.merge(team_attributes, how='left', left_on=[f'idx'], right_on=[f'{loc}_idx']).drop([f'{loc}_idx', f'{loc}_team_id_copy', f'{loc}_date'], axis=1)

    # match.loc[match.match_id.isin(old_match.match_id), ['date']] = old_match[['date']]

    team_attributes = old_team_attributes.copy()
    loc = 'away'
    match = match.assign(idx=-1)
    match = match.apply(closest_team_time, df2=team_attributes, loc = loc, axis=1)

    team_attributes.columns = f'{loc}_' + old_team_attributes.columns.values
    team_attributes = team_attributes.rename(columns = {f'{loc}_team_id':f'{loc}_team_id_copy'})
    match = match.merge(team_attributes, how='left', left_on=[f'idx'], right_on=[f'{loc}_idx']).drop([f'{loc}_idx', f'{loc}_team_id_copy', f'{loc}_date'], axis=1)

    # match.loc[match.match_id.isin(old_match.match_id), ['date']] = old_match[['date']]

    # ####################### Merge Player Data #######################
    loc = 'home'
    for i in range(1, 12):
        print(loc, i)
        print(len(match.index))
        
        match = match.assign(idx=-1)
        # to reset column names
        player_attributes = old_player_attributes.copy()
        player = old_player.copy()

        # replace dates with dates that match player_attributes
        match = match.apply(closest_player_time, df2=player_attributes, num=i, loc=loc, axis=1)

        # rename columns and combine
        player_attributes.columns = f'{loc}_' + old_player_attributes.columns.values + f'_{i}'
        match = match.merge(player_attributes, how='left', left_on=['idx'], 
            right_on=[f'{loc}_idx_{i}']).drop([f'{loc}_idx_{i}', f'{loc}_player_id_{i}', f'{loc}_date_{i}'], axis=1)
        
        player.columns = f'{loc}_' + old_player.columns.values + f'_{i}'
        match = match.merge(player, how='left', left_on=[f'{loc}_player_{i}'], 
            right_on=[f'{loc}_player_id_{i}']).drop([f'{loc}_player_id_{i}'], axis=1)

    loc = 'away'
    for i in range(1, 12):
        print(loc, i)
        print(len(match.index))

        match = match.assign(idx=-1)
        # to reset column names
        player_attributes = old_player_attributes.copy()
        player = old_player.copy()

        # replace dates with dates that match player_attributes
        match = match.apply(closest_player_time, df2=player_attributes, num=i, loc=loc, axis=1)

        # rename columns and combine
        player_attributes.columns = f'{loc}_' + old_player_attributes.columns.values + f'_{i}'
        match = match.merge(player_attributes, how='left', left_on=['idx'], 
            right_on=[f'{loc}_idx_{i}']).drop([f'{loc}_idx_{i}', f'{loc}_player_id_{i}', f'{loc}_date_{i}'], axis=1)
        
        player.columns = f'{loc}_' + old_player.columns.values + f'_{i}'
        match = match.merge(player, how='left', left_on=[f'{loc}_player_{i}'], 
            right_on=[f'{loc}_player_id_{i}']).drop([f'{loc}_player_id_{i}'], axis=1)

    match = match.drop(['idx'], axis=1)
    match.to_csv('match_team_player_w_position.csv', index=False)


def check_data():
    match = pd.read_csv('match_team_player.csv')
    print(len(match.columns))
    # match = match.drop(['idx'], axis=1)
    print(len(match['date']))
    print(match['date'].unique)
    # match.to_csv('match_team_player.csv', index=False)

    league = pd.read_csv('league.csv')
    print(len(league['league_id']))  
    print(league['league_id'].unique)
  

def add_position():
    player = pd.read_csv('player.csv')
    pos = pd.read_csv('FullData.csv')
    # print(pos.columns)
    player = player.merge(pos[['Name', 'Club_Position']], how='left', left_on=['player_name'], 
            right_on=['Name']).drop([f'Name'], axis=1)
    
    player.to_csv('new_stuff.csv', index=False)
    print(player)


def search_player(row, **kwds):
    df_list = kwds['df_list']
    num_years = kwds['num_years']
    df = None
    exists = False
    # print(row.player_name)
    # print(df_list[0].iloc[2]['Name'])
    # print(row.player_name == df_list[0].iloc[2]['Name'])
    # print("WWWW")
    for i in range(num_years-1, -1, -1):
        # print(i)
        cur_df = df_list[i]
        # print("asdf")
        # print(cur_df)
        if cur_df['Name'].str.contains(row.player_name).any():
            df = cur_df.loc[(cur_df['Name'] == row['player_name'])]
            exists = True
            break

    # break
    if not exists:
        print(f"{row.player_name} not found in FIFA")
        return row
    # print(df.iloc[0]['url'])
    # exit()

    row.real_pos = get_poss(df.iloc[0]['url'])
    print(f"{row.player_name} has position {row.real_pos}")

    return row


def get_pos():
    player = pd.read_csv('player_actual_pos.csv')
    idx = []
    for i in range(len(player.index)):
        idx += [None]
    player.insert(len(player.columns), "real_pos", idx)

    # print(player.columns)

    df_list = []
    year = ['09', '10', '11', '12', '13', '14', '15', '16']
    for y in year:
        df_list += [pd.read_csv(f'Scraper/Names-{y}.csv')]
        df_list[-1]['Name'] = df_list[-1]['Name'].apply(lambda x: x.replace(f" FIFA {y}", ""))
        
        # print(df_list[-1])

    player = player.apply(search_player, df_list=df_list, num_years = len(year), axis=1)

    player.to_csv('new_stuff.csv', index=False)


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
    # main()
    # check_data()
    get_pos()