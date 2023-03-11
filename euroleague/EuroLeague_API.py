#%% EuroLeague API  

import requests
import pandas as pd
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

#%%

df_game_events, df_game_shots, df_boxscore = get_games(n_games = 216, season = range(2022,2023))
#df_game_shots = get_games(n_games = 1, season = range(2020, 2021))
#%%
#df_game_shots["GAME_ID"].unique()

df_game_events.to_pickle("df_game_events.pkl")
df_boxscore.to_pickle("df_boxscore.pkl")
df_game_shots.to_pickle("df_game_shots.pkl")

#%%

#-- Strip degli spazi

df_single_player = df_boxscore[df_boxscore["Player_ID"] == 'PJDR      ']
df_single_player["2P"] = df_boxscore["FieldGoalsMade2"] * 2
df_single_player["3P"] = df_boxscore["FieldGoalsMade3"] * 3


#df_boxscore.to_csv("df_boxscore.csv")

#%%
import plotly.express as px
import plotly.graph_objects as go
#%%
px.bar(data_frame = df_single_player,
       x = "GAME_ID",
       y = ["2P", "3P", "FreeThrowsMade"],
       title = "Player Stats",
       hover_data = ["Points"],
       labels = {})

#%%
fig = go.Figure()
fig.add_traces(
    go.Bar(
        x = df_single_player["GAME_ID"],
        y = df_single_player["2P"],
        name = "2 Points Made"
    )
)
fig.add_traces(
    go.Bar(
        x = df_single_player["GAME_ID"],
        y = df_single_player["3P"],
        name = "3 Points Made"
    )
)
fig.add_traces(
    go.Bar(
        x = df_single_player["GAME_ID"],
        y = df_single_player["FreeThrowsMade"],
        name = "Free Throws Made",
        text = df_single_player["Points"],
        textposition = "outside",
    )
)

fig.update_layout(barmode = 'stack',
                  xaxis_tickangle = -45,
                  title_text = 'Point By Game'
                  )

# %%

import pycelonis
from pycelonis import get_celonis
from pycelonis import pql

print(pycelonis.__version__)

celonis = get_celonis(
    base_url = "alberto-filosa-protiviti-it.training.celonis.cloud",
    api_token = "NzQ4Mzg3YjctNzkzNy00ZTFhLWE5ZTUtN2Y5NDk0MGVhYWJiOnlHK2xYb3NKRHpwTitGU053NUxOT2ZDZFZOUllKaXNsNWlUeGFwVnJ0UTc3",
    key_type = 'USER_KEY'
)
# %%

df_game_events = pickle.load(open("/home/alberto/Git/basket-report/df_game_events.pkl",'rb'))
df_boxscore = pickle.load(open("/home/alberto/Git/basket-report/df_boxscore.pkl",'rb'))
df_game_shots = pickle.load(open("/home/alberto/Git/basket-report/df_game_shots.pkl",'rb'))

# %%

dp_euroleague = celonis.data_integration.get_data_pool("26a8fa87-21b1-4850-9447-48c2e6a171fc")

dp_euroleague.create_table(table_name = "BoxScore", df = df_boxscore, drop_if_exists = True, force = True)
dp_euroleague.create_table(table_name = "GameEvents", df = df_game_events, drop_if_exists = True, force = True)
dp_euroleague.create_table(table_name = "GameShots", df = df_game_shots, drop_if_exists = True, force = True)

#%%
df = df_boxscore.groupby(["GAME_ID", "Team"]).sum()
df["Point_Diff"] = df.groupby('GAME_ID')['Points'].diff()
df["Point_Diff"] = df['Point_Diff'].fillna(-df['Point_Diff'].shift(-1))

df['Result'] = df['Point_Diff'].apply(lambda x: 'W' if x > 0 else 'L')
df

#%%
#df.groupby('Team')['Result'].value_counts()
df['Cumulative_Wins_Team'] = df.groupby('Team')['Result'].apply(lambda x: (x == 'W').cumsum())
#df.reset_index(drop = True).sort_values(by = 'GAME_ID')

# %% 