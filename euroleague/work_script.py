#%% [Libraries]
import pickle
import numpy as np

# %% [Load Pickle]

df_game_events = pickle.load(open("/home/alberto/Git/basket-report/euroleague/pickle/df_boxscore.pkl",'rb'))
df_boxscore = pickle.load(open("/home/alberto/Git/basket-report/euroleague/pickle/df_boxscore.pkl",'rb'))
df_game_shots = pickle.load(open("/home/alberto/Git/basket-report/euroleague/pickle/df_game_shots.pkl",'rb'))

# %% [Set Cumulative Standings]

df_cumulative_standings = df_boxscore.groupby(["GAME_ID", "Team"]).sum()
# Group the rows by GAME_ID and calculate the difference
df_cumulative_standings['Point_Diff'] = df_cumulative_standings.groupby('GAME_ID')['Points'].diff()

# Fill the NaN values with the opposite of the previous non-null value
df_cumulative_standings['Point_Diff'] = df_cumulative_standings['Point_Diff'].fillna(-df_cumulative_standings['Point_Diff'].shift(-1))

# Create a new column with 'W' if the difference is positive, 'N' otherwise
df_cumulative_standings['Result'] = df_cumulative_standings['Point_Diff'].apply(lambda x: 'W' if x > 0 else 'N')

# Add a cumulative sum for all wins in the Result column for each team
df_cumulative_standings['Cumulative_Wins_Team'] = df_cumulative_standings.groupby('Team')['Result'].apply(lambda x: (x == 'W').cumsum())

# Reset the index and sort by ascending GAME_ID
df_cumulative_standings = df_cumulative_standings.reset_index().sort_values(by = 'GAME_ID')
df_cumulative_standings

# %%
# Extract the round number from the game_id column and add it as a new column
df_cumulative_standings['Round'] =  df_cumulative_standings['GAME_ID'].str[3:6].astype(int) // 10 + 1

# select the opposite team for each row within the same GAME_ID
df_cumulative_standings['Opponent'] = df_cumulative_standings.groupby('GAME_ID')['Team'].shift(1)
df_cumulative_standings['Opponent'] = df_cumulative_standings['Opponent'].fillna(df_cumulative_standings.groupby('GAME_ID')['Team'].shift(-1))
df_cumulative_standings
#%%
df_cumulative_standings['Win_Loss'] = np.where(df_cumulative_standings['Result'] == 'W', 1, 0)
df_cumulative_standings['Win_Last5'] = df_cumulative_standings.groupby('Team')['Win_Loss'].apply(lambda x: x.rolling(5, min_periods=1).sum())
df_cumulative_standings['Win_Last10'] = df_cumulative_standings.groupby('Team')['Win_Loss'].apply(lambda x: x.rolling(10, min_periods=1).sum())
df_cumulative_standings

# %%

df_standing = df_cumulative_standings.groupby("Team").agg(
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
df_standing.columns = ['Points_Made', 'Points_Diff', 'Wins', 'Losses', "Win_Last5", "Win_Last10", "Games"]
df_standing['Losses'] = df_standing['Games'] - df_standing['Wins']
df_standing["Points_Sub"] = df_standing["Points_Made"] - df_standing["Points_Diff"]
df_standing["Percentage"] = df_standing['Wins'] / df_standing['Games']
df_standing = df_standing.sort_values("Wins", ascending=False)
df_standing = df_standing.reset_index()
df_standing

# --------------------------------------------------------------------------------------------------------
#%% ------------------------------------------------------------------------------------------------------

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

from EuroLeague_API import get_games