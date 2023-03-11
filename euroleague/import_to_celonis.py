# %% [Libraries]
import pycelonis
import numpy as np
from pycelonis import get_celonis
from pycelonis import pql
print(pycelonis.__version__)

import EuroLeague_API as el

# %% [Scraping from API]

df_game_events, df_game_shots, df_boxscore = el.import_pickle()
df_cumulative_standings = el.get_cumulative_standings()
df_standings = el.get_standing()

# %% [Import into Celonis]

celonis = get_celonis(
    base_url = "alberto-filosa-protiviti-it.training.celonis.cloud",
    api_token = "NzQ4Mzg3YjctNzkzNy00ZTFhLWE5ZTUtN2Y5NDk0MGVhYWJiOnlHK2xYb3NKRHpwTitGU053NUxOT2ZDZFZOUllKaXNsNWlUeGFwVnJ0UTc3",
    key_type = 'USER_KEY'
)

dp_euroleague = celonis.data_integration.get_data_pool("26a8fa87-21b1-4850-9447-48c2e6a171fc")

dp_euroleague.create_table(table_name = "BoxScore", df = df_boxscore, drop_if_exists = True, force = True)
dp_euroleague.create_table(table_name = "GameEvents", df = df_game_events, drop_if_exists = True, force = True)
dp_euroleague.create_table(table_name = "GameShots", df = df_game_shots, drop_if_exists = True, force = True)
