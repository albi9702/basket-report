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

#-- Libraries ----
ipak(c("rvest", "lubridate", "xml2",
     "dplyr", "stringr", "plotly"))

#-- Funzione di Scraping ----
scraping_table <- function(id_game_html){

    all_games <- NULL
    all_scores <- NULL

    for (game in id_game_html){

      print(game)
      html <- try(read_html(paste0(
                        "https://lombardiacanestro.it/Maschile/Tabellino?idgame=",
                          game)), TRUE)

      ifelse(grepl("Error", html[1]) == TRUE, next, "corretto")

      for (tables in seq(1,3,1)){

        if (tables == 1){

          name_teams <- rvest::html_nodes(html, "table")[tables] %>%
                        rvest::html_table(fill = TRUE) %>%
                        as.data.frame() %>%
                         .[2:3,1]

        } else {

          ifelse(tables == 3, name_teams[c(1,2)] <- name_teams[c(2,1)], NA)

          temp_table <- rvest::html_nodes(html, "table")[tables] %>%
                        rvest::html_table(fill = TRUE) %>% as.data.frame() %>%
                        dplyr::mutate(squadra = str_to_title(name_teams[1]),
                                      avversario = str_to_title(name_teams[2]),
                                      partita = ifelse(tables == 2, "C", "T"),
                                      id_gara = game)

          colnames(temp_table) <- c("giocatore", "tiri_liberi", "due_punti",
                                    "tre_punti", "punti_totali", "squadra",
                                    "avversario", "partita","id_gara")

          ifelse(temp_table$giocatore == 'Tabellino non disponibile',
                 next,
                 all_games <- dplyr::bind_rows(all_games, temp_table))


        }

      }

    }

      return(all_games)
}

all_table <- scraping_table(id_game_html = c(3427:3466))
head(all_table)

#-- Classifica Complessiva -----

html2 <- read_html("https://lombardiacanestro.it/Maschile/Calendar?id=23&idturn=497")

classifica <- rvest::html_nodes(html2, "table") %>%
                        rvest::html_table(fill = TRUE) %>%
                        as.data.frame()
                        
classifica[, c("Squadra")] <- str_to_title(classifica[, "Squadra"])
colnames(classifica) <- c("posizione", "squadra", "punti",
                          "partite_giocate", "vittorie",
                          "sconfitte", "punti_fatti",
                          "punti_subiti")
