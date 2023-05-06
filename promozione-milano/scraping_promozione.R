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

ipak(c("rvest", "lubridate", "xml2", 
     "dplyr", "stringr", "plotly"))

#-- Funzione di Scraping ----
scraping_table <- function(id_game_html){

    all_games <- NULL
    all_scores <- NULL

    for (game in id_game_html){

      print(game)
      html <- try(read_html(paste0(
                        "https://lombardia.italiacanestro.it/Maschile/Partita?id=",
                          game)), TRUE)

      ifelse(grepl("Error", html[1]) == TRUE, next, "corretto")

      #-- Data Manipulation --

      #-- First Scraping Table (with no manipulation)
      raw_table <- rvest::html_nodes(html, "table")[2] %>%
                        rvest::html_table(fill = TRUE) %>%
                        as.data.frame()

      team_list  <- na.omit(unique(ifelse(raw_table$X2 == 'PTS', str_to_title(raw_table$X1), NA)))[1:2]
      blank_flag <- as.integer(row.names(raw_table)) < as.integer(row.names(subset(raw_table, X1 == "")))[1]

      temp_table <- raw_table %>%
                    mutate(squadra    = ifelse(blank_flag, team_list[1], team_list[2]), 
                           avversario = ifelse(blank_flag, team_list[2], team_list[1]),
                           partita    = ifelse(blank_flag, "C", "T"),
                           id_gara    = game) %>%
                    filter(!str_detect(X2, 'PTS'))

      temp_table <- temp_table[!apply(is.na(temp_table) | temp_table == "", 1, any),]

      colnames(temp_table) <- c("giocatore", "punti_totali", "tiri_liberi",
                                "due_punti", "tre_punti", "squadra",
                                "avversario", "partita","id_gara")

      temp_table <- temp_table %>%
                    mutate(giocatore = str_to_title(giocatore))
        
      ifelse(temp_table$giocatore == 'Tabellino non disponibile',
                 next,
                 all_games <- dplyr::bind_rows(all_games, temp_table))
        
    }
      return(all_games)
}

players_df <- function(id_html){

    lv_allPlayersName_df   <- NULL #-- DataFrame to store all Players in the League
    
    #-- Read the HTML to scrape Players Data
    lv_html <- read_html(paste0("https://lombardia.italiacanestro.it/Maschile/Roster?id=",
                                id_html))
    
    #-- Range of Tables (Teams) in the HTML link
    lv_lenght_teams <- c(1 : length(rvest::html_nodes(lv_html, "table")))
    
    #-- For each Team, scrape the table
    for (team in lv_lenght_teams){
        
        lv_currentTeam_df <- rvest::html_nodes(lv_html, "table")[team]      %>% #-- Select the n table in the HTML
                             rvest::html_table(header = 1)                  %>% #-- Set the Header
                             .[[1]]                                         %>% #-- Select the first element in the list
                             mutate(squadra = str_to_title(colnames(.)[2]))     #-- Add Team Column to identify the Team's player
        
        colnames(lv_currentTeam_df) <- c("numero", "giocatore", "squadra")      #-- Rename the DataFrame Columns
        
        lv_currentTeam_df <- lv_currentTeam_df %>%
                             mutate(giocatore = str_to_title(giocatore))        #-- Set the Players name to Title
        
        lv_allPlayersName_df <- dplyr::bind_rows(lv_allPlayersName_df,          #-- Concatenate all extracted Table
                                                 lv_currentTeam_df)             #-- into One
    }
    
    #-- Return the Players DataFrame
    return(lv_allPlayersName_df)
}

standing_df <- function(id_html){
    
    #-- Read the HTML to scrape Players Data
    lv_html <- read_html(paste0("https://lombardia.italiacanestro.it/Maschile/Calendario?id=",
                                id_html))
    
    lv_standings_df <- rvest::html_nodes(lv_html, "table")           %>% #-- Select the standing table in the HTML
                       rvest::html_table(header = 1)                 %>% #-- Set the Header
                       .[[2]]                                        %>% #-- Select the second element in the list
                       mutate(CLASSIFICA = str_to_title(CLASSIFICA))     #-- Set the Teams name to Title
    
    colnames(lv_standings_df) <- c("posizione", "squadra",   "punti",       "partite_giocate",
                                    "vittorie",  "sconfitte", "punti_fatti", "punti_subiti")
 
    return(lv_standings_df)
}

all_table <- scraping_table(id_game_html = c(5508:5714))
allPlayersName <- players_df(id_html = "42")
allStanding <- standing_df(id_html = "42")