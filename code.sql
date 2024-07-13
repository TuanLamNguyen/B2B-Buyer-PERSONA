-- create accounts table
CREATE TABLE accounts (
    account VARCHAR,
    sector VARCHAR,
    year_established VARCHAR,
    revenue VARCHAR,
    employees VARCHAR,
    office_location VARCHAR,
    subsidiary_of VARCHAR
);

-- create products table
CREATE TABLE products (
    product VARCHAR,
    series VARCHAR,
    sales_price VARCHAR
);

-- create sales_teams table
CREATE TABLE sales_teams (
    sales_agent VARCHAR,
    manager VARCHAR,
    regional_office VARCHAR
);

-- create sales_pipeline table
CREATE TABLE sales_pipeline (
    opportunity_id VARCHAR,
    sales_agent VARCHAR,
    product VARCHAR,
    account VARCHAR,
    deal_stage VARCHAR,
    engage_date VARCHAR,
    close_date VARCHAR,
    close_value VARCHAR
);

-- accounts table
ALTER TABLE accounts
    ALTER COLUMN year_established TYPE INTEGER USING year_established::INTEGER,
    ALTER COLUMN revenue TYPE NUMERIC USING revenue::NUMERIC,
    ALTER COLUMN employees TYPE INTEGER USING employees::INTEGER;

--  products table
ALTER TABLE products
    ALTER COLUMN sales_price TYPE NUMERIC USING sales_price::NUMERIC;

--  sales_pipeline table
ALTER TABLE sales_pipeline
    ALTER COLUMN engage_date TYPE DATE USING engage_date::DATE,
    ALTER COLUMN close_date TYPE DATE USING close_date::DATE,
    ALTER COLUMN close_value TYPE NUMERIC USING close_value::NUMERIC;

UPDATE sales_pipeline
SET account = 'unknown'
WHERE account IS NULL 
  AND (deal_stage = 'Engaging' OR deal_stage = 'Prospecting')
  AND close_date IS NULL 
  AND close_value IS NULL;

WITH ranked_data AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY id, "opportunity_id" ORDER BY opportunity_id) AS rnk
    FROM
        sales_pipeline
)

DELETE FROM sales_pipeline
WHERE opportunity_id IN (
    SELECT opportunity_id
    FROM ranked_data
    WHERE rnk > 1
);

WITH abc AS (
    SELECT
        q1 - 1.5 * iqr AS min,
        q3 + 1.5 * iqr AS max
    FROM (
        SELECT
            percentile_cont(0.25) WITHIN GROUP (ORDER BY "revenue") AS q1,
            percentile_cont(0.75) WITHIN GROUP (ORDER BY "revenue") AS q3,
            percentile_cont(0.75) WITHIN GROUP (ORDER BY "revenue") - percentile_cont(0.25) WITHIN GROUP (ORDER BY "revenue") AS iqr
        FROM sales_pipeline
    ) AS a
)

SELECT * FROM sales_pipeline
WHERE "revenue" < (SELECT min FROM abc)
   OR "revenue" > (SELECT max FROM abc)



