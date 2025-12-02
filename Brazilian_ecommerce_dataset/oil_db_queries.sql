-- Miesięczna liczba zamówień i przychodów w całym okresie dostępnym w danych
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS liczba_zamowien,
    SUM(oi.price) AS przychod
    -- z uwzględnieniem kosztów dostawy: SUM(oi.price + oi.freight_value) AS przychod
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- Miesięczna liczba zamówień i przychodów w całym okresie dostępnym w danych w formacie YYYY-MM
SELECT
    TO_CHAR(DATE_TRUNC('month', o.order_purchase_timestamp), 'YYYY-MM') AS rok_miesiac,
    COUNT(DISTINCT o.order_id) AS liczba_zamowien,
    SUM(oi.price) AS przychod
    -- z uwzględnieniem kosztów dostawy: SUM(oi.price + oi.freight_value) AS przychod
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
GROUP BY TO_CHAR(DATE_TRUNC('month', o.order_purchase_timestamp), 'YYYY-MM')
ORDER BY rok_miesiac;

-- Kategorie produktów, które generują najwyższe przychody. Top 5.
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS kategoria,
    SUM(oi.price) AS przychod
    -- z uwzględnieniem kosztów dostawy: SUM(oi.price + oi.freight_value) AS przychod
FROM olist_order_items oi
JOIN olist_products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name)
ORDER BY przychod DESC
LIMIT 5;

-- Średnia wartość zamówienia (koszyk) dla poszczególnych metod płatności
SELECT
    op.payment_type AS metoda_platnosci,
    ROUND(AVG(order_total)::numeric, 2) AS srednia_wartosc_zamowienia
FROM (
    SELECT
        o.order_id,
        SUM(oi.price + oi.freight_value) AS order_total
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id
) AS orders_summary
JOIN olist_order_payments op
    ON orders_summary.order_id = op.order_id
GROUP BY op.payment_type
ORDER BY srednia_wartosc_zamowienia DESC;

-- Najbardziej dochodowe stany (geograficznie) dla Olist. Top 5.
SELECT
    c.customer_state AS stan,
    SUM(oi.price + oi.freight_value) AS przychod
FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
JOIN olist_customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY przychod DESC
LIMIT 5;

-- Średni czas dostawy i ile zamówień dotarło po obiecanym terminie. Analiza opóźnień
WITH base AS (
  SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date
  FROM olist_orders
  WHERE order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
)
SELECT
  -- średni czas dostawy w dniach (z dokładnością do 2 miejsc)
  ROUND(
    AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))) / 86400
  ::numeric, 2) AS sredni_czas_dostawy_dni,

  -- liczba zamówień opóźnionych względem obiecanego terminu
  COUNT(*) FILTER (
    WHERE order_delivered_customer_date > order_estimated_delivery_date
  ) AS liczba_opoznionych_zamowien,

  -- liczba wszystkich zamówień w analizie
  COUNT(*) AS liczba_wszystkich_zamowien,

  -- procent opóźnionych
  ROUND(
    100.0 * COUNT(*) FILTER (
      WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) / COUNT(*)
  , 2) AS procent_opoznionych
FROM base;

-- Top 10 sprzedawców pod względem liczby sprzedanych produktów.
SELECT
    oi.seller_id,
    COUNT(oi.product_id) AS liczba_sprzedanych_produktow
FROM olist_order_items oi
GROUP BY oi.seller_id
ORDER BY liczba_sprzedanych_produktow DESC
LIMIT 10;

-- Top 5 stanów z największą liczbą sprzedanych produktów
SELECT
    s.seller_state AS stan,
    COUNT(oi.product_id) AS liczba_sprzedanych_produktow
FROM olist_order_items oi
JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY liczba_sprzedanych_produktow DESC
LIMIT 5;

-- Top 5 miast z największą liczbą sprzedanych produktów
SELECT
    s.seller_city AS miasto,
    COUNT(oi.product_id) AS liczba_sprzedanych_produktow
FROM olist_order_items oi
JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_city
ORDER BY liczba_sprzedanych_produktow DESC
LIMIT 5;

-- Top 5 stanów wg przychodów
SELECT
    s.seller_state AS stan,
    SUM(oi.price + oi.freight_value) AS przychod
FROM olist_order_items oi
JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY przychod DESC
LIMIT 5;

-- Top 5 miast wg przychodów
SELECT
    s.seller_city AS miasto,
    SUM(oi.price + oi.freight_value) AS przychod
FROM olist_order_items oi
JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_city
ORDER BY przychod DESC
LIMIT 5;

-- Średnia ocena (review score) produktów w zależności od kategorii
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS kategoria,
    ROUND(AVG(r.review_score)::numeric, 2) AS srednia_ocena
FROM olist_order_reviews r
JOIN olist_order_items oi
    ON r.order_id = oi.order_id
JOIN olist_products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name)
ORDER BY srednia_ocena desc
limit 15;

-- Segmentacja klientów na podstawie częstotliwości i wartości ich zamówień (prosta analiza RFM), identyfikacja klientów o najwyższej wartości.
WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp
),
rfm AS (
    SELECT
        customer_id,
        -- Recency: liczba dni od ostatniego zakupu do dziś
        DATE_PART('day', CURRENT_DATE - MAX(order_purchase_timestamp)) AS recency,
        -- Frequency: liczba zamówień
        COUNT(order_id) AS frequency,
        -- Monetary: suma wartości zamówień
        SUM(order_value) AS monetary
    FROM customer_orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    recency,
    frequency,
    ROUND(monetary::numeric, 2) AS monetary
FROM rfm
ORDER BY monetary DESC
LIMIT 20;  -- top 20 klientów o najwyższej wartości

-- Analiza RFM z klasyfikacją klientów dla określonych progów wartości
WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp
),
rfm AS (
    SELECT
        customer_id,
        DATE_PART('day', CURRENT_DATE - MAX(order_purchase_timestamp)) AS recency,
        COUNT(order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM customer_orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    recency,
    frequency,
    ROUND(monetary::numeric, 2) AS monetary,
    CASE
        WHEN monetary >= 5000 AND frequency >= 5 AND recency <= 30 THEN 'High-Value'
        WHEN monetary >= 2000 AND frequency >= 2 AND recency <= 90 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS segment
FROM rfm
ORDER BY segment, monetary DESC;

-- Analiza RFM z klasyfikacją klientów dla określonych progów wartości i procentowym udziale poszczególnych segmentów
WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM olist_orders o
    JOIN olist_order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp
),
rfm AS (
    SELECT
        customer_id,
        DATE_PART('day', CURRENT_DATE - MAX(order_purchase_timestamp)) AS recency,
        COUNT(order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM customer_orders
    GROUP BY customer_id
),
segmented AS (
    SELECT
        customer_id,
        CASE
            WHEN monetary >= 5000 AND frequency >= 5 AND recency <= 30 THEN 'High-Value'
            WHEN monetary >= 2000 AND frequency >= 2 AND recency <= 90 THEN 'Medium-Value'
            ELSE 'Low-Value'
        END AS segment
    FROM rfm
)
SELECT
    segment,
    COUNT(*) AS liczba_klientow,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(*) FROM segmented),
        2
    ) AS procent_udzial
FROM segmented
GROUP BY segment
ORDER BY procent_udzial DESC;