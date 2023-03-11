#%% EuroLeague API  

import requests
import pandas as pd
import numpy as np
import time
import pickle

#-- Naming Convention variables:

#-- * lv_ = local variables
#-- * iv_ = iterable variables
#-- * df_ = Data Frame

#%% 
def get_url(type_url):

    """
    Main Variable:

    @type_url  = identifies the type of JSON file (inserted manually in the function)

    Type of JSON file:

    * Points:     Shot selections of the Game
    * PlaybyPlay: All events of the game
    * Boxscore:   Box Score of all Players in the game

    There is no other Local Variables. Main variables are passed through the main function (get_games):

    * @get_games.n_games = Game identifier of the Single Game
    * @get_games.season    = Year of the season when the game matched

    They uniquely identifies a game in all seasons.
    """

    #-- Concatenation of the URL Game Event
    lv_url = "https://live.euroleague.net/api/" + type_url + "?gamecode=" + get_games.n_games + "&seasoncode=E" + get_games.season

    #-- Try - Except to find if the Game is not started
    try:
        lv_json_file = requests.get(lv_url).json()
    except:
        return print("Can't download the game. The game is not started yet.")

    return lv_json_file

#%%
def get_game_events():

    """
    This functions is used to scrape the data from the API Euroleague data events (Field Goal Made, Attempted, etc.) in a single game.
    In this case, the link used in the @get_url function is PlaybyPlay.
    In this function there is no Local Variables. Main variables are passed through the main function (@get_games):

    * @get_games.n_games = Game identifier of the Single Game
    * @get_games.season  = Year of the season when the game matched

    They uniquely identifies a game in all seasons.
    """

    #-- Get URL from the Function
    lv_json_events = get_url(type_url  = "PlaybyPlay")

    #-- Empty DataFrame to store all Events in quarters in a game
    df_all_quarters = pd.DataFrame()
    
    #-- Loop to find all events in Quartes (also Extra time if necessary)
    for iv_count, iv_quarter in enumerate(lv_json_events):

        #-- Starts FirstQuarter events
        if iv_count > 5:

            #-- From JSON to DataFrame for all Quartes
            df_quarter = pd.DataFrame.from_dict(lv_json_events[iv_quarter])

            #-- Concatenation of all Events in Quarters
            df_all_quarters = pd.concat([df_quarter, df_all_quarters], 
                                        ignore_index = True)

    #-- Add unique identifier as concatenation of Game Code and Season
    df_all_quarters["GAME_ID"] = (str(get_games.n_games) + str(get_games.season)).zfill(10)

    return(df_all_quarters)

#%%
def get_game_shots():

    """
    This functions is used to scrape the data from the API Euroleague Game Shot (Field Goal Made, Attempted, from 3 and 2, etc.) in a single game for a single player.
    In this case, the link used in the @get_url function is Points.
    There is no Local Variables. Main variables are passed through the main function (get_games):

    * @get_games.n_games = Game identifier of the Single Game
    * @get_games.season  = Year of the season when the game matched

    They uniquely identifies a game in all seasons. 
    """

    #-- Get URL from the Function
    lv_json_events = get_url(type_url  = "Points")

    #-- From JSON to DataFrame for Rows Dictionary
    df_all_shots = pd.DataFrame.from_dict(lv_json_events["Rows"])

    #-- Add unique identifier as concatenation of Game Code and Season
    df_all_shots["GAME_ID"] = (str(get_games.n_games) + str(get_games.season)).zfill(10)

    return(df_all_shots)

#%%

def get_boxscore():

    """
    This functions is used to scrape the data from the API Euroleague Box Score (Field Goal Made, Attempted, Minutes, etc.) in a single game for a single player.
    In this case, the link used in the @get_url function is Boxscore.
    There is no Local Variables. Main variables are passed through the main function (get_games):

    @get_games.n_games = Game identifier of the Single Game
    @get_games.season  = Year of the season when the game matched

    They uniquely identifies a game in all seasons. 
    """

    #-- Get URL from the Function
    lv_json_boxscore = get_url(type_url  = "Boxscore")

    #-- Empty DataFrame to store all Events in quarters in a game
    df_all_boxscore = pd.DataFrame()

    #-- The JSON file is divided in 2 Dictionary (1 for each Team)
    for iv_team in lv_json_boxscore["Stats"]:

        #-- From JSON to DataFrame for all Teams
        df_all_boxscore = pd.concat([pd.DataFrame.from_dict(iv_team["PlayersStats"]),
                                     df_all_boxscore],
                                     ignore_index = True)

    #-- Add unique identifier as concatenation of Game Code and Season
    df_all_boxscore["GAME_ID"] = (str(get_games.n_games) + str(get_games.season)).zfill(10)

    return(df_all_boxscore)

#%%

def get_games(n_games, season):

    """
    This functions is used to scrape the previous API Euroleague Events, BoxScore and Game Shot games.
    To do that, it concatenates all games in Data Frames.

    The function takes in input two variables:
    
    * n_games = Game identifier of the Single Game
    * season  = Year of the season when the game matched

    and returns the concatenation of the Three Data Frames from the API
    """

    lv_start_time = time.time()

    df_all_game_events = pd.DataFrame()
    df_all_game_shots  = pd.DataFrame()
    df_all_boxscore    = pd.DataFrame()

    for iv_year in season:

        print("Downloading Season: " + str(iv_year))

        #-- Pass as string the single year to download the data
        get_games.season = str(iv_year)

        for iv_match in range(1, n_games + 1):

            #-- Convert Local Variables in String
            get_games.n_games = str(iv_match)

            if iv_match % 10 == 0:
                print("Downloading match number: " + str(iv_match))

            df_current_game_events = get_game_events()
            df_current_game_shots  = get_game_shots()
            df_current_boxscore    = get_boxscore()

            #-- Concatenation of all games in single DataFrame
            df_all_game_events = pd.concat([df_current_game_events, df_all_game_events], 
                                            ignore_index = True)
            df_all_game_shots  = pd.concat([df_current_game_shots, df_all_game_shots], 
                                            ignore_index = True)
            df_all_boxscore    = pd.concat([df_current_boxscore, df_all_boxscore], 
                                            ignore_index = True)

    lv_end_time = time.time()

    print(lv_end_time - lv_start_time)

    return df_all_game_events, df_all_game_shots, df_all_boxscore

# %% [Import Pickle]

def import_pickle(response = 'Y'):

    if response == 'Y':
        df_game_events = pickle.load(open("/home/alberto/Git/basket-report/euroleague/pickle/df_boxscore.pkl",'rb'))
        df_boxscore = pickle.load(open("/home/alberto/Git/basket-report/euroleague/pickle/df_boxscore.pkl",'rb'))
        df_game_shots = pickle.load(open("/home/alberto/Git/basket-report/euroleague/pickle/df_game_shots.pkl",'rb'))
    else:
        df_game_events, df_game_shots, df_boxscore = get_games(n_games = 216, season = range(2022,2023))

    return [df_game_events, df_game_shots, df_boxscore]

# %% [Cumulative Standings Function]

def get_cumulative_standings(df = import_pickle(response = 'Y')[2]):

    """
    This function takes in input the df_boxscore for all games scraped from the previous functions.
    It returns the cumulative Standings for each Games, in order to identify the trend of the single Team.

    The following Columns are calculated:

    * Point_Diff: Points difference for each Game for each Team;
    * Result [W/L]: Boolean variable to identify if a Team won o lost;
    * Cumulative_Wins_Team: cumulative Wins for each Round and each Team;
    * Round: Round of each Game;
    * Opponent: Opponent Team matched in the Game;
    * Win_Last5 / Win_Last10: Number of Wins in Last 5 / 10 games
    """

    #-- Group the BoxScore table by Team and Game and calculate the sum of the Values
    df_cumulative_standings = df.groupby(["GAME_ID", "Team"]).sum()

    #-- Then calculate the difference between rows. In this case, for each Game calculates the
    #-- point difference between Teams
    df_cumulative_standings['Point_Diff'] = df_cumulative_standings.groupby('GAME_ID')['Points'].diff()
    
    #-- In order to have Not Null values, fill the NaN Values with the opposite value for each Game to the other Team
    df_cumulative_standings['Point_Diff'] = df_cumulative_standings['Point_Diff'].fillna(-df_cumulative_standings['Point_Diff'].shift(-1))

    #-- Create a column to identify if the Team for each Game won (W) or lost (L)
    df_cumulative_standings['Result'] = df_cumulative_standings['Point_Diff'].apply(lambda x: 'W' if x > 0 else 'L')
    
    # In order to identify the trend of wins per each Game, add a cumulative sum for all wins
    df_cumulative_standings['Cumulative_Wins_Team'] = df_cumulative_standings.groupby('Team')['Result'].apply(lambda x: (x == 'W').cumsum())
    df_cumulative_standings = df_cumulative_standings.reset_index().sort_values(by = 'GAME_ID')

    #-- Each Round is composed by 9 games. Number of games are identified from the 3rd to the 6th digit in the GAME_ID column.
    df_cumulative_standings['Round'] =  df_cumulative_standings['GAME_ID'].str[3:6].astype(int) // 10 + 1

    #-- Select the opposite Team for each Game and fill NaN Values with the opposite (it's like a switch of the Teams for each Game)
    df_cumulative_standings['Opponent'] = df_cumulative_standings.groupby('GAME_ID')['Team'].shift(1)
    df_cumulative_standings['Opponent'] = df_cumulative_standings['Opponent'].fillna(df_cumulative_standings.groupby('GAME_ID')['Team'].shift(-1))

    #-- In order to identify the streak, select the Number of Wins from Last 5 and 10 Games
    df_cumulative_standings['Win_Loss'] = np.where(df_cumulative_standings['Result'] == 'W', 1, 0)
    df_cumulative_standings['Win_Last5'] = df_cumulative_standings.groupby('Team')['Win_Loss'].apply(lambda x: x.rolling(5, min_periods=1).sum())
    df_cumulative_standings['Win_Last10'] = df_cumulative_standings.groupby('Team')['Win_Loss'].apply(lambda x: x.rolling(10, min_periods=1).sum())

    return df_cumulative_standings

# %% [Standing Function]

def get_standing():

    """
    This function takes in input the Cumulative Standings developed in the previous function.
    It returns the standing containing all cumulative information about the Euroleague.
    """

    df = get_cumulative_standings()

    # Group the dataframe by Team and calculate the sum of the following Columns
    df_standing = df.groupby("Team").agg(
    {
        "Points": "sum",
        "Point_Diff": "sum",
        'Result': lambda x: (x == 'W').sum(),
        'Opponent': lambda x: (x == 'N').sum(),
        'Win_Last5': "last",
        'Win_Last10': "last",
        'GAME_ID': 'nunique'
    }
    )

    #-- Renaming Columns
    df_standing.columns = ['Points_Made', 'Points_Diff', 'Wins', 'Losses',
                           "Win_Last5", "Win_Last10", "Games"]
    
    #-- Creating the Following new columns
    df_standing['Losses'] = df_standing['Games'] - df_standing['Wins'] #--  Number of Losses
    df_standing["Points_Sub"] = df_standing["Points_Made"] - df_standing["Points_Diff"] #-- Point Sub
    df_standing["Percentage"] = df_standing['Wins'] / df_standing['Games'] #-- Percentage of Wins
    
    #-- Sort Values by Number of Wins and Reset Index
    df_standing = df_standing.sort_values("Wins", ascending=False)
    df_standing = df_standing.reset_index()
    
    return df_standing