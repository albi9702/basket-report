#-- Librerie ----
library(rvest)
library(lubridate)
library(xml2)
library(dplyr)
library(stringr)
library(plotly)

#-- Variabili ----

#id_games    <- c(455:458)
id_calendar <- c(1801:1832)

#-- Funzione di Scraping ----
scrape_table <- function(team, id_game){

  #-- Lettura del File HTML
  html <- read_html(paste0("https://lombardiacanestro.it/Maschile/Tabellino?idgame=",
                    id_game))

  #-- Scraping Testata di Colonna
  colnames <- html                                  %>%
              html_nodes(paste0("table#",
                         team,
                         " > thead > tr > th"))     %>%
              html_text()

  #-- Scraping Tabella
  table <- html                                     %>%
           html_nodes(paste0("table#",
                             team,
                             " > tbody > tr > td")) %>%
           html_text()                              %>%
           matrix(ncol = length(colnames),
                  byrow = TRUE)                     %>%
           cbind(colnames[1])                       %>%
           as.data.frame()
 
  #-- Rinomina Colonne
  colnames(table) <- c("giocatore"   , "tiri_liberi",
                       "due_punti"   , "tre_punti",
                       "punti_totali", "squadra")

  #-- Filtro su Allenatore
  table <- table %>%
           filter(tiri_liberi != "Allenatore")
 
  return(table)
}

#-- Funzione Plotly ----

plot_stats <- function(team, scrape = TRUE){
  
  all_games <- NULL
  all_scores <- NULL
  
  if (scrape == TRUE) {
    
    for (games in id_calendar) {
      
      #-- Richiamo della Funzione
      home_team <- scrape_table(team = "homeTable",
                                id_game = games)
      away_team <- scrape_table(team = "awayTable",
                                id_game = games)
      
      #-- Aggiunta della Squadra Avversaria
      home_team <- home_team %>%
                   mutate(avversario = away_team$squadra[1],
                          id_game = games)
      away_team <- away_team %>%
                   mutate(avversario = home_team$squadra[1],
                          id_game = games)
      
      #-- Concatenazione del Tabellino
      all_games <- bind_rows(all_games, home_team)
      all_games <- bind_rows(all_games, away_team)
      
      #-- Risultato Finale (Squadra)
      home_points <- home_team %>% summarise(squadra = home_team$squadra[1],
                                             punti = sum(as.numeric(punti_totali)),
                                             games = games)
      away_points <- away_team %>% summarise(squadra = away_team$squadra[1],
                                             punti = sum(as.numeric(punti_totali)),
                                             games = games)
    
      single_score <- rbind(home_points, away_points)
      all_scores <- bind_rows(all_scores, single_score)
      
    }
    
    #-- Salvataggio File RDS
    saveRDS(all_games, "all_games.rds")
    
  } else {
    
    #-- Recupero del File
    all_games <- readRDS("all_games.rds")
    print("La tabella ? gi? stata scaricata")

  }
  
  #-- Trasformazione in colonne Numeriche
  for (i in colnames(all_games[, c(2:5)])) all_games[, i] <- as.numeric(all_games[, i])
  
  all_games[is.na(all_games)] <- 0
  
  team_points <- all_games %>%
    group_by(squadra, id_game, avversario) %>%
    summarise(punti_totali = sum(punti_totali))
  
  team_points <- left_join(team_points,
                 team_points,
                 by = c("avversario" = "squadra",
                        "id_game")) %>%
    select(id_game, squadra, avversario, punti_totali.x, punti_totali.y) %>%
    mutate(differenza = punti_totali.x - punti_totali.y,
           color = differenza > 0) %>%
    filter(squadra == team)
  
  team_points$color[team_points$differenza > 0] <- 'rgba(50, 171, 96, 0.7)'
  team_points$color[team_points$differenza < 0] <- 'rgba(219, 64, 82, 0.7)'
  
  #-- Costruzione Tabella Punteggio Medio
  stats <- all_games                                    %>%
           filter(squadra == team)                      %>%
           group_by(giocatore)                          %>%
           summarise(punti_medi  = mean(punti_totali),
                     due_punti   = mean(due_punti) * 2,
                     tre_punti   = mean(tre_punti) * 3,
                     tiri_liberi = mean(tiri_liberi))   %>%
           arrange(desc(punti_medi))
  
  #-- Costruzione Punteggio Medio a Partita
  fig_player <- plot_ly(stats,
                 x = ~giocatore,
                 y = ~due_punti,
                 type = 'bar',
                 name = 'Due Punti',
                 marker = list(color = 'rgba(50, 171, 96, 0.7)',
                               line = list(color = 'rgba(50, 171, 96, 1.0)',
                                           width = 2))) %>%
    add_trace(y = ~tre_punti,
              name = 'Tre Punti',
              marker = list(color = 'rgba(55, 128, 191, 0.7)',
                            line = list(color = 'rgba(55, 128, 191, 0.7)',
                                        width = 2))) %>%
    add_trace(y = ~tiri_liberi,
              name = 'Tiri Liberi', 
              marker = list(color = 'rgba(219, 64, 82, 0.7)',
                            line = list(color = 'rgba(219, 64, 82, 1.0)',
                                        width = 2))) %>%
    layout(yaxis = list(title = 'Punteggio Medio a Partita'),
           xaxis = list(title = 'Giocatore',
                        categoryorder = "array",
                        categoryarray = c("punti_medi", "tre_punti",
                                          "due_punti",  "tiri_liberi")),
           barmode = 'stack',
           title = list(text = team,
                        y = 0.95),
           legend = list(title = list(text = '<b>Canestri</b>'),
                         y = 0.95,
                         x = 0.9))
  
  
  fig_team <- plot_ly(team_points, x = ~reorder(id_game, avversario),#~seq(1, nrow(team_points)),
          y = ~differenza,
          type = 'bar',
          marker = list(color = ~color)
  ) %>%
    layout(title = "Partite",
           xaxis = list(title = team),
           yaxis = list(title = "Differenza"),
           title = list(text = team,
                        y = 0.95))
  
  return(list(fig_player, fig_team))
}

plot_stats(team = "osal novate",
           scrape = FALSE)
