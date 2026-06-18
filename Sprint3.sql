--Nivel 1

--Ejercicio 1
CREATE SCHEMA 'sprint3-analytics-luis-rayon.sprint3_silver'
OPTIONS (
    location = 'EU'
);

--Ejercicio 2
CREATE OR REPLACE EXTERNAL TABLE 'sprint3-analytics-luis-rayon.sprint3_bronze.transactions_raw'
OPTIONS ( 
    format = 'CSV', 
    uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'], 
    skip_leading_rows = 1, 
    field_delimiter = ';' 
);

CREATE OR REPLACE EXTERNAL TABLE 'sprint3-analytics-luis-rayon.sprint3_bronze.companies_raw' (
    company_id STRING,
    company_name STRING,
    phone STRING,
    email STRING,
    country STRING,
    website STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
    skip_leading_rows = 1,
    field_delimiter = ','
);

CREATE OR REPLACE EXTERNAL TABLE 'sprint3-analytics-luis-rayon.sprint3_bronze.american_users_raw' 
OPTIONS ( 
    format = 'CSV', 
    uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'], 
    skip_leading_rows = 1, 
    field_delimiter = ',' 
); 

CREATE OR REPLACE EXTERNAL TABLE 'sprint3-analytics-luis-rayon.sprint3_bronze.european_users_raw' 
OPTIONS ( 
    format = 'CSV', 
    uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'], 
    skip_leading_rows = 1, 
    field_delimiter = ',' 
);

CREATE OR REPLACE EXTERNAL TABLE 'sprint3-analytics-luis-rayon.sprint3_bronze.credit_cards_raw'
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
    skip_leading_rows = 1,
    field_delimiter = ','
);

--Ejercicio 3 (No hay código)

--Ejercicio 4
--a)

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_bronze.transactions_raw_native' AS 
SELECT *
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.transactions_raw' 
;

--b)

SELECT id FROM 'sprint3_bronze.transactions_raw'
;

SELECT id FROM 'sprint3_bronze.transactions_raw_native'
;

--c)
SELECT * FROM 'sprint3_bronze.transactions_raw_native'
;

SELECT * FROM 'sprint3_bronze.transactions_raw_native'
LIMIT 10
;

--Ejercicio 5

SELECT
    DATE(timestamp) AS fecha,
    ROUND(SUM(amount),2) AS ingresos
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.transactions_raw_native'
WHERE EXTRACT(YEAR FROM timestamp) = 2021
GROUP BY fecha
ORDER BY ingresos DESC
LIMIT 5
;

--Ejercicio 6

SELECT
    c.company_name AS nombre,
    c.country AS pais,
    DATE(t.timestamp) AS fecha
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.transactions_raw_native' AS t
JOIN 'sprint3-analytics-luis-rayon.sprint3_bronze.companies_raw' AS c
ON t.business_id = c.company_id
WHERE t.amount BETWEEN 100 AND 200
    AND DATE(t.timestamp) IN (
        DATE '2015-04-29',
        DATE '2018-07-20',
        DATE '2024-03-13'
        )
ORDER BY fecha, nombre
;

--Nivel 2
--Ejercicio 1

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_silver.products_clean' AS
SELECT
    id AS product_id,
    product_name AS name,
    CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
    CAST(price AS FLOAT64) AS price,
    weight,
    colour,
    category,
    brand,
    cost,
    launch_date
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.products_raw'
;

--Ejercicio 2

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_silver.transactions_clean' AS
SELECT
    id AS transaction_id,
    card_id,
    business_id,
    timestamp,
    IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
    declined,
    ARRAY(
        SELECT SAFE_CAST(TRIM(product_id) AS INT64)
        FROM UNNEST(SPLIT(product_ids, ',')) AS product_id
    ) AS product_ids,

    user_id,

    SAFE_CAST(lat AS FLOAT64) AS lat,

    SAFE_CAST(longitude AS FLOAT64) AS longitude

FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.transactions_raw'
;

--Ejercicio 3

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_silver.users_combined' AS

SELECT
    id AS user_id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    'USA' AS origin
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.american_users_raw'

UNION ALL

SELECT
    id AS user_id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    'Europe' AS origin
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.european_users_raw'
;

--Ejercicio 4

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_silver.companies_clean' AS
SELECT
    company_id,
    company_name,
    phone,
    email,
    country,
    website
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.companies_raw'
;

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_silver.credit_cards_clean' AS
SELECT
    id AS card_id,
    user_id,
    iban,
    pan,
    pin,
    cvv,
    track1,
    track2,
    expiring_date
FROM 'sprint3-analytics-luis-rayon.sprint3_bronze.credit_cards_raw'
;

--Nivel 3
--Ejercicio 1

CREATE OR REPLACE VIEW 'sprint3-analytics-luis-rayon.sprint3_gold.v_marketing_kpis' AS
SELECT
    c.company_name,
    c.phone,
    c.country,
    ROUND(AVG(t.amount),2) AS media_compra,
    CASE
        WHEN AVG(t.amount) > 260 THEN 'Premium'
        ELSE 'Standard'
    END AS tipo_cliente
FROM 'sprint3-analytics-luis-rayon.sprint3_silver.companies_clean' AS c
INNER JOIN 'sprint3-analytics-luis-rayon.sprint3_silver.transactions_clean' AS t
    ON c.company_id = t.business_id
GROUP BY
    c.company_name,
    c.phone,
    c.country
;

SELECT *
FROM 'sprint3-analytics-luis-rayon.sprint3_gold.v_marketing_kpis'
ORDER BY
    tipo_cliente ASC,
    media_compra DESC
;

--Ejercicio 2

CREATE OR REPLACE TABLE 'sprint3-analytics-luis-rayon.sprint3_gold.product_sales_ranking' AS

WITH product_sales AS (
    SELECT
        product_id,
        COUNT(*) AS ventas_totales
    FROM 'sprint3-analytics-luis-rayon.sprint3_silver.transactions_clean',
         UNNEST(product_ids) AS product_id
    GROUP BY product_id
    )

SELECT
    p.product_id,
    p.name,
    p.price,
    p.colour,
    IFNULL(ps.ventas_totales, 0) AS ventas_totales
FROM 'sprint3-analytics-luis-rayon.sprint3_silver.products_clean' AS p
LEFT JOIN product_sales AS ps
    ON p.product_id = ps.product_id
;

SELECT *
FROM 'sprint3-analytics-luis-rayon.sprint3_gold.product_sales_ranking'
ORDER BY ventas_totales DESC, product_id
;

--Ejercicio 3

SELECT *
FROM 'sprint3-analytics-luis-rayon.sprint3_gold.product_sales_ranking'
ORDER BY ventas_totales DESC, product_id
;