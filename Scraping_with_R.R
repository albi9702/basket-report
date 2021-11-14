#-- Librerie ----
library(rvest)
library(lubridate)
library(xml2)
library(dplyr)
library(stringr)
library(plotly)

#-- Variabili ----

#id_games    <- c(455:458)
id_calendar <- c(1801:1816)

all_games <- NULL

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
  
  if (scrape == TRUE) {
    
    for (games in id_calendar) {
      
      #-- Richiamo della Funzione
      home_team <- scrape_table(team = "homeTable",
                                id_game = games)
      away_team <- scrape_table(team = "awayTable",
                                id_game = games)
      
      #-- Aggiunta della Squadra Avversaria
      home_team <- home_team %>%
                   mutate(avversario = away_team$squadra[1])
      away_team <- away_team %>%
                   mutate(avversario = home_team$squadra[1])
      
      #-- Concatenazione del Tabellino
      all_games <- bind_rows(all_games, home_team)
      all_games <- bind_rows(all_games, away_team)
      
    }
    
    #-- Salvataggio File RDS
    saveRDS(all_games, "all_games.rds")
    
  } else {
    
    #-- Recupero del File
    all_games <- readRDS("all_games.rds")
    print("La tabella è già stata scaricata")

  }
  
  #-- Trasformazione in colonne Numeriche
  for (i in colnames(all_games[, c(2:5)])) all_games[, i] <- as.numeric(all_games[, i])
  
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
  fig <- plot_ly(stats,
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
  
  return(fig)
}

plot_stats(team = "scuola basket murat",
           scrape = FALSE)