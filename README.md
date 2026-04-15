# Fraud Detection & Analysis, CloudWalk Risk Analyst Assessment

> End-to-end fraud analysis of 3,199 card-not-present payment transactions, covering data cleaning, SQL analysis, Power BI dashboards, business recommendations, and a production-ready anti-fraud API.

## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Tools & Stack](#tools--stack)
- [Methodology](#methodology)
- [Dashboard & Analysis](#dashboard--analysis)
- [Business Recommendations](#business-recommendations)
- [Anti-Fraud Solution](#anti-fraud-solution)
- [Industry Theory](#industry-theory)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)


## Project Overview

This project presents a comprehensive fraud analysis of 3,199 hypothetical payment transactions processed in a **card-not-present (CNP) mobile environment** during November 2019. The analysis was conducted to identify suspicious behaviours, quantify the financial impact of fraud, and design a production-ready anti-fraud solution.

The dataset exhibits a **12.22% fraud rate**, approximately 12 times the industry benchmark of below 1%. Total transacted value reached €2,456,233.48, of which **€568,346.62 (23.14%) was fraudulent**. This disproportionate monetary share reflects a core characteristic of CNP fraud: fraudulent actors deliberately target high-value transactions, making each fraud event more financially damaging than the transaction count alone suggests.


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
- November 1 to December 1, 2019
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
- Parsed ISO datetime into usable date, time and hour columns
- Converted `has_cbk` text to integer `is_fraud` flag (0/1)
- Identified and classified `device_id` missing values
- Derived `amount_bucket` and `risk_hour` classification columns
- Validated data integrity: 0 duplicate transaction IDs · 391 fraud rows confirmed · 830 missing device IDs identified

### 2. SQL Analysis (SQL Server)
- Imported cleaned data into SQL Server Express
- Corrected column data types 
- Created three analytical views:
  - `vw_user_velocity` — transaction velocity per user per hour
  - `vw_fraud_users` — distinct users with confirmed chargeback history
  - `vw_merchant_risk` — fraud rate, revenue, and risk classification per merchant
- Added computed columns: `card_shared`, `transactions_in_hour`, `would_deny`
- Authored CTE-based queries to answer all analytical business questions

### 3. Python Enrichment & API
- Built BIN enrichment module via binlist.net (prepaid flag, issuing country, card scheme)
- Built IP enrichment module via ip-api.com (geolocation, VPN and proxy detection)
- Built email and phone enrichment modules with heuristic fallback for offline use
- Implemented a two-layer rules engine combining hard deny rules and score-based risk assessment
- Deployed as a REST API via FastAPI with auto-generated Swagger documentation

### 4. Power BI Dashboard
- Connected directly to SQL Server via live import
- Built a dedicated `_Measures` table containing all DAX measures
- Established relationships between the main transaction table and all three analytical views
- Developed a 4-page interactive dashboard with cross-page slicers


## Dashboard & Analysis

The Power BI dashboard is organised into 4 pages, each addressing a distinct set of business questions. All pages are interactive via slicers for Risk Hour, Amount Bucket, Fraud Status, Card Status, and Denial Status.


### Page 1 — Fraud Overview

![Fraud Overview](assets/dashboard_overview.png)

**Analysis:**

The majority of transaction volume and transacted value occurs during low-risk hours, indicating that the platform is predominantly serving legitimate users. However, a fraud rate of 12.22% is materially above the industry benchmark of below 1% and requires immediate investigation and remediation.

Transaction amount is a direct and significant predictor of fraud. The fraud rate escalates from 2.98% for transactions below €200 to 33.61% for transactions above €2,000. This pattern is consistent with fraudulent actors deliberately targeting high-value transactions to maximise yield before detection. From a sub-acquirer perspective, this is particularly concerning because larger fraudulent transactions translate directly into larger chargeback liabilities.

Time of day is a secondary but meaningful signal. Fraud activity peaks between 01:00 and 02:00 and again between 06:00 and 07:00, where the fraud rate reaches approximately 50%. 

The overall picture is that the platform is not in a critical position — 87.78% of transactions are legitimate — but the fraud rate must be addressed systematically before it deteriorates further or triggers card network penalties.

**Key metrics:**

| Metric | Value | Benchmark |
|---|---|---|
| Total Transactions | 3,199 | |
| Fraud Transactions | 391 (12.22%) | Below 1% |
| Total Transacted Value | €2.46M | |
| Fraud Transacted Value | €568K (23.14%) | Below 2% |
| Fraud Rate — Amount 0-200 | 2.98% | |
| Fraud Rate — Amount 2k+ | 33.61% | |
| Fraud Rate — High Risk Hours | 18.10% | |
| Fraud Rate — Low Risk Hours | 8.21% | |


### Page 2 — Merchant Analysis

![Merchant Analysis](assets/dashboard_merchant.png)

**Analysis:**

A subset of merchants exhibits fraud rates of 100% across five or more transactions, a pattern strongly consistent with fictitious or compromised merchant accounts being used to process stolen card data. These merchant relationships represent an acute financial and reputational risk and should be escalated for immediate review and suspension pending investigation.

Merchant 1308 is particularly notable — it appears both in the highest-risk merchant list and among the top merchants by transacted value. This combination of high transaction volume and a 100% fraud rate makes it the most financially damaging entitie in the dataset and the highest-priority case for immediate action.

High-risk merchants collectively account for 45.01% of all fraudulent transactions while representing only 5.50% of total transaction volume. This concentration means that suspending even a small number of compromised merchant accounts would produce a large reduction in overall fraud rate.

Conversely, merchants such as 49205 demonstrate that low-risk, high-volume merchant relationships are achievable within the current portfolio. Understanding the acquisition channel and onboarding process for these clean merchants would enable the business to replicate successful partnerships and strengthen portfolio quality over time.

Shared card usage is concentrated among high-risk merchants. Since shared cards carry a fraud rate of 33.8% compared to 11.7% for exclusive cards, the co-occurrence of a high-risk merchant and a shared card transaction should be treated as a compounding risk signal requiring immediate intervention.

**Key metrics:**

| Metric | Value |
|---|---|
| High Risk Merchants (fraud rate >= 80%, min 5 transactions) | 23 |
| Merchants with 100% fraud rate | 11 |
| High Risk Merchant Fraud Transactions | 176 |
| High Risk Merchant Fraud % of Total Fraud | 45.01% |
| High Risk Merchant Fraud % of All Transactions | 5.50% |
| Total Transacted Value | €2.46M |
| Fraud Transacted Value | €568K |


### Page 3 — User Risk

![User Risk](assets/dashboard_user_risk.png)

**Analysis:**

A group of 153 users accounts for all 391 confirmed fraudulent transactions. The highest-volume fraud users exhibit transaction patterns consistent with organised card testing or account takeover activity, with individual users recording up to 25 fraudulent transactions within the observation period.

Transaction velocity is the single most reliable behavioural indicator of fraud in the dataset. The fraud rate increases progressively with the number of transactions submitted by the same user within a one-hour window, reaching 100% at seven or more transactions per hour. This confirms that a velocity threshold of three or more transactions in 60 minutes constitutes a statistically sound hard deny signal.

Fraudulent users transact on average every 15.99 hours compared to 56.27 hours for legitimate users, a 3.5-times difference in transaction frequency. This behavioural gap is one of the strongest distinguishing characteristics between fraudulent and legitimate activity and should be incorporated as a feature in any risk scoring model.

Regarding device identification, 62.88% of fraudulent transactions are submitted with a device ID present, indicating that the absence of a device ID is not a primary driver of fraud. However, 25.9% of all mobile transactions lacking a device identifier remains an anomaly that warrants investigation, as it may indicate a technical capture failure or deliberate obfuscation.

**Key metrics:**

| Metric | Value |
|---|---|
| Users with Fraud History | 153 |
| High Velocity Transactions | 66 |
| Missing Device ID | 830 (25.9%) |
| Avg Hours Between Fraud Transactions | 15.99 hours |
| Avg Hours Between Legit Transactions | 56.27 hours |
| Fraud Rate — 3+ Transactions in 1 Hour | High |
| Fraud Rate — 7 Transactions in 1 Hour | 100% |


### Page 4 — Fraud Impact

![Fraud Impact](assets/dashboard_fraud_impact.png)

**Analysis:**

Card sharing across multiple user identifiers is a significant fraud enabler. Transactions associated with shared cards carry a fraud rate of 33.80% compared to 11.73% for cards used by a single user, nearly three times higher. While shared card transactions represent only 2.22% of total transaction volume, their disproportionate fraud rate justifies treating card sharing as a hard deny condition or a mandatory escalation flag.

The monetary split between legitimate and fraudulent transacted value reinforces the severity of the problem. Fraudulent transactions account for 12.22% of transaction count but 23.14% of total transacted value, confirming that fraudulent actors systematically target higher-value transactions and amplifying financial exposure beyond what the count figures alone suggest.

Backtesting the three proposed hard deny rules against the full dataset produces highly favourable results. Applying the chargeback history, velocity, and shared card rules simultaneously would flag 514 transactions for denial, capturing 100% of all fraudulent transactions with a false positive rate of 4.38%. This precision-recall balance is commercially viable, the financial cost of blocking 4.38% of legitimate transactions is far outweighed by the elimination of all fraud-related chargeback liability.

**Key metrics:**

| Metric | Value |
|---|---|
| Fraud Value % of Total Transacted | 23.14% |
| Transactions Flagged by Rules | 514 (16.07%) |
| Fraud Transactions Caught | 391 (100% recall) |
| False Positive Rate | 4.38% |
| Fraud Rate — Shared Card | 33.80% |
| Fraud Rate — Exclusive Card | 11.73% |
| Legitimate Transacted Value | €1,887,886.86 |
| Fraud Transacted Value | €568,346.62 |


## Business Recommendations

The following recommendations are prioritised by expected impact and feasibility of implementation.

### Priority 1 

**Suspend high-risk merchants.**
The 11 merchants with a 100% fraud rate across 5 or more transactions should be suspended immediately pending investigation. These accounts are almost certainly fictitious or compromised and collectively account for a significant proportion of total fraud exposure. Merchant 1308, which combines a 100% fraud rate with high transaction volume and value, should be the first case escalated to the compliance and risk teams.

**Block users with confirmed chargeback history.**
The 153 users with at least one confirmed chargeback should be permanently flagged in the authorisation system. Any subsequent transaction from a flagged account should be flaged automatically to keep an eye on every transaction to see if those charge backs become an habbit. This is the most precise rule available — it targets known fraudulent actors with no ambiguity and zero implementation risk to legitimate users.

**Enforce transaction velocity limits.**
Transactions should be denied automatically when a user submits three or more transactions within a 60-minute window. The data confirms that 36.3% of all fraud transactions exhibit this velocity pattern, and the fraud rate reaches 100% at seven transactions per hour. This rule is both highly effective and straightforward to implement.

### Priority 2 

**Flag shared card transactions for review.**
Card numbers associated with more than one user ID should trigger a mandatory review or additional authentication requirement. Shared cards carry a fraud rate of 33.8% and are concentrated among high-risk merchant transactions, making this a high-leverage signal for both merchant and user risk monitoring.

**Apply risk-based friction for high-value transactions.**
Transactions above €500 should require additional authentication, particularly during high-risk hours (22:00 to 05:00). The fraud rate for transactions in this segment exceeds 19%, and implementing 3D Secure challenge requirements would shift chargeback liability to the issuing bank on authenticated transactions, materially reducing sub-acquirer exposure.

**Investigate and resolve the 25.9% missing device ID rate.**
In a mobile CNP environment every transaction should carry a device identifier. A missing rate of 25.9% is anomalous and may indicate a technical capture failure or deliberate obfuscation. Resolving this gap would improve the reliability of all device-based fraud signals and reduce ambiguity in the risk assessment process.

### Priority 3 

**Integrate BIN-based prepaid card detection.**
Prepaid cards show a fraud rate of 23.3% compared to 2.4% for standard cards. Integrating a BIN lookup at the point of authorisation using binlist.net (free, no API key required) would enable real-time prepaid card identification and add a material risk signal with minimal implementation effort.

**Implement IP geolocation and proxy detection.**
The originating IP address of each mobile transaction provides valuable context for risk assessment. Real-time VPN, proxy, and Tor exit node detection via ip-api.com (free tier, no key required) would identify transactions originating from anonymised connections, which are disproportionately associated with CNP fraud.

**Develop a proactive merchant risk monitoring programme.**
Rather than reacting to merchant fraud after the fact, implement a continuous monitoring threshold, for example, flagging any merchant whose rolling 30-day fraud rate exceeds 20% for proactive review. This would enable the identification of deteriorating or newly compromised merchant accounts before they reach critical fraud levels.

**Analyse and replicate the profile of low-risk merchants.**
Merchants such as 49205 demonstrate that low-fraud merchant relationships are achievable within the current portfolio. Analysing the acquisition channel, onboarding criteria, and business category of consistently low-risk merchants would enable the development of targeted acquisition strategies and a stronger overall merchant portfolio.

### Priority 4 

**Extend enrichment to email and phone risk signals.**
Disposable email domains and VoIP phone numbers are strongly associated with fraudulent account creation. Integrating email validation via Abstract API and phone line-type detection via Numverify would add pre-transaction risk signals that complement the existing transaction-level rule set at minimal incremental cost.

**Transition from rule-based to score-based decisioning.**
The current hard-rule approach achieves 100% fraud recall with a 4.38% false positive rate. Introducing a score-based layer, where multiple weighted signals accumulate toward a configurable risk threshold, would enable more granular decisioning, reducing false positives while maintaining high fraud capture rates. The enrichment modules for BIN, IP, email, and phone are already implemented in the anti-fraud API and ready to be incorporated into a scoring model.

**Join an industry chargeback intelligence network.**
Services such as Ethoca and Verifi distribute real-time chargeback signals across participating merchants and acquirers. Joining such a network would enable pre-emptive blocking of cards already flagged elsewhere in the ecosystem, reducing fraud exposure before a chargeback is filed and improving the precision of the authorisation decision.


## Anti-Fraud Solution

A production-ready REST API was developed using **Python and FastAPI**, implementing the analytical findings as an automated transaction scoring and decisioning system.

### Architecture

```
Transaction arrives (POST /api/v1/transaction)
        |
  Enrichment layer
  BIN · IP · Email · Phone
        |
  Rules engine
  Hard rules: instant DENY
  Score rules: DENY if score >= 60
        |
  Return recommendation
  { "recommendation": "approve" | "deny" }
```

### Hard Rules (Instant Deny)

| Rule | Condition | Evidence |
|---|---|---|
| Prior chargeback | User has any has_cbk = true in history | 153 known fraud users identified |
| High velocity | 3+ transactions from same user in 60 minutes | 36.3% of fraud transactions exhibit this pattern |
| Shared card | Card number used by more than one user_id | 33.8% fraud rate on shared cards |

### Score Rules (Deny if Score >= 60)

| Signal | Points | Evidence |
|---|---|---|
| Amount > €2,000 | +35 | 33.61% fraud rate |
| Amount > €1,000 | +20 | 17.73% fraud rate |
| Amount > €500 | +10 | 19.84% fraud rate |
| Night transaction (22:00-05:00) | +20 | 18.10% fraud rate |
| Prepaid card (BIN lookup) | +40 | 23.3% fraud rate on prepaid cards |
| VPN / proxy IP | +50 | Strong CNP fraud indicator |
| Datacenter IP | +30 | Automated traffic indicator |
| Disposable email | +45 | Fraudulent account creation indicator |
| VoIP phone number | +40 | Anonymous registration indicator |
| Missing device ID | +15 | Anomalous in mobile CNP environment |

### Backtesting Results

| Metric | Value | Interpretation |
|---|---|---|
| Transactions flagged for denial | 514 (16.07%) | 1 in 6 transactions would be reviewed |
| Fraud transactions caught | 391 (100% recall) | No fraudulent transaction would be approved |
| Legitimate transactions blocked | 123 | 4.38% false positive rate |
| Precision | 76.07% | 76 of every 100 denials are genuine fraud |

### Running the API

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

### 1. Money and Information Flow in the Payment Industry

A payment transaction involves five main players. The cardholder initiates a purchase at the merchant. The merchant's acquirer submits an authorisation request to the card network, which routes it to the issuing bank. The issuer approves or declines the transaction and the decision is returned along the same chain. At settlement — typically one to three business days later — funds flow from the issuer through the card network to the acquirer and finally to the merchant, net of interchange fees and the acquirer's merchant discount rate (MDR).

### 2. Acquirer vs Sub-Acquirer vs Payment Gateway

An acquirer holds a direct licence with card networks and bears full financial and regulatory risk for the transactions it processes. A sub-acquirer such as CloudWalk aggregates multiple merchants under a single acquirer contract, simplifying onboarding for smaller merchants while absorbing the chargeback and fraud liability that those merchants generate. A payment gateway is a technology intermediary only — it securely transmits card data between the merchant and the acquirer but assumes no financial risk.

### 3. Chargebacks vs Cancellations

A cancellation is a voluntary and cooperative refund initiated by the merchant or cardholder before or shortly after settlement. A chargeback is a forced transaction reversal initiated by the cardholder through their issuing bank, typically weeks after settlement, and carries financial penalties and a formal dispute process for the acquirer or sub-acquirer. Chargebacks are the primary financial consequence of fraud in the acquiring world — because they arrive after the fact, anti-fraud systems must make accurate decisions at the point of authorisation rather than attempting to remediate fraud after it has occurred.

### 4. What Is Anti-Fraud and How Does an Acquirer Use It

An anti-fraud system evaluates each transaction at the point of authorisation and returns an approve or deny recommendation in real time, typically within milliseconds. Acquirers and sub-acquirers deploy these systems to intercept fraudulent transactions before they are processed, thereby preventing chargeback losses and protecting their standing with card networks. For a sub-acquirer like CloudWalk, every fraudulent transaction that is approved results in a direct financial liability — making real-time fraud prevention a commercial and operational necessity.
