# Fraud Detection & Analysis CloudWalk Risk Analyst Assessment

> End-to-end fraud analysis project covering data cleaning, SQL analysis, Power BI dashboards, and a production-ready anti-fraud API.

## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Tools & Stack](#tools--stack)
- [Methodology](#methodology)
- [Key Findings](#key-findings)
- [Dashboard](#dashboard)
- [Anti-Fraud Solution](#anti-fraud-solution)
- [Industry Theory](#industry-theory)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)

## Project Overview

This project presents a comprehensive fraud analysis of 3,199 hypothetical payment transactions processed in a **card-not-present (CNP) mobile environment**. The objective was to:

1. Identify suspicious behaviours and fraud patterns in the transaction data
2. Quantify the financial impact of fraud
3. Propose actionable anti-fraud measures
4. Design and implement a production-ready anti-fraud solution

The dataset exhibits a **12.22% fraud rate** approximately 12× the industry benchmark of below 1% making it an ideal stress-test environment for fraud detection systems.

## Dataset

| Field | Description |
|---|---|
| `transaction_id` | Unique transaction identifier |
| `merchant_id` | Identifier of the merchant |
| `user_id` | Identifier of the cardholder |
| `card_number` | Masked card number |
| `transaction_date` | ISO 8601 datetime of the transaction |
| `transaction_amount` | Transaction value in EUR |
| `device_id` | Identifier of the device used (nullable) |
| `has_cbk` | Whether the transaction received a fraud-related chargeback |

**Key stats:**
- 3,199 total transactions
- November 1 – December 1, 2019
- 2,704 unique users · 1,756 unique merchants
- 391 fraud transactions (12.22%)
- €2,456,233.48 total transacted value
- €568,346.62 fraud value (23.14% of total)

## Tools & Stack

| Layer | Tool |
|---|---|
| Data cleaning & validation | Excel |
| Data storage & analysis | SQL Server Express (SSMS) |
| Enrichment & API | Python 3.12 · FastAPI · Pandas · Requests |
| Visualisation | Power BI Desktop |
| Version control | Git / GitHub |

## Methodology

### 1. Data Cleaning (Excel)
- Parsed ISO datetime into usable date/time/hour columns
- Converted `has_cbk` text to integer `is_fraud` flag (0/1)
- Classified `device_id` missing values
- Created `amount_bucket` and `risk_hour` derived columns
- Validated: 0 duplicate transaction IDs · 391 fraud rows · 830 missing device IDs

### 2. SQL Analysis (SQL Server)
- Imported cleaned data into SQL Server Express
- Corrected column data types (identifiers as VARCHAR, amounts as FLOAT)
- Created three analytical views:
  - `vw_user_velocity` transaction velocity per user per hour
  - `vw_fraud_users` distinct users with chargeback history
  - `vw_merchant_risk` fraud rate, revenue, and risk level per merchant
- Added computed columns: `card_shared`, `transactions_in_hour`, `would_deny`
- Wrote CTE-based queries to answer all business questions

### 3. Python Enrichment & API
- Built BIN enrichment module using binlist.net (prepaid flag, card country, scheme)
- Built IP enrichment module using ip-api.com (geolocation, proxy/VPN detection)
- Built email and phone enrichment modules with heuristic fallback
- Implemented rules engine with hard rules + score-based system
- Exposed as REST API via FastAPI with Swagger documentation

### 4. Power BI Dashboard
- Connected directly to SQL Server (live import)
- Built `_Measures` table with all DAX measures
- Created relationships between main table and views
- Built 4-page interactive dashboard

## Key Findings

### Transaction Amount
Fraud rate increases dramatically above €500:

| Amount Range | Fraud Rate |
|---|---|
| €0 – 200 | 2.98% |
| €200 – 500 | 4.57% |
| €500 – 1,000 | **19.84%** |
| €1,000 – 2,000 | **17.73%** |
| €2,000+ | **33.61%** |

### Time of Day
| Risk Period | Hours | Fraud Rate |
|---|---|---|
| High | 22:00–05:00 | **18.10%** |
| Medium | 19:00–21:00 | 16.16% |
| Low | 06:00–18:00 | 8.21% |

### Velocity
- 36.3% of fraud transactions occurred within 1 hour of a previous transaction by the same user
- Only 3.0% of legitimate transactions show the same pattern a **12× difference**
- Fraudulent users transact every **15.99 hours** vs **56.27 hours** for legitimate users

### Merchants
- 23 merchants with ≥5 transactions show a fraud rate ≥ 80%
- 11 merchants show a **100% fraud rate** consistent with fictitious or compromised accounts
- High-risk merchants account for **45% of all fraud** despite representing only 5.5% of transactions

### Shared Cards
- 31 card numbers used by multiple user IDs
- Fraud rate on shared cards: **33.80%** vs 11.73% for exclusive cards

### Device ID
- 830 transactions (25.9%) missing device ID anomalous in a mobile CNP environment
- Fraud rate with device present: 13.70% · without: 8.10%

## Dashboard

The Power BI dashboard covers 4 pages:

### Page 1 Fraud Overview
> _Insert screenshot of Fraud Overview dashboard here_

![Fraud Overview](assets/dashboard_overview.png)

Key visuals: Fraud rate KPI · Total/Fraud transaction counts · Fraud vs Legit donut · Fraud rate by amount bucket · Fraud rate by hour · Fraud rate by risk period

### Page 2 Merchant Analysis
> _Insert screenshot of Merchant Analysis dashboard here_

![Merchant Analysis](assets/dashboard_merchant.png)

Key visuals: High-risk merchant KPIs · Top merchants by fraud rate · Top merchants by transaction volume · Top merchants by transacted value · Revenue vs fraud rate scatter

### Page 3 User Risk
> _Insert screenshot of User Risk dashboard here_

![User Risk](assets/dashboard_user_risk.png)

Key visuals: Velocity KPIs · Users with fraud history · Top 10 fraud users · Fraud rate by velocity bucket · Avg hours between transactions (fraud vs legit) · Fraud rate by device status

### Page 4 Fraud Impact
> _Insert screenshot of Fraud Impact dashboard here_

![Fraud Impact](assets/dashboard_fraud_impact.png)

Key visuals: Total vs fraud transacted value · Fraud value % of total · Shared card fraud rate · Would-deny rule backtesting KPIs · Fraud caught % · False positive rate

## Anti-Fraud Solution

A production-ready REST API was built using **Python and FastAPI**.

### Architecture

```
Transaction arrives (POST /api/v1/transaction)
        ↓
  Enrichment layer
  BIN · IP · Email · Phone
        ↓
  Rules engine
  Hard rules → instant DENY
  Score rules → DENY if score ≥ 60
        ↓
  Return recommendation
  { "recommendation": "approve" | "deny" }
```

### Hard Rules (Instant Deny)

| Rule | Condition |
|---|---|
| Prior chargeback | User has any `has_cbk = true` in history |
| High velocity | ≥ 3 transactions from same user in 60 minutes |
| Shared card | Same card used by more than one `user_id` |

### Score Rules (Deny if Score ≥ 60)

| Signal | Points |
|---|---|
| Amount > €2,000 | +35 |
| Amount > €1,000 | +20 |
| Night transaction (22:00–05:00) | +20 |
| Prepaid card (BIN lookup) | +40 |
| VPN / proxy IP | +50 |
| Datacenter IP | +30 |
| Disposable email | +45 |
| VoIP phone number | +40 |
| Missing device ID | +15 |

### Backtesting Results

| Metric | Value |
|---|---|
| Transactions flagged | 514 (16.07%) |
| Fraud transactions caught | 391 (100% recall) |
| False positive rate | 4.38% |
| Precision | 76.07% |

### Running the API

```bash
# Install dependencies
pip install fastapi uvicorn pandas requests pydantic

# Update DATA_PATH in antifraud_single.py to point to your CSV
# Then start the server
uvicorn antifraud_single:app --reload --port 8000
```

API documentation available at: `http://localhost:8000/docs`

### Example Request

```bash
curl -X POST http://localhost:8000/api/v1/transaction \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": 2342357,
    "merchant_id": "29744",
    "user_id": "97051",
    "card_number": "434505******9116",
    "transaction_date": "2019-11-30T23:16:32.812632",
    "transaction_amount": 373,
    "device_id": 285475,
    "ip_address": "187.10.20.30",
    "email": "user@gmail.com"
  }'
```

### Example Response

```json
{
  "transaction_id": 2342357,
  "recommendation": "approve",
  "score": 20,
  "hard_deny": false,
  "reasons": ["night_transaction_hour_23"],
  "enrichment": {
    "bin":   { "scheme": "visa", "type": "debit", "prepaid": false, "score": 0 },
    "ip":    { "country_code": "BR", "is_proxy": false, "score": 0 },
    "email": { "email_valid": true, "email_disposable": false, "score": 0 },
    "phone": { "score": 0 }
  }
}
```

## Industry Theory

Brief answers to the four industry questions from the assessment brief:

**1. Money & information flow in the payment industry**
A transaction flows: Cardholder → Merchant → Acquirer → Card Network → Issuer for authorisation. Money flows in reverse at settlement, with the acquirer deducting the MDR before paying the merchant.

**2. Acquirer vs Sub-Acquirer vs Payment Gateway**
An acquirer holds a direct card network licence and bears full financial risk. A sub-acquirer (like CloudWalk) aggregates merchants under one acquirer contract and absorbs merchant-level chargeback risk. A payment gateway is technology-only it routes data but takes no financial risk.

**3. Chargebacks vs Cancellations**
A cancellation is a voluntary, cooperative refund initiated before or shortly after settlement. A chargeback is a forced reversal initiated by the cardholder through their issuing bank, often weeks after settlement, carrying fees and dispute obligations for the merchant and acquirer. Chargebacks are the primary financial consequence of fraud in the acquiring world.

**4. What is anti-fraud and how does an acquirer use it**
An anti-fraud system evaluates transactions at the point of authorisation and returns an approve/deny recommendation in real time. Acquirers use it to block fraudulent transactions before they are processed, preventing chargeback losses and protecting their card network standing.

## Project Structure

```
├── antifraud_single.py          # Anti-fraud API (single file)
├── enrichment_notebook.py       # Jupyter-compatible enrichment script
├── data/
│   └── transactional-sample.csv # Original dataset
├── sql/
│   └── analysis_queries.sql     # All SQL queries and view definitions
├── report/
│   └── fraud_analysis_report.docx # Full written report
└── assets/
    ├── dashboard_overview.png
    ├── dashboard_merchant.png
    ├── dashboard_user_risk.png
    └── dashboard_fraud_impact.png
```

## How to Run

### SQL Analysis
1. Import `transactional-sample.csv` into SQL Server Express
2. Run `sql/analysis_queries.sql` to create views and computed columns
3. Connect Power BI to your SQL Server instance

### Anti-Fraud API
```bash
pip install fastapi uvicorn pandas requests pydantic
uvicorn antifraud_single:app --reload --port 8000
```

### Enrichment Script (Jupyter)
```bash
pip install pandas requests
# Open enrichment_notebook.py in Jupyter
# Update DATA_PATH and OUTPUT_PATH at the top
# Run cells sequentially
```

*CloudWalk Risk Analyst I Assessment 2024*
