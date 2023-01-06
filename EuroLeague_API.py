#%% EuroLeague API  

import requests
import pandas as pd
import time

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

    @get_games.n_games = Game identifier of the Single Game
    @get_games.season    = Year of the season when the game matched

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
    There is no Local Variables. Main variables are passed through the main function (get_games):

    @get_games.n_games = Game identifier of the Single Game
    @get_games.season    = Year of the season when the game matched

    They uniquely identifies a game in all seasons. 
    """

    #-- Get URL from the Function
    lv_json_events = get_url(type_url  = "PlaybyPlay")

    #-- Empty DataFrame to store all Events in quarters in a game
    df_all_quarters = pd.DataFrame()
    
    #-- Loop to find all events in Quartes (also Extra time if necessary)
    for count, quarter in enumerate(lv_json_events):

        #-- Starts FirstQuarter events
        if count > 5:

            #-- From JSON to DataFrame for all Quartes
            df_quarter = pd.DataFrame.from_dict(lv_json_events[quarter])

            #-- Concatenation of all Events in Quarters
            df_all_quarters = pd.concat([df_quarter, df_all_quarters], 
                                        ignore_index = True)

    #-- Add unique identifier as concatenation of Game Code and Season
    df_all_quarters["GAME_ID"] = (str(get_games.n_games) + str(get_games.season)).zfill(10)

    return(df_all_quarters)

#%%
def get_game_shots():

    """
    There is no Local Variables. Main variables are passed through the main function (get_games):

    @get_games.n_games = Game identifier of the Single Game
    @get_games.season    = Year of the season when the game matched

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
    There is no Local Variables. Main variables are passed through the main function (get_games):

    @get_games.n_games = Game identifier of the Single Game
    @get_games.season    = Year of the season when the game matched

    They uniquely identifies a game in all seasons. 
    """

    #-- Get URL from the Function
    lv_json_boxscore = get_url(type_url  = "Boxscore")

    #-- Empty DataFrame to store all Events in quarters in a game
    df_all_boxscore = pd.DataFrame()

    #-- The JSON file is divided in 2 Dictionary (1 for each Team)
    for team in lv_json_boxscore["Stats"]:

        #-- From JSON to DataFrame for all Teams
        df_all_boxscore = pd.concat([pd.DataFrame.from_dict(team["PlayersStats"]),
                                     df_all_boxscore],
                                     ignore_index = True)

    #-- Add unique identifier as concatenation of Game Code and Season
    df_all_boxscore["GAME_ID"] = (str(get_games.n_games) + str(get_games.season)).zfill(10)

    return(df_all_boxscore)

#%%

def get_games(n_games, season):

    start_time = time.time()

    df_all_game_events = pd.DataFrame()
    df_all_game_shots  = pd.DataFrame()
    df_all_boxscore    = pd.DataFrame()

    for year in season:

        print("Downloading Season: " + str(year))

        #-- Pass as string the single year to download the data
        get_games.season = str(year)

        for match in range(1, n_games + 1):

            #-- Convert Local Variables in String
            get_games.n_games = str(match)

            if match % 10 == 0:
                print("Downloading match number: " + str(match))

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

    end_time = time.time()

    print(end_time - start_time)

    return df_all_game_events, df_all_game_shots, df_all_boxscore

#%%

df_game_events, df_game_shots, df_boxscore = get_games(n_games = 50, season = range(2022, 2023))
#df_game_shots = get_games(n_games = 1, season = range(2020, 2021))
#%%
df_game_shots["GAME_ID"].unique()