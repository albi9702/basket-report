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
#-- of the match and event log of the shot

get_game <- function(nr, year) {
  
  #-- Get Link
  link_game <- fromJSON(paste0(
    "http://live.euroleague.net/api/PlayByPlay?gamecode=", nr,
    "&seasoncode=E", year
  ))
  
  link_shot <- fromJSON(paste0(
    "http://live.euroleague.net/api/Points?gamecode=", nr,
    "&seasoncode=E", year
  ))
  
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
    
    df_quarter <- data.table::rbindlist(quarter)
    df_all_quarters <- dplyr::bind_rows(df_quarter, df_all_quarters)
    
  }
  
  #-- Get Shots
  df_shots <- data.table::rbindlist(link_shot$Rows)
  
  #-- Trim all elements
  df_all_quarters <- df_all_quarters %>% 
    mutate_if(is.character, str_trim) %>%
    arrange(NUMBEROFPLAY)

  df_shots <- df_shots %>% 
    mutate_if(is.character, str_trim) %>%
    arrange(NUM_ANOT)
  
  return(list(df_all_quarters, df_shots))
  
}

#-- The function @download_all_games takes in input the season to download and
#-- the amount of matches to download and insert in a single Data Frame. The
#-- function prints out also the time of downloading. The function returns
#-- a list of two Data Frames: all events and shots in matches

download_all_games <- function(season, n_games){
  
  #-- Select Season to insert in the URL
  
  #-- Empty DataFrame of games and shots. Cycle for will insert single games
  df_all_games <- data.frame()
  df_all_shots <- data.frame()
  
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
                    mutate(GAME_ID = match)
    current_shot <- as.data.frame(get_game(match,
                                           season)[2]) %>%
                    mutate(GAME_ID = match)
  
    #-- Concatenation of all games in single dataframe 
    df_all_games <- bind_rows(df_all_games,
                              current_game)
    df_all_shots <- bind_rows(df_all_shots,
                              current_shot)
  
    }
     
  
  #-- End of loop to measure time of downloading
  end_time <- Sys.time()
  
  print("Download complete!")
  
  print(end_time - start_time)
  
    return(list(df_all_games, df_all_shots))

}

download <- readline("Do you want to download the matches? [Y/n] ")

if (download == tolower(download)) {
  
  print("Downloading file ...")
  gv_df_all_games <- download_all_games(season = 2021,
                                        n_games = 3)
} else {
  "You loaded the file"
}

gv_df_all_events <- gv_df_all_games[[1]]
gv_df_all_shots <- gv_df_all_games[[2]]


df_all_games %>%
  mutate_if(is.character, str_trim) %>%
  group_by(PLAYER_ID) %>%
  count(PLAYTYPE) %>%
  filter(PLAYER_ID == "P007432")

#-- Set Up Data Frames for a Data Model

gv_df_player_id <- gv_df_all_events %>%
  select(CODETEAM, PLAYER_ID, PLAYER, DORSAL, TEAM) %>%
  filter(!(PLAYER_ID == "") & !(PLAYER == "")) %>%
  unique() %>%
  arrange(CODETEAM, as.integer(DORSAL))

gv_df_playtype <- gv_df_all_events %>% 
  separate(PLAYINFO,
           into = c("PLAYINFO", "Other"),
           sep = "[(].") %>%
  select(PLAYINFO, PLAYTYPE) %>%
  mutate_if(is.character, str_trim) %>%
  unique() %>%
  filter(!(PLAYINFO == ""))
