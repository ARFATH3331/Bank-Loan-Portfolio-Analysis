# Bank Loan Portfolio Analysis

A loan portfolio analysis project using SQL, Excel, and Power BI. The report reviews portfolio size and funding, loan status, repayment performance, and delinquency/default patterns across loan segments.

## Dashboard

The Power BI report contains two pages:

- **Portfolio Overview** — loan volume, funded amount, loan status, delinquency by grade, default by term, and funded amount by state.
- **Risk & Repayment** — delinquency by state, default by grade, payments and principal recovery by loan status, with Term and Product Code slicers.

## Selected findings

- 65,535 loans
- 733M total funded amount
- 10.84% delinquency rate
- 1.56% default rate
- 89.12% principal recovery rate
- 814.90M total payments

Amounts are shown in the dataset's displayed monetary units. Rates for small groups should be interpreted alongside their loan counts. Active and completed loans may have different repayment maturity.

## Files included

- `BankloanAnalysis.sql` — SQL analysis queries
- `Bank_Loan_Portfolio_Analysis_Summary.pdf` — project summary

## Data and privacy

The loan-level CSV, Excel workbooks, and Power BI file are excluded from this repository because they may contain borrower-level information or embed the source data. Add only data that is public and licensed for redistribution, or use a synthetic/anonymized sample that has been checked for re-identification risk.
