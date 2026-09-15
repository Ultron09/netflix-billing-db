-- ==============================================================================
-- NETFLIX BILLING & SUBSCRIPTION DATABASE SCHEMA (SQLite / DDL)
-- Source: netflix_billing_schema_erd.html
-- Target: SQLite 3.x (Lightweight, Serverless, Production-Grade Relational Model)
-- ==============================================================================

PRAGMA foreign_keys = ON;

-- 1. USERS TABLE
DROP TABLE IF EXISTS REVENUE_LEDGER;
DROP TABLE IF EXISTS PAYMENTS;
DROP TABLE IF EXISTS INVOICES;
DROP TABLE IF EXISTS PAYMENT_METHODS;
DROP TABLE IF EXISTS SUBSCRIPTIONS;
DROP TABLE IF EXISTS TAX_RATES;
DROP TABLE IF EXISTS SUBSCRIPTION_PLANS;
DROP TABLE IF EXISTS USERS;

CREATE TABLE USERS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    country_code TEXT NOT NULL CHECK(length(country_code) = 2),
    account_status TEXT NOT NULL CHECK(account_status IN ('ACTIVE', 'SUSPENDED', 'CANCELLED', 'PENDING')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. SUBSCRIPTION PLANS TABLE
CREATE TABLE SUBSCRIPTION_PLANS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_name TEXT NOT NULL,
    tier TEXT NOT NULL CHECK(tier IN ('STANDARD_WITH_ADS', 'BASIC', 'STANDARD', 'PREMIUM')),
    monthly_price NUMERIC(10, 2) NOT NULL CHECK(monthly_price >= 0),
    currency_code TEXT NOT NULL CHECK(length(currency_code) = 3),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1))
);

-- 3. TAX RATES TABLE
CREATE TABLE TAX_RATES (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_code TEXT NOT NULL CHECK(length(country_code) = 2),
    region_code TEXT,
    tax_type TEXT NOT NULL,
    rate_percent NUMERIC(5, 2) NOT NULL CHECK(rate_percent >= 0),
    effective_from DATE NOT NULL
);

-- 4. SUBSCRIPTIONS TABLE
CREATE TABLE SUBSCRIPTIONS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    plan_id INTEGER NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('ACTIVE', 'PAST_DUE', 'CANCELLED', 'PAUSED')),
    start_date DATE NOT NULL,
    next_billing_date DATE,
    auto_renew INTEGER NOT NULL DEFAULT 1 CHECK(auto_renew IN (0, 1)),
    cancelled_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USERS(id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES SUBSCRIPTION_PLANS(id) ON DELETE RESTRICT
);

-- 5. PAYMENT METHODS TABLE
CREATE TABLE PAYMENT_METHODS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    method_type TEXT NOT NULL CHECK(method_type IN ('CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL', 'UPI', 'GIFT_CARD')),
    provider TEXT NOT NULL,
    last4 TEXT NOT NULL CHECK(length(last4) = 4),
    expiry_date DATE,
    is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
    FOREIGN KEY (user_id) REFERENCES USERS(id) ON DELETE CASCADE
);

-- 6. INVOICES TABLE
CREATE TABLE INVOICES (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subscription_id INTEGER NOT NULL,
    tax_rate_id INTEGER,
    invoice_number TEXT NOT NULL UNIQUE,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    subtotal_amount NUMERIC(10, 2) NOT NULL CHECK(subtotal_amount >= 0),
    tax_amount NUMERIC(10, 2) NOT NULL CHECK(tax_amount >= 0),
    total_amount NUMERIC(10, 2) NOT NULL CHECK(total_amount >= 0),
    status TEXT NOT NULL CHECK(status IN ('DRAFT', 'ISSUED', 'PAID', 'VOID', 'UNCOLLECTIBLE')),
    FOREIGN KEY (subscription_id) REFERENCES SUBSCRIPTIONS(id) ON DELETE RESTRICT,
    FOREIGN KEY (tax_rate_id) REFERENCES TAX_RATES(id) ON DELETE SET NULL
);

-- 7. PAYMENTS TABLE
CREATE TABLE PAYMENTS (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,
    payment_method_id INTEGER NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK(amount >= 0),
    status TEXT NOT NULL CHECK(status IN ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED')),
    processor_ref TEXT,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES INVOICES(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_method_id) REFERENCES PAYMENT_METHODS(id) ON DELETE RESTRICT
);

-- 8. REVENUE LEDGER TABLE
CREATE TABLE REVENUE_LEDGER (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,
    recognized_amount NUMERIC(10, 2) NOT NULL,
    revenue_type TEXT NOT NULL CHECK(revenue_type IN ('SUBSCRIPTION', 'ADD_ON', 'AD_REVENUE', 'PENALTY')),
    recognition_date DATE NOT NULL,
    gl_account_code TEXT NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES INVOICES(id) ON DELETE CASCADE
);

-- PERFORMANCE & FOREIGN KEY INDEXES
CREATE INDEX idx_users_email ON USERS(email);
CREATE INDEX idx_subscriptions_user ON SUBSCRIPTIONS(user_id);
CREATE INDEX idx_subscriptions_plan ON SUBSCRIPTIONS(plan_id);
CREATE INDEX idx_subscriptions_status ON SUBSCRIPTIONS(status);
CREATE INDEX idx_payment_methods_user ON PAYMENT_METHODS(user_id);
CREATE INDEX idx_invoices_subscription ON INVOICES(subscription_id);
CREATE INDEX idx_invoices_status ON INVOICES(status);
CREATE INDEX idx_payments_invoice ON PAYMENTS(invoice_id);
CREATE INDEX idx_payments_method ON PAYMENTS(payment_method_id);
CREATE INDEX idx_revenue_ledger_invoice ON REVENUE_LEDGER(invoice_id);
