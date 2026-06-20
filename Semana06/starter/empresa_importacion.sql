--  SEMANA 06 — Funciones de Agregación
--  Dominio: bc-sql Empresa de Importación
--  Tablas: suppliers, products, shipments, customs

-- 0. CREAR TABLAS

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id   INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL,
    country       TEXT    NOT NULL,
    rating        REAL    DEFAULT 3.0
);

CREATE TABLE IF NOT EXISTS products (
    product_id    INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL,
    category      TEXT    NOT NULL,
    unit_price    REAL    NOT NULL
);

CREATE TABLE IF NOT EXISTS shipments (
    shipment_id   INTEGER PRIMARY KEY,
    supplier_id   INTEGER NOT NULL REFERENCES suppliers(supplier_id),
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL,
    total_value   REAL    NOT NULL,
    ship_date     TEXT    NOT NULL,   -- formato YYYY-MM-DD
    status        TEXT    NOT NULL    -- 'delivered', 'in_transit', 'pending'
);

CREATE TABLE IF NOT EXISTS customs (
    customs_id    INTEGER PRIMARY KEY,
    shipment_id   INTEGER NOT NULL REFERENCES shipments(shipment_id),
    duty_amount   REAL    NOT NULL,
    cleared       INTEGER NOT NULL DEFAULT 0,  -- 0=pendiente, 1=liberado
    cleared_date  TEXT
);


-- 1. DATOS SEMILLA — mínimo 30 filas en shipments
--    Distribución desigual: algunos suppliers tienen muchos envíos,
--    otros pocos. Algunas categorías dominan el volumen.

INSERT OR IGNORE INTO suppliers VALUES
(1, 'Shenzhen Tech Imports', 'China',     4.5),
(2, 'Seoul Electronics Co', 'Korea',      4.2),
(3, 'Mumbai Textiles Ltd',  'India',      3.8),
(4, 'Berlin Machinery GmbH','Germany',    4.7),
(5, 'São Paulo Agro SA',    'Brazil',     3.5),
(6, 'Jakarta Rubber Corp',  'Indonesia',  3.9);

INSERT OR IGNORE INTO products VALUES
(1,  'Laptop 15"',          'Electronics',  850.00),
(2,  'Smartphone X12',      'Electronics',  620.00),
(3,  'Cotton Fabric 100m',  'Textiles',      45.00),
(4,  'Industrial Motor 5HP','Machinery',   1200.00),
(5,  'Soybean Oil 1L',      'Agriculture',    2.80),
(6,  'Natural Rubber Sheet','Raw Material',  18.50),
(7,  'USB-C Cable 2m',      'Electronics',    4.20),
(8,  'Denim Jeans Bulk',    'Textiles',       28.00),
(9,  'CNC Spindle Part',    'Machinery',     340.00),
(10, 'Coffee Beans 1kg',    'Agriculture',    9.50);

-- shipments: 35 filas con distribución desigual
INSERT OR IGNORE INTO shipments VALUES
-- Shenzhen Tech Imports (supplier 1) — 10 envíos, dominante en Electronics
(101, 1, 1, 200,  170000.00, '2024-01-10', 'delivered'),
(102, 1, 2, 500,  310000.00, '2024-01-22', 'delivered'),
(103, 1, 7,5000,   21000.00, '2024-02-05', 'delivered'),
(104, 1, 1, 150,  127500.00, '2024-02-18', 'in_transit'),
(105, 1, 2, 300,  186000.00, '2024-03-01', 'delivered'),
(106, 1, 7,8000,   33600.00, '2024-03-15', 'delivered'),
(107, 1, 1, 100,   85000.00, '2024-04-02', 'pending'),
(108, 1, 2, 400,  248000.00, '2024-04-20', 'in_transit'),
(109, 1, 7,6000,   25200.00, '2024-05-08', 'delivered'),
(110, 1, 1, 220,  187000.00, '2024-05-30', 'delivered'),

-- Seoul Electronics Co (supplier 2) — 7 envíos
(201, 2, 2, 800,  496000.00, '2024-01-15', 'delivered'),
(202, 2, 1, 120,  102000.00, '2024-02-10', 'delivered'),
(203, 2, 7,10000,  42000.00, '2024-03-05', 'in_transit'),
(204, 2, 2, 600,  372000.00, '2024-04-12', 'delivered'),
(205, 2, 1, 250,  212500.00, '2024-05-01', 'delivered'),
(206, 2, 2, 350,  217000.00, '2024-05-22', 'pending'),
(207, 2, 7,7000,   29400.00, '2024-06-10', 'delivered'),

-- Mumbai Textiles Ltd (supplier 3) — 6 envíos
(301, 3, 3, 400,   18000.00, '2024-01-08', 'delivered'),
(302, 3, 8, 500,   14000.00, '2024-02-14', 'delivered'),
(303, 3, 3, 600,   27000.00, '2024-03-22', 'delivered'),
(304, 3, 8, 700,   19600.00, '2024-04-18', 'in_transit'),
(305, 3, 3, 350,   15750.00, '2024-05-10', 'pending'),
(306, 3, 8, 450,   12600.00, '2024-06-01', 'delivered'),

-- Berlin Machinery GmbH (supplier 4) — 6 envíos
(401, 4, 4,  50,   60000.00, '2024-01-20', 'delivered'),
(402, 4, 9, 100,   34000.00, '2024-02-28', 'delivered'),
(403, 4, 4,  80,   96000.00, '2024-03-30', 'delivered'),
(404, 4, 9, 150,   51000.00, '2024-04-25', 'in_transit'),
(405, 4, 4,  60,   72000.00, '2024-05-18', 'pending'),
(406, 4, 9, 200,   68000.00, '2024-06-15', 'delivered'),

-- São Paulo Agro SA (supplier 5) — 4 envíos
(501, 5, 5,5000,   14000.00, '2024-02-05', 'delivered'),
(502, 5,10,2000,   19000.00, '2024-03-18', 'delivered'),
(503, 5, 5,8000,   22400.00, '2024-04-30', 'delivered'),
(504, 5,10,1500,   14250.00, '2024-06-08', 'in_transit'),

-- Jakarta Rubber Corp (supplier 6) — 2 envíos (grupo pequeño)
(601, 6, 6,3000,   55500.00, '2024-03-10', 'delivered'),
(602, 6, 6,2000,   37000.00, '2024-05-25', 'pending');

-- customs: un registro por envío (35 filas)
INSERT OR IGNORE INTO customs VALUES
(1001, 101,  8500.00, 1, '2024-01-15'),
(1002, 102, 15500.00, 1, '2024-01-27'),
(1003, 103,  1050.00, 1, '2024-02-09'),
(1004, 104,  6375.00, 0, NULL),
(1005, 105,  9300.00, 1, '2024-03-06'),
(1006, 106,  1680.00, 1, '2024-03-20'),
(1007, 107,  4250.00, 0, NULL),
(1008, 108, 12400.00, 0, NULL),
(1009, 109,  1260.00, 1, '2024-05-12'),
(1010, 110,  9350.00, 1, '2024-06-04'),
(1011, 201, 24800.00, 1, '2024-01-20'),
(1012, 202,  5100.00, 1, '2024-02-15'),
(1013, 203,  2100.00, 0, NULL),
(1014, 204, 18600.00, 1, '2024-04-17'),
(1015, 205, 10625.00, 1, '2024-05-06'),
(1016, 206, 10850.00, 0, NULL),
(1017, 207,  1470.00, 1, '2024-06-15'),
(1018, 301,   900.00, 1, '2024-01-12'),
(1019, 302,   700.00, 1, '2024-02-19'),
(1020, 303,  1350.00, 1, '2024-03-27'),
(1021, 304,   980.00, 0, NULL),
(1022, 305,   787.50, 0, NULL),
(1023, 306,   630.00, 1, '2024-06-06'),
(1024, 401,  3000.00, 1, '2024-01-25'),
(1025, 402,  1700.00, 1, '2024-03-05'),
(1026, 403,  4800.00, 1, '2024-04-04'),
(1027, 404,  2550.00, 0, NULL),
(1028, 405,  3600.00, 0, NULL),
(1029, 406,  3400.00, 1, '2024-06-20'),
(1030, 501,   700.00, 1, '2024-02-10'),
(1031, 502,   950.00, 1, '2024-03-23'),
(1032, 503,  1120.00, 1, '2024-05-05'),
(1033, 504,   712.50, 0, NULL),
(1034, 601,  2775.00, 1, '2024-03-15'),
(1035, 602,  1850.00, 0, NULL);

-- ============================================================
-- CONSULTAS DE AGREGACIÓN
-- ============================================================

-- ------------------------------------------------------------
-- REPORTE 1 — COUNT
-- Total de envíos registrados en el sistema
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_shipments
FROM shipments;

-- ------------------------------------------------------------
-- REPORTE 2 — SUM + AVG
-- Valor total importado y valor promedio por envío
-- ------------------------------------------------------------
SELECT
    SUM(total_value) AS valor_total_importado,
    AVG(total_value) AS valor_promedio_por_envio,
    MIN(total_value) AS envio_mas_pequeno,
    MAX(total_value) AS envio_mas_grande
FROM shipments;

-- ------------------------------------------------------------
-- REPORTE 3 — GROUP BY con 2+ funciones de agregación
-- Resumen por proveedor: cuántos envíos, valor total e importe promedio
-- ------------------------------------------------------------
SELECT
    s.name                       AS proveedor,
    s.country                    AS pais,
    COUNT(sh.shipment_id)        AS total_envios,
    SUM(sh.total_value)          AS valor_total,
    ROUND(AVG(sh.total_value), 2) AS valor_promedio,
    SUM(sh.quantity)             AS unidades_totales
FROM suppliers s
JOIN shipments sh ON s.supplier_id = sh.supplier_id
GROUP BY s.supplier_id, s.name, s.country
ORDER BY valor_total DESC;

-- ------------------------------------------------------------
-- REPORTE 4 — GROUP BY por categoría de producto
-- Total facturado y promedio por categoría
-- ------------------------------------------------------------
SELECT
    p.category                    AS categoria,
    COUNT(sh.shipment_id)         AS num_envios,
    SUM(sh.total_value)           AS facturado_total,
    ROUND(AVG(sh.total_value), 2) AS promedio_por_envio
FROM products p
JOIN shipments sh ON p.product_id = sh.product_id
GROUP BY p.category
ORDER BY facturado_total DESC;

-- ------------------------------------------------------------
-- REPORTE 5 — HAVING: proveedores con volumen alto
-- Solo proveedores cuyo valor total supera los 500.000 USD
-- Condición de negocio: concentración de riesgo por proveedor
-- ------------------------------------------------------------
SELECT
    s.name                        AS proveedor,
    COUNT(sh.shipment_id)         AS total_envios,
    SUM(sh.total_value)           AS valor_total
FROM suppliers s
JOIN shipments sh ON s.supplier_id = sh.supplier_id
GROUP BY s.supplier_id, s.name
HAVING SUM(sh.total_value) > 500000
ORDER BY valor_total DESC;

-- ------------------------------------------------------------
-- REPORTE 6 — HAVING: categorías con más de 5 envíos
-- Para detectar categorías con alta frecuencia de importación
-- ------------------------------------------------------------
SELECT
    p.category                    AS categoria,
    COUNT(sh.shipment_id)         AS num_envios,
    SUM(sh.total_value)           AS valor_total
FROM products p
JOIN shipments sh ON p.product_id = sh.product_id
GROUP BY p.category
HAVING COUNT(sh.shipment_id) > 5
ORDER BY num_envios DESC;

-- ------------------------------------------------------------
-- REPORTE 7 (BONUS) — GROUP BY por estado del envío
-- Cuánto dinero está en cada etapa del pipeline logístico
-- ------------------------------------------------------------
SELECT
    status                        AS estado,
    COUNT(*)                      AS num_envios,
    SUM(total_value)              AS valor_en_estado,
    ROUND(AVG(total_value), 2)    AS promedio
FROM shipments
GROUP BY status
ORDER BY valor_en_estado DESC;

-- ------------------------------------------------------------
-- REPORTE 8 (BONUS) — Aranceles de aduana por proveedor
-- SUM de duty_amount agrupado, con HAVING para identificar
-- proveedores con carga arancelaria alta (> 20.000 USD)
-- ------------------------------------------------------------
SELECT
    s.name                         AS proveedor,
    COUNT(c.customs_id)            AS tramites_aduana,
    SUM(c.duty_amount)             AS total_aranceles,
    ROUND(AVG(c.duty_amount), 2)   AS arancel_promedio,
    SUM(CASE WHEN c.cleared = 1 THEN 1 ELSE 0 END) AS liberados,
    SUM(CASE WHEN c.cleared = 0 THEN 1 ELSE 0 END) AS pendientes
FROM suppliers s
JOIN shipments sh  ON s.supplier_id  = sh.supplier_id
JOIN customs   c   ON sh.shipment_id = c.shipment_id
GROUP BY s.supplier_id, s.name
HAVING SUM(c.duty_amount) > 20000
ORDER BY total_aranceles DESC;