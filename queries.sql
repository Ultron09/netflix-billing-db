-- ==============================================================================
-- NETFLIX BILLING SYSTEM: ASSIGNMENT ANALYTICAL & OPERATIONAL QUERIES
-- Database: netflix_billing.db (SQLite)
-- ==============================================================================

.mode box
.header on

-- ------------------------------------------------------------------------------
-- QUERY 1: Active Subscribers Overview with Plan Details & Default Payment Method
-- Demonstrates: 4-table JOIN, Filtering, Conditional Aliasing
-- ------------------------------------------------------------------------------
SELECT 
    u.id AS user_id,
    u.full_name,
    u.country_code,
    sp.plan_name,
    sp.tier,
    sp.monthly_price || ' ' || sp.currency_code AS price,
    pm.provider AS default_payment_provider,
    pm.last4 AS card_last4,
    s.status AS subscription_status,
    s.next_billing_date
FROM USERS u
JOIN SUBSCRIPTIONS s ON u.id = s.user_id
JOIN SUBSCRIPTION_PLANS sp ON s.plan_id = sp.id
LEFT JOIN PAYMENT_METHODS pm ON u.id = pm.user_id AND pm.is_default = 1
WHERE s.status = 'ACTIVE'
ORDER BY u.id ASC;

-- ------------------------------------------------------------------------------
-- QUERY 2: Monthly Recurring Revenue (MRR) & Subscriber Count by Plan Tier
-- Demonstrates: GROUP BY, COUNT, SUM, Formatting
-- ------------------------------------------------------------------------------
SELECT 
    sp.tier,
    sp.currency_code,
    COUNT(s.id) AS active_subscribers,
    ROUND(SUM(sp.monthly_price), 2) AS total_monthly_runrate
FROM SUBSCRIPTIONS s
JOIN SUBSCRIPTION_PLANS sp ON s.plan_id = sp.id
WHERE s.status = 'ACTIVE'
GROUP BY sp.tier, sp.currency_code
ORDER BY sp.currency_code, total_monthly_runrate DESC;

-- ------------------------------------------------------------------------------
-- QUERY 3: Invoice Settlement & Audit (Billing Reconciliation)
-- Demonstrates: Invoices joined with Tax Rates & Settlement Status
-- ------------------------------------------------------------------------------
SELECT 
    i.invoice_number,
    u.full_name AS subscriber,
    i.billing_period_start || ' to ' || i.billing_period_end AS billing_cycle,
    i.subtotal_amount,
    COALESCE(tr.tax_type, 'None') AS tax_type,
    COALESCE(tr.rate_percent, 0) || '%' AS tax_rate,
    i.tax_amount,
    i.total_amount,
    i.status AS invoice_status,
    COALESCE(p.status, 'UNPAID') AS payment_status,
    COALESCE(p.processor_ref, 'N/A') AS transaction_ref
FROM INVOICES i
JOIN SUBSCRIPTIONS s ON i.subscription_id = s.id
JOIN USERS u ON s.user_id = u.id
LEFT JOIN TAX_RATES tr ON i.tax_rate_id = tr.id
LEFT JOIN PAYMENTS p ON i.id = p.invoice_id AND p.status = 'SUCCEEDED'
ORDER BY i.id ASC;

-- ------------------------------------------------------------------------------
-- QUERY 4: Tax Collection Summary by Country & Jurisdiction
-- Demonstrates: Aggregation over financial records, Tax compliance
-- ------------------------------------------------------------------------------
SELECT 
    tr.country_code,
    tr.tax_type,
    tr.rate_percent || '%' AS tax_percentage,
    COUNT(i.id) AS invoices_count,
    ROUND(SUM(i.subtotal_amount), 2) AS total_taxable_subtotal,
    ROUND(SUM(i.tax_amount), 2) AS total_tax_collected
FROM INVOICES i
JOIN TAX_RATES tr ON i.tax_rate_id = tr.id
WHERE i.status = 'PAID'
GROUP BY tr.country_code, tr.tax_type, tr.rate_percent
ORDER BY total_tax_collected DESC;

-- ------------------------------------------------------------------------------
-- QUERY 5: Revenue Recognition Ledger by GL Account Code
-- Demonstrates: Financial Accounting compliance (ASC 606 / IFRS 15), Ledger reporting
-- ------------------------------------------------------------------------------
SELECT 
    rl.gl_account_code,
    rl.revenue_type,
    COUNT(rl.id) AS recognition_events,
    ROUND(SUM(rl.recognized_amount), 2) AS total_recognized_revenue
FROM REVENUE_LEDGER rl
GROUP BY rl.gl_account_code, rl.revenue_type
ORDER BY total_recognized_revenue DESC;

-- ------------------------------------------------------------------------------
-- QUERY 6: Risk & Delinquency Audit (Past Due Subscriptions & Failed Charges)
-- Demonstrates: Churn prevention, failed transaction tracking
-- ------------------------------------------------------------------------------
SELECT 
    u.id AS user_id,
    u.full_name,
    u.email,
    s.status AS subscription_status,
    i.invoice_number,
    i.total_amount AS amount_due,
    p.status AS payment_attempt_status,
    p.processor_ref AS failure_reason,
    p.processed_at AS attempt_timestamp
FROM USERS u
JOIN SUBSCRIPTIONS s ON u.id = s.user_id
JOIN INVOICES i ON s.id = i.subscription_id
LEFT JOIN PAYMENTS p ON i.id = p.invoice_id
WHERE s.status = 'PAST_DUE' OR p.status = 'FAILED'
ORDER BY p.processed_at DESC;
