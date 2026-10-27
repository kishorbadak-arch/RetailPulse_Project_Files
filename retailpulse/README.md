# RetailPulse: Sales & Customer Analytics

RetailPulse is a sample retail analytics project built with Python and PostgreSQL. It generates synthetic sales data, loads it into a PostgreSQL star schema, and provides reporting views and analysis queries that can be explored in SQL or Power BI.

## Project structure

- `gen.py` — generates the synthetic CSV dataset. The random seed is fixed so the data is reproducible.
- `data/` — generated CSV files for dates, stores, products, customers, and sales.
- `sql/` — PostgreSQL scripts to create and load the database, create reporting views, and run analysis queries.

## Requirements

- Python 3
- Python packages: `numpy` and `pandas`
- PostgreSQL with the `psql` command-line tool

Install Python packages with:

```bash
python -m pip install numpy pandas
```

## Generate the data

Run these commands from the project folder (the folder containing `gen.py`):

```bash
python gen.py
```

This writes the CSV files into `data/`, replacing the existing generated CSV files.

## Set up PostgreSQL

Create a database named `retailpulse` if you do not already have one:

```bash
createdb retailpulse
```

Then, from the project folder, run the scripts in order:

```bash
psql -d retailpulse -f sql/01_schema_and_load.sql
psql -d retailpulse -f sql/02_reporting_views.sql
psql -d retailpulse -f sql/03_analysis_queries.sql
```

The first script creates the `retail` schema and tables, then loads the CSV files from `data/`. The next script creates reporting views. The last script contains analysis queries. The first script uses `psql`'s `\\copy` command, so run it with `psql` from the project folder and ensure the CSV files are present in `data/`.

## Power BI

The `vw_sales_detail` reporting view is designed to provide a joined sales dataset for Power BI. Connect Power BI to the PostgreSQL database and import the view from the `retail` schema. This repository currently contains the data and SQL files; add your Power BI report file separately if you want it included in the repository.
