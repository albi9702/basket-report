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

  html <- read_html(paste0("https://lombardiacanestro.it/Maschile/Tabellino?idgame=",
                    id_game))

  colnames <- html %>%
    html_nodes(paste0("table#", team, " > thead > tr > th")) %>%
    html_text()

  table <- html %>%
    html_nodes(paste0("table#", team, " > tbody > tr > td")) %>%
    html_text() %>%
    matrix(ncol = length(colnames),
           byrow = TRUE) %>%
    cbind(colnames[1]) %>%
    as.data.frame()
 
  colnames(table) <- c("giocatore", "tiri_liberi", "due_punti",
                       "tre_punti", "punti_totali", "squadra")

  table <- table %>%
    filter(tiri_liberi != "Allenatore")
 
  return(table)
}

#-- Funzione Plotly ----

plot_stats <- function(team, scrape = TRUE){
  
  if (scrape == TRUE) {
    
    for (games in id_calendar) {
      
      home_team <- scrape_table(team = "homeTable", id_game = games)
      away_team <- scrape_table(team = "awayTable", id_game = games)
      
      home_team <- home_team %>% mutate(avversario = away_team$squadra[1])
      away_team <- away_team %>% mutate(avversario = home_team$squadra[1])
      
      all_games <- bind_rows(all_games, home_team)
      all_games <- bind_rows(all_games, away_team)
      
    }
    
  } else {
    
    get(all_games)
    
    print("La tabella è già stata scaricata")
  }
  
  stats <- all_games %>%
    filter(squadra == team) %>%
    group_by(giocatore) %>%
    summarise(punti_medi  = mean(punti_totali),
              due_punti   = mean(due_punti) * 2,
              tre_punti   = mean(tre_punti) * 3,
              tiri_liberi = mean(tiri_liberi)) %>%
    arrange(desc(punti_medi))
  
  fig <- plot_ly(stats,
                 x = ~giocatore,
                 y = ~due_punti,
                 type = 'bar',
                 name = 'Due Punti') %>%
    add_trace(y = ~tre_punti,
              name = 'Tre Punti') %>%
    add_trace(y = ~tiri_liberi,
              name = 'Tiri Liberi') %>%
    layout(yaxis = list(title = 'Punteggio Medio a Partita'),
           xaxis = list(title = 'Giocatore',
                        categoryorder = "array",
                        categoryarray = c("punti_medi","tre_punti",
                                          "due_punti","tiri_liberi")),
           barmode = 'stack')
  
  return(fig)
}

plot_stats("scuola basket murat", FALSE)


#-- Scraping ----
for (games in id_calendar) {

  home_team <- scrape_table(team = "homeTable", id_game = games)
  away_team <- scrape_table(team = "awayTable", id_game = games)

  home_team <- home_team %>% mutate(avversario = away_team$squadra[1])
  away_team <- away_team %>% mutate(avversario = home_team$squadra[1])

  all_games <- bind_rows(all_games, home_team)
  all_games <- bind_rows(all_games, away_team)

}

for (i in colnames(all_games[, c(2:5)])) all_games[, i] <- as.numeric(all_games[, i])

unique(all_games$squadra)

stats <- all_games %>%
  filter(squadra == "scuola basket murat") %>%
  group_by(giocatore) %>%
  summarise(punti_medi  = mean(punti_totali),
            due_punti   = mean(due_punti) * 2,
            tre_punti   = mean(tre_punti) * 3,
            tiri_liberi = mean(tiri_liberi)) %>%
  arrange(desc(punti_medi))

colnames(stats)

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
                      categoryarray = c("punti_medi","tre_punti",
                                        "due_punti","tiri_liberi")),
         barmode = 'stack',
         title = list(text = unique(all_games$squadra)[7],
                      y = 0.95),
         legend = list(title = list(text = '<b>Canestri</b>'),
                       y = 0.95,
                       x = 0.9))
fig
