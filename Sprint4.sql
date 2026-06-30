--Nivel 1
--Ejercicio 1

SELECT
    t.transaction_id,
    t.amount,
    t.declined,
    c.company_name,
    t.timestamp,
    t.card_id,
    t.product_ids,
    t.user_id,
    t.business_id,
    c.country
FROM `sprint3-analytics-luis-rayon.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-luis-rayon.sprint3_silver.companies_clean` AS c
    ON t.business_id = c.company_id
WHERE DATE(t.timestamp) = '2022-03-12'
  AND c.country = 'Germany'
;

--Ejercicio 2
--Paso 1

CREATE OR REPLACE TABLE `sprint3-analytics-luis-rayon.sprint3_silver.transactions_recent` AS
SELECT
    * EXCEPT(timestamp),
    TIMESTAMP_SUB(
        CURRENT_TIMESTAMP(),
        INTERVAL CAST(RAND() * 50 AS INT64) DAY
    ) AS timestamp
FROM `sprint3-analytics-luis-rayon.sprint3_silver.transactions_clean`
;

--Paso 2

CREATE OR REPLACE TABLE `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY business_id
AS
SELECT 
transaction_id,
business_id,
card_id,
user_id,
product_ids,
amount,
timestamp,
declined,
lat,
longitude
FROM `sprint3-analytics-luis-rayon.sprint3_silver.transactions_recent`
;

--Ejercicio 3
--Consulta a tabla transactions_recent

SELECT *
FROM `sprint3-analytics-luis-rayon.sprint3_silver.transactions_recent`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
;

--Consulta a tabla transactions_optimized

SELECT *
FROM `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
;

--Ejercicio 4
--Creamos la vista

CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-luis-rayon.sprint3_gold.mv_daily_sales`
AS
SELECT
    DATE(timestamp) AS fecha,
   SUM(amount) AS total_ventas
FROM `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized`
WHERE declined = 0
GROUP BY fecha
;

--Ejecutamos la consulta

SELECT
    fecha,
    ROUND(total_ventas, 2) AS total_ventas
FROM `sprint3-analytics-luis-rayon.sprint3_gold.mv_daily_sales`
ORDER BY fecha
;

--Nivel 2
--Ejercicio 1

WITH VIP_Stats AS (
    SELECT
        user_id,
        ROUND(SUM(amount),2) AS total_gastado,
        COUNT(transaction_id) AS numero_compras,
        ROUND(AVG(amount), 2) AS media_compras,
        ROUND(MAX(amount),2) AS compra_maxima
    FROM `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized`
    WHERE declined = 0
    GROUP BY user_id
    HAVING SUM(amount) > 500
)

SELECT
    v.user_id,
    CONCAT(u.name, ' ', u.surname) AS nombre_completo,
    u.email,
    v.numero_compras,
    v.media_compras,
    v.compra_maxima,
    ROUND(v.total_gastado,2)
FROM VIP_Stats v
JOIN `sprint3-analytics-luis-rayon.sprint3_silver.users_combined` AS u
    ON v.user_id = u.user_id
ORDER BY v.total_gastado DESC
;

--Ejercicio 2

WITH Comparador_Ventas AS (
    SELECT
        fecha,
        total_ventas,
        LAG(total_ventas) OVER (ORDER BY fecha) AS ventas_ayer
    FROM `sprint3-analytics-luis-rayon.sprint3_gold.mv_daily_sales`
)

SELECT
    fecha AS fecha,
    ROUND(total_ventas,2) AS ventas_hoy,
   ROUND(ventas_ayer,2) AS ventas_ayer,
    ROUND(
        SAFE_DIVIDE((total_ventas - ventas_ayer),ventas_ayer) * 100,
        2
    ) AS diferencia
FROM Comparador_Ventas
ORDER BY fecha
;

--Ejercicio 3

SELECT
    fecha AS fecha,
    ROUND(total_ventas, 2) AS ventas_dia,
    ROUND(
        SUM(total_ventas) OVER (
            PARTITION BY EXTRACT(YEAR FROM fecha)
            ORDER BY fecha
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS ventas_acumuladas
FROM `sprint3-analytics-luis-rayon.sprint3_gold.mv_daily_sales`
ORDER BY fecha
;

--Ejercicio 4

WITH clientes_cualificados AS (
    SELECT
        t.user_id,
        t.timestamp,
        t.amount,
        ROW_NUMBER() OVER (
            PARTITION BY t.user_id
            ORDER BY t.timestamp
        ) AS transacciones
    FROM `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized` AS t
    WHERE declined = 0
    QUALIFY transacciones <= 3
),

tercera_compra AS (
    SELECT
        user_id,
        timestamp AS fecha_compra,
        amount AS importe_tercera_compra
    FROM clientes_cualificados
    WHERE transacciones = 3
),

media_compras_cualificadas AS (
    SELECT
        user_id,
        ROUND(AVG(amount), 2) AS media_compras
    FROM clientes_cualificados
    GROUP BY user_id
)

SELECT
    u.user_id,
    CONCAT(u.name, ' ', u.surname) AS nombre_completo,
    u.email,
    tc.fecha_compra,
    tc.importe_tercera_compra,
    mc.media_compras
FROM tercera_compra AS tc
JOIN media_compras_cualificadas AS mc
    ON tc.user_id = mc.user_id
JOIN `sprint3-analytics-luis-rayon.sprint3_silver.users_combined` AS u
    ON tc.user_id = u.user_id
ORDER BY tc.fecha_compra
;
--Nivel 3
--Ejercicio 1

CREATE OR REPLACE TABLE `sprint3-analytics-luis-rayon.sprint3_gold.dim_transactions_flat` AS
SELECT
    t.transaction_id,
    t.timestamp,
    ROUND(t.amount,2) AS total_ticket,
    p.product_id AS product_sku,
    p.name AS product_name,
    ROUND(p.price,2) AS product_price
FROM `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized` AS t
CROSS JOIN UNNEST(t.product_ids) AS product_id
JOIN `sprint3-analytics-luis-rayon.sprint3_silver.products_clean` AS p
    ON SAFE_CAST(product_id AS INT64) = p.product_id
    WHERE declined = 0
;
--Ejercicio 2

SELECT
    product_name,
    COUNT(transaction_id) AS unidades_vendidas
FROM `sprint3-analytics-luis-rayon.sprint3_gold.dim_transactions_flat`
GROUP BY product_name
ORDER BY unidades_vendidas DESC
LIMIT 5
;

--Ejercicio 3
--UDF

CREATE OR REPLACE FUNCTION `sprint3-analytics-luis-rayon.sprint3_gold.calculate_tax`(amount FLOAT64)
RETURNS FLOAT64
AS (
  ROUND(amount * 1.21, 2)
)
;

--Integración y orquestación

CREATE OR REPLACE TABLE `sprint3-analytics-luis-rayon.sprint3_gold.dim_transactions_flat` AS
SELECT
    t.transaction_id,
    t.timestamp,
    ROUND(t.amount,2) AS total_ticket,
    p.product_id,
    p.name AS product_name,
    ROUND(p.price,2) AS product_price,
    `sprint3-analytics-luis-rayon.sprint3_gold.calculate_tax`(p.price)
        AS product_price_tax_inc
FROM `sprint3-analytics-luis-rayon.sprint3_gold.fact_transactions_optimized` AS t
CROSS JOIN UNNEST(t.product_ids) product_id
JOIN `sprint3-analytics-luis-rayon.sprint3_silver.products_clean` AS p
    ON SAFE_CAST(product_id AS INT64) = p.product_id
WHERE declined = 0
;