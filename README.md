# dbt + DuckDB Job Postings Analytics

An analytics engineering project that turns raw job-posting data into analysis-ready models with **dbt** (Fusion engine, v2) and **DuckDB**. dbt reads the raw Parquet files straight from disk, so there is no database server to install or load data into.

The dataset comes from Luke Barousse's [dbt Analytics Engineering Course](https://github.com/lukebarousse/dbt_Analytics_Engineering_Course): 12 months of data-job postings (July 2025 – June 2026) plus the skills mentioned in each posting.

## Tech stack

| Tool | Role |
|------|------|
| [dbt](https://docs.getdbt.com/) 2.x (Fusion engine) | SQL transformations, testing, documentation |
| [DuckDB](https://duckdb.org/) | Embedded analytical database that queries Parquet directly |
| [uv](https://docs.astral.sh/uv/) | Python environment and dependency management |
| Python 3.13 | Runtime for the download script |

## Project structure

```
dbt-duckdb-project/
├── analytics/                  # dbt project
│   ├── dbt_project.yml         # dbt project config (name: analytics)
│   ├── models/
│   │   └── job_posting.sql     # Cleaned job postings view
│   ├── macros/
│   └── seeds/
├── data/                       # git-ignored
│   ├── raw/                    # Raw Parquet files (downloaded)
│   └── dev.duckdb              # DuckDB database built by dbt
├── scripts/
│   └── download_data.py        # Downloads the raw dataset into data/raw/
├── src/dbt_duckdb_project/     # Python package scaffold
├── pyproject.toml
└── uv.lock
```

## Data

The raw files are about 85 MB in total and are not committed to the repo. `scripts/download_data.py` downloads them.

### `raw_job_postings_YYYY-MM.parquet` (12 files, ~843k rows)

One row per scraped job posting. Main columns:

| Column | Type | Description |
|--------|------|-------------|
| `job_id` | varchar | Unique posting identifier |
| `job_title` | varchar | Title as posted |
| `company_name` | varchar | Hiring company |
| `job_location` | varchar | Location as posted |
| `job_via` | varchar | Source / job board |
| `job_posted_at` | varchar | Relative posting time (raw text) |
| `job_salary` | varchar | Salary text, when available |
| `job_schedule_type` | varchar | Full-time, Contractor, etc. |
| `job_work_from_home` | boolean | Remote flag |
| `job_extensions_raw`, `job_detected_extensions_raw` | varchar | Raw metadata payloads |
| `search_time`, `search_date` | timestamptz, date | When the posting was scraped |
| `search_term`, `search_location` | varchar | Query used to find the posting |
| `error`, `error_message` | boolean, varchar | Scrape errors (~151k rows have one) |

### `raw_job_skills.parquet` (~3.3M rows)

One row per (job, skill) pair: `job_id`, `skill_keyword`, `skill_id`.

## Models

| Model | Materialization | Description |
|-------|-----------------|-------------|
| `job_posting` | view | Selects the core posting fields from all monthly files and drops rows with scrape errors (`WHERE error IS NULL`) |

## Getting started

### 1. Prerequisites

- [uv](https://docs.astral.sh/uv/getting-started/installation/)
- Optional: the [DuckDB CLI](https://duckdb.org/docs/installation/), for querying the results

### 2. Install dependencies

From the repo root:

```bash
uv sync
```

Then activate the environment (`source .venv/Scripts/activate` in Git Bash on Windows, `source .venv/bin/activate` on macOS/Linux), or put `uv run` in front of each command.

### 3. Download the data

Run this from the repo root:

```bash
uv run scripts/download_data.py
```

The files go to `data/raw/`. Re-running the script skips files you already have.

### 4. Configure the dbt profile

Add this to `~/.dbt/profiles.yml`. The paths are relative to the `analytics/` folder:

```yaml
analytics:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: ../data/dev.duckdb
      threads: 1
    prod:
      type: duckdb
      path: ../data/dev.duckdb
      threads: 4
```

### 5. Run dbt

```bash
cd analytics
dbt debug    # check the connection
dbt run      # build the models
dbt build    # run models + tests + seeds
```

### 6. Query the results

The view stores a relative path to the Parquet files, so query it from inside `analytics/`:

```bash
cd analytics
duckdb ../data/dev.duckdb -c "SELECT search_term, COUNT(*) AS postings FROM main.job_posting GROUP BY 1 ORDER BY 2 DESC;"
```

## Roadmap

- [ ] Add a staging model for `raw_job_skills`
- [ ] Define sources in a `sources.yml` instead of hard-coded file paths
- [ ] Add schema tests (`unique`, `not_null`) on `job_id`
- [ ] Build marts: top skills by role, remote share, postings over time
- [ ] Generate dbt docs (`dbt docs generate`)

## Credits

Dataset and course material: [lukebarousse/dbt_Analytics_Engineering_Course](https://github.com/lukebarousse/dbt_Analytics_Engineering_Course).
