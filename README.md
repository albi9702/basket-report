# Basketball Data Analysis

This repository contains Python scripts and data for analyzing basketball statistics from Euroleague and the Promozione league in Italy. The scripts provide tools for scraping and processing basketball data, as well as generating insights and visualizations.

## Euroleague

The Euroleague directory includes Python scripts and notebooks related to the Euroleague basketball competition. Euroleague is the top professional basketball league in Europe, featuring teams from various countries.

In order to analyze the results of the games, Euroleague provides the following API functions:

* *Points*:     Shot selections of the Game.
* *PlaybyPlay*: All events of the game.
* *Boxscore*:   Box Score of all Players in the game.

### Work Scripts

Here are the following functions in order to analyze the results of the games from Euroleague:

* `euroleague_api.py`: API function written in python to scrape data from the previous three URL.
* `euroleague_api.r`: API function written in R to scrape data from the previous three URL.
* `import_to_celonis.py`: script written in Python to upload the data from the previous python script into the Celonis Environment.
* `work_script.py`: testing script written in python.

## Promozione League

The Promozione league is a local basketball league in Italy. This directory contains Python scripts and data specifically related to this league. Data are collected from [LombardiaCanestro](https://lombardia.italiacanestro.it/). In this case, the results are collected from the Promozione - Girone E championship.

### Features

Here are the following functions in order to analyze the results of the games from Euroleague:

* scraping_promozione.ipynb: Python Notebook containing all functions related to scrape data from the Promozione - Girone E championship.
* scraping_promozione.r: R code containing all functions related to scrape data from the Promozione - Girone E championship.

## Usage

1. Clone the repository:

```bash
git clone https://github.com/albi9702/basket-report
```

2. Install the required dependencies:

```bash
pip install -r requirements.txt
```

3. Navigate to the desired directory (Euroleague or Promozione) and execute the relevant scripts or notebooks.

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or improvements, please open an issue or submit a pull request. Let's collaborate to enhance the basketball data analysis tools.