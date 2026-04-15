-- ============================================================
-- exploratory analysis
-- transactional fraud detection
-- ============================================================


-- ============================================================
-- Data type correction
-- ============================================================

alter table [dbo].[transactional-sample] alter column transaction_id varchar(20);

alter table [dbo].[transactional-sample] alter column merchant_id varchar(20);

alter table [dbo].[transactional-sample] alter column user_id varchar(20);

alter table [dbo].[transactional-sample] alter column card_number varchar(20);

alter table [dbo].[transactional-sample] alter column trasnacation_date varchar(20);

alter table [dbo].[transactional-sample] alter column transaction_date varchar(40);

alter table [dbo].[transactional-sample] alter column transaction_amount float;

alter table [dbo].[transactional-sample] alter column device_id varchar(20);

alter table [dbo].[transactional-sample] alter column has_cbk varchar(10);

alter table [dbo].[transactional-sample] alter column time varchar(5);

alter table [dbo].[transactional-sample] alter column hour int;

alter table [dbo].[transactional-sample] alter column is_fraud int;

alter table [dbo].[transactional-sample] alter column amount_bucket varchar(10);

alter table [dbo].[transactional-sample] alter column risk_hour varchar(10);


-- ============================================================
-- Clean missing device values
-- ============================================================

update [dbo].[transactional-sample]
set device = null
where device = 'MISSING';

alter table [dbo].[transactional-sample] alter column device int;



-- ============================================================
-- Fraud rate by hour —
-- ============================================================
 
select
    hour,
    count(*) as total_txns,
    sum(is_fraud) as fraud_txns,
    cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) as fraud_rate_pct
from [dbo].[transactional-sample]
group by hour
order by hour asc;


-- ============================================================
-- Classify transactions by time of day risk
-- ============================================================

update [dbo].[transactional-sample]
set risk_hour =
    case
        when hour >= 22 or hour <= 5 then 'High'
        when hour >= 19 and hour <= 21 then 'Medium'
        else 'Low'
    end;


-- ============================================================
-- Dataset overview
-- summary statistics covering transaction volume, unique entities,
-- amount distribution, fraud counts, fraud rate, and missing device rate
-- ============================================================

select
    count(*) as total_transactions,
    count(distinct user_id) as unique_users,
    count(distinct merchant_id) as unique_merchants,
    count(distinct card_number) as unique_cards,
    cast(avg(transaction_amount) as decimal(10,2)) as avg_amount,
    cast(min(transaction_amount) as decimal(10,2)) as min_amount,
    cast(max(transaction_amount) as decimal(10,2)) as max_amount,
    cast(avg(case when is_fraud = 1 then transaction_amount end) as decimal(10,2)) as avg_amount_fraud,
    cast(avg(case when is_fraud = 0 then transaction_amount end) as decimal(10,2)) as avg_amount_legit,
    sum(is_fraud) as total_fraud_txns,
    count(*) - sum(is_fraud) as total_legit_txns,
    cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) as fraud_rate_pct,
    sum(case when device is null then 1 else 0 end) as missing_device_count,
    cast(sum(case when device is null then 1 else 0 end) * 100.0 / count(*) as decimal(5,2)) as missing_device_pct
from [dbo].[transactional-sample];


-- ============================================================
-- Total unique users
-- ============================================================

select
    count(distinct user_id) as total_users
from [dbo].[transactional-sample];


-- ============================================================
-- Overall fraud rate using a cte
-- ============================================================

with base as (
    select
        count(*) as total_transactions,
        sum(is_fraud) as total_fraud_transactions,
        cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) as fraud_percentage
    from [dbo].[transactional-sample]
)
select * from base;


-- ============================================================
-- Create view: user velocity
-- used to detect high-velocity behaviour 
-- ============================================================

create view vw_user_velocity as
select
    transaction_id,
    trasnacation_date,
    user_id,
    hour,
    is_fraud,
    transaction_amount,
    count(*) over (partition by user_id, trasnacation_date, hour) as transactions_in_the_same_hour
from [dbo].[transactional-sample];


-- ============================================================
-- Create view: fraud users
-- used for chargeback history lookups in the rules engine
-- ============================================================

create view vw_fraud_users as
select distinct user_id
from [dbo].[transactional-sample]
where is_fraud = 1;


-- ============================================================
-- Create view: merchant risk profile
-- aggregates transaction volume, fraud count, fraud rate,
-- total and average transacted value per merchant
-- classifies each merchant as high risk, medium risk or low risk
-- ============================================================

create view vw_merchant_risk as
select
    merchant_id,
    count(*) as total_transactions,
    sum(is_fraud) as fraud_transactions,
    cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) as fraud_rate_pct,
    cast(sum(transaction_amount) as decimal(12,2)) as total_revenue,
    cast(avg(transaction_amount) as decimal(10,2)) as avg_transactions,
    case
        when cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) >= 80 then 'high risk'
        when cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) >= 40 then 'medium risk'
        else 'low risk'
    end as risk_level
from [dbo].[transactional-sample]
group by merchant_id;


-- ============================================================
-- Combined risk profile per transaction
-- joins the main table with all three views to produce
-- a unified view of each transaction showing velocity,
-- fraud history, and merchant risk classification
-- ============================================================

select
    t.transaction_id,
    t.user_id,
    t.transaction_amount,
    t.is_fraud,
    v.transactions_in_the_same_hour,
    case when f.user_id is not null then 1 else 0 end as has_fraud_history,
    m.risk_level as merchant_risk_level
from [dbo].[transactional-sample] t
left join vw_user_velocity v on t.transaction_id = v.transaction_id
left join vw_fraud_users f on t.user_id = f.user_id
left join vw_merchant_risk m on t.merchant_id = m.merchant_id
order by merchant_risk_level asc;


-- ============================================================
-- Fraud rate by transaction amount bucket
-- groups transactions into amount ranges and calculates
-- the fraud rate per bucket to quantify the relationship
-- between transaction size and fraud probability
-- classifies each bucket as high, medium or low risk
-- ============================================================

with amount_fraud as (
    select
        amount_bucket,
        count(*) as total_transactions,
        sum(is_fraud) as fraud_transactions,
        cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) as fraud_rate_pct,
        cast(avg(transaction_amount) as decimal(10,2)) as avg_amount
    from [dbo].[transactional-sample]
    group by amount_bucket
)
select
    amount_bucket,
    total_transactions,
    fraud_transactions,
    fraud_rate_pct,
    avg_amount,
    case
        when fraud_rate_pct >= 80 then 'high risk'
        when fraud_rate_pct >= 15 then 'medium risk'
        else 'low risk'
    end as risk_level
from amount_fraud
order by fraud_rate_pct desc;


-- ============================================================
-- Top 20 highest risk merchants
-- returns the merchants with the highest fraud rate
-- filtered to only include merchants with 5 or more transactions
-- to avoid statistical distortion from low-volume accounts
-- ============================================================

select top 20
    merchant_id,
    total_transactions,
    fraud_transactions,
    fraud_rate_pct,
    total_revenue,
    avg_transactions
from vw_merchant_risk
where total_transactions >= 5
order by fraud_rate_pct desc;


-- ============================================================
-- Top 20 merchants by transacted value
-- identifies the highest-value merchants by total revenue
-- includes fraud rate to flag high-value merchants that also
-- carry significant fraud exposure
-- ============================================================

select top 20
    merchant_id,
    total_transactions,
    total_revenue,
    avg_transactions,
    fraud_rate_pct
from vw_merchant_risk
order by total_revenue desc;


-- ============================================================
-- Top 10 merchants by fraud amount
-- returns the merchants with the highest average fraudulent
-- transaction amount, identifying where fraud is most costly
-- ============================================================

select top 10
    merchant_id,
    count(distinct user_id) as unique_users,
    cast(avg(case when is_fraud = 1 then transaction_amount end) as decimal(10,2)) as avg_amount_fraud
from [dbo].[transactional-sample]
group by merchant_id
order by avg_amount_fraud desc;


-- ============================================================
-- User risk profiling 
-- ============================================================

with user_stats as (
    select
        t.user_id,
        count(*) as total_txns,
        sum(t.is_fraud) as fraud_txns,
        cast(avg(t.transaction_amount) as decimal(10,2)) as avg_amount,
        cast(sum(t.transaction_amount) as decimal(10,2)) as total_spent,
        max(v.transactions_in_the_same_hour) as max_velocity,
        case when f.user_id is not null then 1 else 0 end as has_fraud_history
    from [dbo].[transactional-sample] t
    left join vw_user_velocity v on t.transaction_id = v.transaction_id
    left join vw_fraud_users f on t.user_id = f.user_id
    group by t.user_id, f.user_id
),

user_risk_profile as (
    select
        user_id,
        total_txns,
        fraud_txns,
        avg_amount,
        total_spent,
        max_velocity,
        has_fraud_history,
        case
            when has_fraud_history = 1 and max_velocity >= 3   then 'critical'
            when has_fraud_history = 1 and avg_amount >= 1000  then 'high'
            when has_fraud_history = 1                         then 'high'
            when max_velocity >= 3 and avg_amount >= 1000      then 'high'
            when max_velocity >= 3                             then 'medium'
            when avg_amount >= 1000                            then 'medium'
            else                                                    'low'
        end as risk_tier
    from user_stats
)

select
    risk_tier,
    count(*) as total_users,
    sum(total_txns) as total_txns,
    sum(fraud_txns) as total_fraud_txns,
    cast(sum(fraud_txns) * 100.0 / nullif(sum(total_txns), 0) as decimal(5,2)) as fraud_rate_pct,
    cast(avg(avg_amount) as decimal(10,2)) as avg_transaction_amount,
    cast(avg(max_velocity) as decimal(5,2)) as avg_max_velocity
from user_risk_profile
group by risk_tier
order by
    case risk_tier
        when 'critical' then 1
        when 'high'     then 2
        when 'medium'   then 3
        when 'low'      then 4
    end;


-- ============================================================
-- Fraud rate by hour and risk period
-- used to identify which hours carry the highest fraud risk
-- ============================================================

select
    hour,
    risk_hour,
    count(*) as total_txns,
    sum(is_fraud) as fraud_txns,
    cast(sum(is_fraud) * 100.0 / count(*) as decimal(5,2)) as fraud_rate_pct,
    cast(avg(transaction_amount) as decimal(10,2)) as avg_amount
from [dbo].[transactional-sample]
group by hour, risk_hour
order by fraud_rate_pct desc;


-- ============================================================
-- Add shared card flag column
-- identifies card numbers used by more than one user_id
-- ============================================================

alter table [dbo].[transactional-sample]
add card_shared int;

update t
set t.card_shared = case when c.user_count > 1 then 1 else 0 end
from [dbo].[transactional-sample] t
inner join (
    select
        card_number,
        count(distinct user_id) as user_count
    from [dbo].[transactional-sample]
    group by card_number
) c on t.card_number = c.card_number;


-- ============================================================
-- Add velocity column from user velocity view
-- ============================================================

alter table [dbo].[transactional-sample]
add transactions_in_hour int;

update t
set t.transactions_in_hour = v.transactions_in_the_same_hour
from [dbo].[transactional-sample] t
inner join [dbo].[vw_user_velocity] v
    on t.transaction_id = v.transaction_id;


-- ============================================================
-- Add would_deny flag column
-- simulates the anti-fraud rules engine against the full dataset
-- ============================================================

alter table [dbo].[transactional-sample]
add would_deny int;

update t
set t.would_deny = case
    when t.card_shared = 1 then 1
    when t.user_id in (
        select distinct user_id
        from [dbo].[transactional-sample]
        where is_fraud = 1
    ) then 1
    when t.transactions_in_hour >= 3 then 1
    else 0
end
from [dbo].[transactional-sample] t;
