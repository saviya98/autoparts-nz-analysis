# AutoParts NZ - BI & Systems Platform

An end-to-end BI and systems-development portfolio project simulating a multi-region
automotive parts distributor: dimensional data modeling, SQL reporting layer, an
interactive Power BI report, and a Power Automate approval workflow.

## What this demonstrates

- Star-schema data modeling in MySQL (fact/dimension design)
- SQL views for reporting, plus a stored procedure for materialized summary refresh
- Deliberately planted, then diagnosed, data-quality issues (orphaned keys, duplicates,
  nulls, CRM status conflicts) — with dedicated SQL views to surface each one
- A 3-page interactive Power BI report (Sales Performance, Inventory & Reorder, Data Quality)
- A Power Automate approval workflow (stock reorder request → manager approval →
  SharePoint record → email notification), plus a companion Power Apps form

## Structure

- `build_data.py` — generates the sample dataset and loads it into MySQL
- `SQL/DB creation.sql` — table definitions
- `SQL/Reporting Views.sql` — the 4 core reporting views + 5 data-quality views
- `SQL/Stored Procedure.sql` — sp_refresh_sales_summary
- `Dashboard/BI.pbix` — the Power BI report

## Setup

1. Create a MySQL database, run the 3 SQL scripts in order (creation → views → procedure)
2. Copy `.env.example` to `.env` and fill in your MySQL password
3. `pip install -r requirements.txt`
4. `python build_data.py`
5. Open `Dashboard/BI.pbix` in Power BI Desktop, point the MySQL connection at your database

## Notable data-quality findings

- 51 orders reference a product ID that doesn't exist in the catalog — all pointing to
  the same invalid ID, suggesting one systemic cause rather than random corruption
- 27 customers marked "Inactive" still have recent, valid purchase history
- 8 customer records are missing an email address
- 15 duplicate order groups detected via a GROUP BY/HAVING reconciliation query

## Notes on scope

Built as a personal portfolio project. The Power Automate flow writes to a SharePoint
list rather than back into MySQL directly, since that would require an on-premises data
gateway outside this project's scope. The Power Apps form is built and the flow is fully
tested independently; connecting them live hit a premium-connector licensing limit on a
free trial tier, not a technical gap.

## Screenshots

### Power BI — Sales Performance

![Sales Performance](screenshots/sales-performance.png)

### Power BI — Inventory & Reorder

![Inventory](screenshots/inventory.png)

### Power BI — Data Quality

![Data Quality](screenshots/data-quality.png)

### Power Automate — Stock Reorder Approval Flow

![Power Automate Flow](screenshots/power-automate-flow.png)

### Power Apps — Reorder Request Form

![Power Apps Form](screenshots/power-apps-form.png)
