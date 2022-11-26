# Scraping Ado

This script shows how to scrape data from [LombardiaCanestro](https://lombardia.italiacanestro.it/). In this case, scrape the Promozione - Girone E League. Here the list of all Teams:

* [Aurora Trezzo](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=482).
* [Posal Sesto San Giovanni](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=483).
* [Ado San Benedetto Milano](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=484).
* [CGB Brugherio](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=485).
* [Azzurri Niguardese](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=486).
* [Pallacanestro Carugate](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=487).
* [CBBA Olimpia Cologno](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=488).
* [Cesano Seveso](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=489).
* [Inzago Basket](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=490).
* [OSAL Novate](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=491).
* [Basket Ajaccio 1988](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=492).
* [Social OSA](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=493).
* [Basket San Rocco 2013 Seregno](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=494).
* [Ciesse Freebasket Milano](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=495).
* [ACLI Trecella](https://lombardia.italiacanestro.it/Maschile/Squadra?id=42&tid=496).

## R Script

The following cells shows the scrape script from the LombardiaCanestro Site. Scrape data:

* *All games*, with this link: `https://lombardia.italiacanestro.it/Maschile/Partita?id=`***`<id_game>`***
* *Standings*, with this link: `https://lombardia.italiacanestro.it/Maschile/Calendario?id=`***`42`***
* *Rosters*, with this link: `https://lombardia.italiacanestro.it/Maschile/Roster?id=`***`42`***

### Libraries

Used libraries:

* `rvest`.
* `lubridate`.
* `xml2`.
* `dplyr`.
* `stringr`.
* `plotly`.


```python
%load_ext rpy2.ipython
```

    /home/jovyan/.local/lib/python3.8/site-packages/pandas/core/computation/expressions.py:20: UserWarning: Pandas requires version '2.7.3' or newer of 'numexpr' (version '2.7.2' currently installed).
      from pandas.core.computation.check import NUMEXPR_INSTALLED



```r
%%R

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
```

    R[write to console]: Loading required package: rvest
    
    R[write to console]: Loading required package: lubridate
    
    [0;1;31mSystem has not been booted with systemd as init system (PID 1). Can't operate.[0m
    [0;1;31mFailed to create bus connection: Host is down[0m
    R[write to console]: 
    Attaching package: ‘lubridate’
    
    
    R[write to console]: The following objects are masked from ‘package:base’:
    
        date, intersect, setdiff, union
    
    
    R[write to console]: Loading required package: xml2
    
    R[write to console]: Loading required package: dplyr
    
    R[write to console]: 
    Attaching package: ‘dplyr’
    
    
    R[write to console]: The following objects are masked from ‘package:stats’:
    
        filter, lag
    
    
    R[write to console]: The following objects are masked from ‘package:base’:
    
        intersect, setdiff, setequal, union
    
    
    R[write to console]: Loading required package: stringr
    
    R[write to console]: Loading required package: plotly
    
    R[write to console]: Loading required package: ggplot2
    
    R[write to console]: 
    Attaching package: ‘plotly’
    
    
    R[write to console]: The following object is masked from ‘package:ggplot2’:
    
        last_plot
    
    
    R[write to console]: The following object is masked from ‘package:stats’:
    
        filter
    
    
    R[write to console]: The following object is masked from ‘package:graphics’:
    
        layout
    
    


        rvest lubridate      xml2     dplyr   stringr    plotly 
         TRUE      TRUE      TRUE      TRUE      TRUE      TRUE 


### Games Scraping

<!-- Inserire cosa fa la funzione -->


```r
%%R

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
```


```r
%%R

all_table <- scraping_table(id_game_html = c(5508:5561))
```

    [1] 5508
    [1] 5509
    [1] 5510
    [1] 5511
    [1] 5512
    [1] 5513
    [1] 5514
    [1] 5515
    [1] 5516
    [1] 5517
    [1] 5518
    [1] 5519
    [1] 5520
    [1] 5521
    [1] 5522
    [1] 5523
    [1] 5524
    [1] 5525
    [1] 5526
    [1] 5527
    [1] 5528
    [1] 5529
    [1] 5530
    [1] 5531
    [1] 5532
    [1] 5533
    [1] 5534
    [1] 5535
    [1] 5536
    [1] 5537
    [1] 5538
    [1] 5539
    [1] 5540
    [1] 5541
    [1] 5542
    [1] 5543
    [1] 5544
    [1] 5545
    [1] 5546
    [1] 5547
    [1] 5548
    [1] 5549
    [1] 5550
    [1] 5551
    [1] 5552
    [1] 5553
    [1] 5554
    [1] 5555
    [1] 5556
    [1] 5557
    [1] 5558
    [1] 5559
    [1] 5560
    [1] 5561


### Rosters


```r
%%R

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
```


```r
%%R

allPlayersName <- players_df(id_html = "42")
```

### Standings


```r
%%R

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
```


```r
%%R

allStanding <- standing_df(id_html = "42")
```

## Python

<!-- Usato Python per caricare i dati in Celonis tramite le API in Python -->

### Libraries

Used libraries:

* `pandas`.
* `pycelonis`.


```python
import pandas as pd
from pycelonis import get_celonis

celonis = get_celonis()
```

    [2022-11-25 14:20:58,317] INFO: No `base_url` given. Using environment variable 'CELONIS_URL'
    [2022-11-25 14:20:58,319] INFO: No `api_token` given. Using environment variable 'CELONIS_API_TOKEN'


    [2022-11-25 14:20:58,529] WARNING: KeyType is not set. Defaulted to 'APP_KEY'.


    [2022-11-25 14:20:58,595] INFO: Initial connect successful! PyCelonis Version: 2.0.0
    [2022-11-25 14:20:58,800] INFO: `package-manager` permissions: ['$ACCESS_CHILD']
    [2022-11-25 14:20:58,801] INFO: `workflows` permissions: []
    [2022-11-25 14:20:58,801] INFO: `task-mining` permissions: []
    [2022-11-25 14:20:58,802] INFO: `team` permissions: []
    [2022-11-25 14:20:58,803] INFO: `action-engine` permissions: []
    [2022-11-25 14:20:58,805] INFO: `process-repository` permissions: []
    [2022-11-25 14:20:58,806] INFO: `process-analytics` permissions: []
    [2022-11-25 14:20:58,807] INFO: `transformation-center` permissions: []
    [2022-11-25 14:20:58,807] INFO: `storage-manager` permissions: []
    [2022-11-25 14:20:58,808] INFO: `event-collection` permissions: ['$ACCESS_CHILD']
    [2022-11-25 14:20:58,809] INFO: `ml-workbench` permissions: []
    [2022-11-25 14:20:58,810] INFO: `user-provisioning` permissions: []


### Load R DataFrames

Here the code to pass DataFrames from R to Python.


```python
%R -o all_table -o allStanding -o allPlayersName
```

### Upload to Celonis

| DataFrame Name   | SQL Table Name   |
|------------------|------------------|
| `all_table`      | `DATA_GAMES`     |
| `allStanding`    | `DATA_STANDINGS` |
| `allPlayersName` | `PLAYERS_NAME`   |


```python
data_pool  = celonis.data_integration.get_data_pools().find("Get Data into the EMS Training - P2P")
data_model = data_pool.get_data_models().find("Data Games - Data Model")
data_job   = data_pool.get_jobs().find("Global Data Jobs")
```


```python
dataFrameList_ls = [all_table, allStanding, allPlayersName]
sqlTableList_ls  = ["DATA_GAMES", "DATA_STANDINGS", "PLAYERS_NAME"]
```


```python
for dataFrame, sqlTable in zip(range(len(dataFrameList_ls)), range(len(sqlTableList_ls))):
    
    print(f"Uploading of the {sqlTableList_ls[sqlTable]} Table from Python to Celonis: \n")
    
    data_pool.create_table(table_name     = sqlTableList_ls[sqlTable],
                           df             = dataFrameList_ls[dataFrame],
                           drop_if_exists = True,
                           force          = True)
    
    print("Upload of the Table Completed!")
    print("_" * 45, "\n \n")
```

    Uploading of the DATA_GAMES Table from Python to Celonis: 
    
    [2022-11-25 14:59:03,057] INFO: Successfully created data push job with id 'de974797-40ba-4436-8472-aba7a8d702df'
    [2022-11-25 14:59:03,059] INFO: Add data frame as file chunks to data push job with id 'de974797-40ba-4436-8472-aba7a8d702df'



      0%|          | 0/1 [00:00<?, ?it/s]


    [2022-11-25 14:59:03,443] INFO: Successfully upserted file chunk to data push job with id 'de974797-40ba-4436-8472-aba7a8d702df'
    [2022-11-25 14:59:03,697] INFO: Successfully triggered execution for data push job with id 'de974797-40ba-4436-8472-aba7a8d702df'
    [2022-11-25 14:59:03,698] INFO: Wait for execution of data push job with id 'de974797-40ba-4436-8472-aba7a8d702df'



    0it [00:00, ?it/s]



```python
data_job.execute()
```

    [2022-11-25 14:21:05,821] INFO: Successfully started execution for job with id 'f8728820-91f9-4329-9ed9-434712c681fa'
    [2022-11-25 14:21:05,822] INFO: Wait for execution of job with id 'f8728820-91f9-4329-9ed9-434712c681fa'



    0it [00:00, ?it/s]



```python
data_model.reload()
```

    [2022-11-25 14:21:33,468] INFO: Successfully triggered data model reload for data model with id '9ef12f6f-c9a2-4260-8da8-0cda6d99b46b'
    [2022-11-25 14:21:33,470] INFO: Wait for execution of data model reload for data model with id '9ef12f6f-c9a2-4260-8da8-0cda6d99b46b'



    0it [00:00, ?it/s]



    ---------------------------------------------------------------------------

    PyCelonisReloadFailedError                Traceback (most recent call last)

    Input In [87], in <cell line: 1>()
    ----> 1 data_model.reload()


    File ~/.local/lib/python3.8/site-packages/pycelonis/ems/data_integration/data_model.py:135, in DataModel.reload(self, force_complete, wait)
        123 def reload(self, force_complete: bool = True, wait: bool = True) -> None:
        124     """Reloads given data model.
        125 
        126     Args:
       (...)
        133         PyCelonisReloadFailedError: Data model reload failed. Only triggered if `wait=True`.
        134     """
    --> 135     self._reload(partial=False, wait=wait, force_complete=force_complete)


    File ~/.local/lib/python3.8/site-packages/pycelonis/ems/data_integration/data_model.py:165, in DataModel._reload(self, partial, wait, data_model_table_ids, **kwargs)
        163 if wait:
        164     self._wait_for_reload()
    --> 165     self._verify_load_successful()


    File ~/.local/lib/python3.8/site-packages/pycelonis/ems/data_integration/data_model.py:216, in DataModel._verify_load_successful(self)
        211 current_compute_load = self._get_current_compute_load()
        212 if current_compute_load and current_compute_load.load_status not in [
        213     DataModelLoadStatus.SUCCESS,
        214     DataModelLoadStatus.WARNING,
        215 ]:
    --> 216     raise PyCelonisReloadFailedError(current_compute_load.load_status, current_compute_load.message)
        218 if current_compute_load and current_compute_load.load_status == DataModelLoadStatus.WARNING:
        219     logger.warning("%s: %s", current_compute_load.load_status.value, current_compute_load.message)


    PyCelonisReloadFailedError: ERROR The load failed: Load failed. Error Message: Could not execute foreign key join: there are duplicates on both sides of the specified key relationship. Table "DATA_GAMES": key columns ("giocatore", "squadra"), key ('Gianotti D.', 'Cesano Seveso'), rows 1 and 2. Table "PLAYERS_NAME": key columns ("giocatore", "squadra"), key ('Digrandi S.', 'Ado San Benedetto Milano'), rows 110 and 126.


To Do:

* Load the Activity
* Load the Data Model

## Other

RIP all part of this code :(

```python

#-- Create Connection with Data Pool 
data_pool = celonis.data_integration.get_data_pools().find("Get Data into the EMS Training - P2P")

#-- Push of All Games Tables
data_pool.create_table(table_name     = "DATA_GAMES",
                       df             = all_table,
                       drop_if_exists = True,
                       force          = True)

#-- Push of Standing Table
data_pool.create_table(table_name     = "DATA_STANDINGS",
                       df             = allStanding,
                       drop_if_exists = True,
                       force          = True)

#-- Push of All Master Data Player Tables
data_pool.create_table(table_name     = "PLAYERS_NAME",
                       df             = allPlayersName,
                       drop_if_exists = True,
                       force          = True)
```

```r

#-- OLD
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
```
