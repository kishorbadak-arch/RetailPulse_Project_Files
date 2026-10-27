# RetailPulse: Sales & Customer Analytics

RetailPulse is a sample retail analytics project built with Python and PostgreSQL. It generates synthetic retail data, loads it into a PostgreSQL star schema, and provides reporting views and SQL analysis queries for exploration in SQL or Power BI.

## Project contents

- `retailpulse/gen.py` — generates the synthetic CSV data.
- `retailpulse/data/` — CSV tables for dates, stores, products, customers, and sales.
- `retailpulse/sql/` — PostgreSQL scripts for schema creation and data loading, reporting views, and analysis queries.
- `retailpulse/README.md` — detailed setup and usage instructions.

## Requirements

- Python 3 with `numpy` and `pandas`
- PostgreSQL and the `psql` command-line tool

Install the Python packages:

```bash
python -m pip install numpy pandas
```

## Generate the sample data

Open a terminal in the `retailpulse` folder and run:

```bash
python gen.py
```

This creates or replaces the CSV files in `retailpulse/data/`.

## Load and query the data

Create a PostgreSQL database named `retailpulse`, then run these commands from the repository folder:

```bash
createdb retailpulse
psql -d retailpulse -f retailpulse/sql/01_schema_and_load.sql
psql -d retailpulse -f retailpulse/sql/02_reporting_views.sql
psql -d retailpulse -f retailpulse/sql/03_analysis_queries.sql
```

The first script creates the `retail` schema and loads the CSVs from `retailpulse/data/`. Run the scripts in order. The first script uses `psql`'s `\\copy` command and expects you to run it from the repository folder.

## Power BI

The SQL reporting view `retail.vw_sales_detail` provides joined sales data for Power BI. Connect Power BI to the PostgreSQL database and import the view from the `retail` schema.
