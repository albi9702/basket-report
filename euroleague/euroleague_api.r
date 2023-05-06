#-- The function ipak takes in input a list of packages and automatically
#-- detect if a package is not installed, otherwise load it. It returns a
#-- prompt of loaded packages

ipak <- function(package) {
  new_package <- package[!(package %in% installed.packages()[, "Package"])]

  if (length(new_package)) {
    install.packages(new_package,
                     dependencies = TRUE
    )
  }
  sapply(package, require,
         character.only = TRUE
  )
}

ipak(c(
  "rjson", "tidyr", "dplyr",
  "WriteXLS", "RJSONIO", "tidyverse"
))

#-- The function get_gate takes in input the number of game code in the EuroLeague
#-- URL and the season. For example, this URL return the JSON file of the first
#-- game of the 2021-2022 season. The function returns a list of the event log
#-- of the match and event log of the shot of the single game

get_game <- function(nr, year) {

  #-- Local Variables:
  #-- @nr    = number of ID game (based on Euroleague)
  #-- @year  = year of the Season


  #-- Get Link of the Play by Play game
  link_game <- RJSONIO::fromJSON(
                paste0("http://live.euroleague.net/api/PlayByPlay?gamecode=",
                       nr,
                       "&seasoncode=E",
                       year)
               )

  #-- Get Link of the Shots taken in the game
  link_shot <- RJSONIO::fromJSON(
                paste0("http://live.euroleague.net/api/Points?gamecode=",
                       nr,
                       "&seasoncode=E",
                       year)
                )

  #-- Every Game is divided in 4 Quartes. As in the JSON Play by Play file,
  #-- also all events are divided in 4 quartes. The variable @quarters takes
  #-- the 4 quartes in the game.

  #-- Quarters
  quarters <- list(
    link_game$FirstQuarter,
    link_game$SecondQuarter,
    link_game$ThirdQuarter,
    link_game$ForthQuarter
  )

  #-- Initial Empty DataFrames
  df_all_quarters <- data.frame()
  df_shots        <- data.frame()

  #-- Loop all Quarters
  for (quarter in quarters) {

    df_quarter      <- data.table::rbindlist(quarter)
    df_all_quarters <- dplyr::bind_rows(df_quarter, df_all_quarters)

  }

  #-- Get Shots
  df_shots <- data.table::rbindlist(link_shot$Rows)

  #-- Trim all elements
  df_all_quarters <- df_all_quarters %>%
                     dplyr::mutate_if(is.character,
                                      stringr::str_trim) %>%
                     dplyr::arrange(NUMBEROFPLAY)

  df_shots <- df_shots %>%
              dplyr::mutate_if(is.character,
                               stringr::str_trim) %>%
              dplyr::arrange(NUM_ANOT)

  return(list(df_all_quarters, df_shots))

}

#-- The function get_boxscore takes in input the number of game code in the EuroLeague
#-- URL and the season. It returns the Box Score of the Single Gam for each Team
#-- and for each Player.

get_boxscore <- function(nr, year) {

   #-- Local Variables:
   #-- @nr    = number of ID game (based on Euroleague)
   #-- @year  = year of the Season

   #-- Empty DataFrame to store the Box Score of the entire
   #-- game with all Teams for a single game 
   df_boxscore <- data.frame()

   #-- Get Link of the Box Score of the single Game
   box_score <- RJSONIO::fromJSON(
                  paste0("https://live.euroleague.net/api/Boxscore?gamecode=",
                         nr,
                         "&seasoncode=E",
                         year)
                  )

   #-- Loop for each Team (the JSON file is made in two lists)
   for(team in c(1, 2)){

      #-- Loop for Each element of the JSON String (the single Player)
      for(player in box_score$Stats[[team]][3]){

         #-- From JSON to DataFrame
         df_single_boxscore <- data.table::rbindlist(player)

      }

      #-- Union all Box Score Player stats of the Game from the 2 Teams
      df_boxscore <- dplyr::bind_rows(df_single_boxscore, df_boxscore)

   }

   #-- Add the Game_ID Column to identify the ID Game (8 Int Lenght)
   game_ID_pad <- stringr::str_pad(string	= paste0(nr, year),
                                   width  = 8,
                                   pad    = 0)

   df_boxscore <- df_boxscore %>%
                  dplyr::mutate(Game_ID = game_ID_pad)

   return(df_boxscore)
}


#-- The function @download_all_games takes in input the season to download and
#-- the amount of matches to download and insert in a single Data Frame. The
#-- function prints out also the time of downloading. The function returns
#-- a list of two Data Frames: all events and shots in matches

download_all_games <- function(season, n_games){

  #-- Select Season to insert in the URL

  #-- Empty DataFrame of games and shots. Cycle for will insert single games
  df_all_games    <- data.frame()
  df_all_shots    <- data.frame()
  df_all_boxscore <- data.frame()

  #-- Start of loop to measure time of downloading
  start_time <- Sys.time()

  for (match in c(1 : n_games)) {

    #-- Print only a multiple of 10 games
    if (match %% 2 == 0) {
      print(paste0("Downloading match number ",
                   match))
    }

    #-- Download single game with get_game function
    #-- Added a column identifying the id game
    current_game <- as.data.frame(get_game(match,
                                           season)[1]) %>%
                    dplyr::mutate(GAME_ID = match)

    current_shot <- as.data.frame(get_game(match,
                                           season)[2]) %>%
                    dplyr::mutate(GAME_ID = match)

    current_boxscore <- as.data.frame(get_boxscore(match,
                                                   season))

    #-- Concatenation of all games in single dataframe
    df_all_games <- dplyr::bind_rows(df_all_games,
                                     current_game)

    df_all_shots <- dplyr::bind_rows(df_all_shots,
                                     current_shot)

    df_all_boxscore <- dplyr::bind_rows(df_all_boxscore,
                                        current_boxscore)
    }


  #-- End of loop to measure time of downloading
  end_time <- Sys.time()

  print("Download complete!")

  print(end_time - start_time)

  return(list(df_all_games, df_all_shots, df_all_boxscore))

}

download <- readline("Do you want to download the matches? [Y/n] ")

if (download == tolower(download)) {

  print("Downloading file ...")
  gv_df_all_games <- download_all_games(season = 2021,
                                        n_games = 10)
} else {
  "You loaded the file"
}

gv_df_all_events <- gv_df_all_games[[1]]
gv_df_all_shots <- gv_df_all_games[[2]]
gv_df_all_boxscore <- gv_df_all_games[[3]]

#-- Set Up Data Frames for a Data Model

#-- Player Description
gv_df_player_id <- gv_df_all_events %>%
  select(CODETEAM, PLAYER_ID, PLAYER, DORSAL, TEAM) %>%
  filter(!(PLAYER_ID == "") & !(PLAYER == "")) %>%
  unique() %>%
  arrange(CODETEAM, as.integer(DORSAL))

#-- Playtyoe Description
gv_df_playtype <- gv_df_all_events %>% 
  separate(PLAYINFO,
           into = c("PLAYINFO", "Other"),
           sep = "[(].") %>%
  select(PLAYINFO, PLAYTYPE) %>%
  mutate_if(is.character, str_trim) %>%
  unique() %>%
  filter(!(PLAYINFO == ""))

#-- Stats
gv_df_stats <- gv_df_all_events %>%
  mutate_if(is.character, str_trim) %>%
  group_by(PLAYER_ID) %>%
  count(PLAYTYPE) %>%
  pivot_wider(names_from = PLAYTYPE,
              values_from = n)
