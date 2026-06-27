CREATE DATABASE financial_dashboard;

USE financial_dashboard;

CREATE TABLE stocks (
    symbol VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    sector VARCHAR(50),
    market_cap_billion DECIMAL(15, 2),  -- Calculated in billions
    exchange VARCHAR(20) DEFAULT 'NSE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE stocks;

CREATE TABLE stocks (
    symbol VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    sector VARCHAR(50),
    market_cap_adjusted_ngn_billion DECIMAL(12, 2),
    exchange VARCHAR(20) DEFAULT 'NSE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stock_prices (
    price_id INT PRIMARY KEY AUTO_INCREMENT,
    symbol VARCHAR(20) NOT NULL,
    trade_date DATE NOT NULL,
    open_price DECIMAL(10, 4),
    high_price DECIMAL(10, 4),
    low_price DECIMAL(10, 4),
    close_price DECIMAL(10, 4),
    volume BIGINT,
    daily_return DECIMAL(8, 4),
    sma_20 DECIMAL(10, 4),
    sma_50 DECIMAL(10, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_symbol_date (symbol, trade_date),
    INDEX idx_symbol (symbol),
    INDEX idx_date (trade_date),
    FOREIGN KEY (symbol) REFERENCES stocks(symbol)
);

CREATE TABLE exchange_rates (
    rate_id INT PRIMARY KEY AUTO_INCREMENT,
    rate_date DATE NOT NULL UNIQUE,
    usd_ngn_rate DECIMAL(10, 4) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (rate_date)
);

CREATE TABLE nse_index (
    index_id INT PRIMARY KEY AUTO_INCREMENT,
    trade_date DATE NOT NULL UNIQUE,
    open_price DECIMAL(12, 2),
    high_price DECIMAL(12, 2),
    low_price DECIMAL(12, 2),
    close_price DECIMAL(12, 2),
    volume BIGINT,
    daily_return DECIMAL(8, 4),
    sma_20 DECIMAL(12, 2),
    sma_50 DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (trade_date)
);

-- Check stocks
SELECT COUNT(*) as total_stocks FROM stocks;

-- Check stock prices
SELECT COUNT(*) as total_prices FROM stock_prices;

-- Check exchange rates
SELECT COUNT(*) as total_rates FROM exchange_rates;

-- Check NSE index
SELECT COUNT(*) as total_index FROM nse_index;

-- View sample data
SELECT * FROM stocks LIMIT 5;
SELECT * FROM stock_prices LIMIT 5;
SELECT * FROM exchange_rates LIMIT 5;
SELECT * FROM nse_index LIMIT 5;

SELECT symbol, company_name, sector FROM stocks;

INSERT INTO stocks (symbol, company_name, sector, market_cap_adjusted_ngn_billion)
VALUES 
('DANGCEM', 'Dangote Cement', 'Industrial', 10202.10),
('MTNN', 'MTN Nigeria', 'Telecommunications', 10715.70);

DELETE FROM stock_prices;

SELECT symbol, COUNT(*) as row_count FROM stock_prices GROUP BY symbol;

SELECT DISTINCT symbol FROM stock_prices ORDER BY symbol;

SELECT symbol, COUNT(*) as row_count 
FROM stock_prices 
GROUP BY symbol 
ORDER BY symbol;

SELECT * FROM stocks WHERE symbol = 'SEPLAT';

SELECT COUNT(*) FROM stock_prices;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/Benita/Downloads/stock_prices.csv'
INTO TABLE stock_prices
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(trade_date, open_price, high_price, low_price, close_price, volume, symbol, daily_return, sma_20, sma_50);

DELETE FROM stocks WHERE symbol = 'SEPLAT';

SELECT COUNT(*) FROM stocks;
-- Should show 6 now

SELECT * FROM stocks;
-- Should show only: ACCESS, DANGCEM, FIRST_HOLDCO, GTCO, MTNN, ZENITH

INSERT INTO stocks (symbol, company_name, sector, market_cap_adjusted_ngn_billion)
VALUES ('SEPLAT', 'Seplat Petroleum', 'Energy', 3310200000);

SELECT * FROM nse_index;

DELETE FROM nse_index;

-- Top Performers
SELECT 
    stocks.symbol,
    stocks.company_name,
    stocks.sector,
    stocks.market_cap_Adjusted_ngn_billion,
    ROUND((MAX(stock_prices.close_price) - MIN(stock_prices.close_price)) / MIN(stock_prices.close_price) * 100, 2) as period_return_pct,
    ROUND(AVG(stock_prices.daily_return), 4) as avg_daily_return,
    ROUND(STDDEV(stock_prices.daily_return), 4) as volatility,
    ROUND(MAX(stock_prices.close_price), 2) as current_price,
    ROUND(MIN(stock_prices.close_price), 2) as lowest_price,
    ROUND(SUM(stock_prices.volume), 0) as total_volume,
    ROUND(AVG(stock_prices.daily_return) / STDDEV(stock_prices.daily_return), 4) as sharpe_ratio,
    CASE 
        WHEN (MAX(stock_prices.close_price) - MIN(stock_prices.close_price)) / MIN(stock_prices.close_price) * 100 > 20 THEN 'Excellent'
        WHEN (MAX(stock_prices.close_price) - MIN(stock_prices.close_price)) / MIN(stock_prices.close_price) * 100 > 10 THEN 'Good'
        WHEN (MAX(stock_prices.close_price) - MIN(stock_prices.close_price)) / MIN(stock_prices.close_price) * 100 > 0 THEN 'Positive'
        ELSE 'Negative'
    END as performance_rating
FROM stock_prices
JOIN stocks ON stock_prices.symbol = stocks.symbol
GROUP BY stocks.symbol
ORDER BY period_return_pct DESC;

SELECT 
    symbol,
    MIN(trade_date) as first_date,
    MAX(trade_date) as last_date,
    COUNT(*) as total_rows
FROM stock_prices
GROUP BY symbol
ORDER BY symbol;

-- Volatility Analysis
SELECT 
    stocks.symbol,
    stocks.company_name,
    stocks.sector,
    ROUND(STDDEV(stock_prices.daily_return), 4) as volatility,
    ROUND(AVG(stock_prices.daily_return), 4) as avg_daily_return,
    ROUND(MAX(stock_prices.daily_return), 4) as best_day,
    ROUND(MIN(stock_prices.daily_return), 4) as worst_day,
    CASE 
        WHEN STDDEV(stock_prices.daily_return) < 0.015 THEN 'Low'
        WHEN STDDEV(stock_prices.daily_return) < 0.025 THEN 'Medium'
        WHEN STDDEV(stock_prices.daily_return) < 0.04 THEN 'High'
        ELSE 'Very High'
    END as risk_category
FROM stock_prices
JOIN stocks ON stock_prices.symbol = stocks.symbol
GROUP BY stocks.symbol
ORDER BY volatility DESC;

-- Sector Performance
SELECT 
    stocks.symbol,
    stocks.company_name,
    stocks.sector,
    ROUND(STDDEV(stock_prices.daily_return), 4) as volatility,
    ROUND(AVG(stock_prices.daily_return), 4) as avg_daily_return,
    ROUND(MAX(stock_prices.daily_return), 4) as best_day,
    ROUND(MIN(stock_prices.daily_return), 4) as worst_day,
    CASE 
        WHEN STDDEV(stock_prices.daily_return) < 0.015 THEN 'Low'
        WHEN STDDEV(stock_prices.daily_return) < 0.025 THEN 'Medium'
        WHEN STDDEV(stock_prices.daily_return) < 0.04 THEN 'High'
        ELSE 'Very High'
    END as risk_category
FROM stock_prices
JOIN stocks ON stock_prices.symbol = stocks.symbol
GROUP BY stocks.symbol
ORDER BY volatility DESC;

-- Price vs Moving average
SELECT 
    stock_prices.trade_date,
    COUNT(DISTINCT stock_prices.symbol) as stocks_traded,
    SUM(CASE WHEN stock_prices.daily_return > 0 THEN 1 ELSE 0 END) as gainers,
    SUM(CASE WHEN stock_prices.daily_return < 0 THEN 1 ELSE 0 END) as losers,
    ROUND(AVG(stock_prices.daily_return), 4) as market_avg_return,
    ROUND(SUM(stock_prices.volume), 0) as total_volume,
    CASE 
        WHEN AVG(stock_prices.daily_return) > 0.005 THEN 'Bullish'
        WHEN AVG(stock_prices.daily_return) < -0.005 THEN 'Bearish'
        ELSE 'Neutral'
    END as market_sentiment
FROM stock_prices
GROUP BY stock_prices.trade_date
ORDER BY stock_prices.trade_date DESC
LIMIT 30;

-- Daily Market Summary
SELECT 
    stock_prices.trade_date,
    COUNT(DISTINCT stock_prices.symbol) as stocks_traded,
    SUM(CASE WHEN stock_prices.daily_return > 0 THEN 1 ELSE 0 END) as gainers,
    SUM(CASE WHEN stock_prices.daily_return < 0 THEN 1 ELSE 0 END) as losers,
    ROUND(AVG(stock_prices.daily_return), 4) as market_avg_return,
    ROUND(SUM(stock_prices.volume), 0) as total_volume,
    CASE 
        WHEN AVG(stock_prices.daily_return) > 0.005 THEN 'Bullish'
        WHEN AVG(stock_prices.daily_return) < -0.005 THEN 'Bearish'
        ELSE 'Neutral'
    END as market_sentiment
FROM stock_prices
GROUP BY stock_prices.trade_date
ORDER BY stock_prices.trade_date DESC
LIMIT 30;

-- Stock Comparison Table
SELECT 
    stocks.symbol,
    stocks.company_name,
    stocks.sector,
    stocks.market_cap_Adjusted_ngn_billion,
    COUNT(*) as trading_days,
    ROUND(MAX(stock_prices.close_price), 2) as current_price,
    ROUND(MIN(stock_prices.close_price), 2) as lowest_price,
    ROUND((MAX(stock_prices.close_price) - MIN(stock_prices.close_price)) / MIN(stock_prices.close_price) * 100, 2) as period_return_pct,
    ROUND(AVG(stock_prices.daily_return), 4) as avg_daily_return,
    ROUND(STDDEV(stock_prices.daily_return), 4) as volatility
FROM stock_prices
JOIN stocks ON stock_prices.symbol = stocks.symbol
GROUP BY stocks.symbol
ORDER BY period_return_pct DESC;

-- Export stock prices for Power BI
SELECT * FROM stock_prices
ORDER BY symbol, trade_date;

-- Export stocks reference
SELECT * FROM stocks;

-- Export daily summaries
SELECT * FROM nse_index;