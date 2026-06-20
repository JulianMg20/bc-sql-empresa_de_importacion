-- ============================================================
--  PROYECTO INTEGRADOR — ETAPA 0
--  Semana 08 — Evidencia de Producto
--  Dominio: Empresa de Importación (bc-sql)
--  Tablas:  suppliers (proveedores)  -> tabla de referencia
--           products  (productos)    -> tabla de referencia
--           shipments (envíos)       -> tabla principal
--           customs   (aduana)       -> tabla dependiente (1:1 con shipments)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- 0. LIMPIAR TABLAS SI EXISTEN (para poder re-ejecutar el script)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS customs;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;

-- ============================================================
-- 1. ESQUEMA (DDL)
-- ============================================================

-- suppliers: tabla de referencia (lado "1" de la relación 1:N con shipments)
CREATE TABLE suppliers (
    supplier_id     INTEGER PRIMARY KEY,
    tax_code        TEXT    NOT NULL UNIQUE,            -- NIT/RUT único por proveedor
    name            TEXT    NOT NULL,
    country         TEXT    NOT NULL,
    contact_email   TEXT,                               -- OPCIONAL: puede ser NULL
    rating          REAL    NOT NULL DEFAULT 3.0
                            CHECK (rating >= 1.0 AND rating <= 5.0),
    active          INTEGER NOT NULL DEFAULT 1
                            CHECK (active IN (0, 1))
);

-- products: tabla de referencia
CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    sku             TEXT    NOT NULL UNIQUE,            -- código único de producto
    name            TEXT    NOT NULL,
    category        TEXT    NOT NULL
                            CHECK (category IN (
                                'Electronics','Textiles','Machinery',
                                'Agriculture','Raw Material'
                            )),
    unit_price      REAL    NOT NULL
                            CHECK (unit_price > 0),
    description     TEXT                               -- OPCIONAL: puede ser NULL
);

-- shipments: TABLA PRINCIPAL — relación 1:N con suppliers y con products
CREATE TABLE shipments (
    shipment_id     INTEGER PRIMARY KEY,
    tracking_code   TEXT    NOT NULL UNIQUE,            -- código de seguimiento único
    supplier_id     INTEGER NOT NULL
                            REFERENCES suppliers(supplier_id)
                            ON DELETE RESTRICT
                            ON UPDATE CASCADE,
    product_id      INTEGER NOT NULL
                            REFERENCES products(product_id)
                            ON DELETE RESTRICT
                            ON UPDATE CASCADE,
    quantity        INTEGER NOT NULL
                            CHECK (quantity > 0),
    total_value     REAL    NOT NULL
                            CHECK (total_value > 0),
    ship_date       TEXT    NOT NULL,                   -- formato YYYY-MM-DD
    arrival_date    TEXT,                               -- OPCIONAL: NULL si aún no llegó
    status          TEXT    NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('delivered','in_transit','pending','cancelled'))
);

-- customs: tabla dependiente (1:1 con shipments) — trámite aduanero por envío
CREATE TABLE customs (
    customs_id      INTEGER PRIMARY KEY,
    shipment_id     INTEGER NOT NULL UNIQUE             -- un trámite por envío
                            REFERENCES shipments(shipment_id)
                            ON DELETE CASCADE,
    duty_amount     REAL    NOT NULL
                            CHECK (duty_amount >= 0),
    cleared         INTEGER NOT NULL DEFAULT 0
                            CHECK (cleared IN (0, 1)),
    cleared_date    TEXT,                               -- OPCIONAL: NULL si no liberado
    inspector_notes TEXT                                -- OPCIONAL: NULL si no hay observaciones
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    suppliers: 10 filas | products: 10 filas
--    shipments: 35 filas (≥30 requerido)
--    customs:   35 filas (una por envío)
-- ============================================================

INSERT INTO suppliers VALUES
(1, 'CN-887234', 'Shenzhen Tech Imports',   'China',       'contact@shenzhen-tech.cn', 4.5, 1),
(2, 'KR-334421', 'Seoul Electronics Co',    'Korea',       'info@seoulec.kr',          4.2, 1),
(3, 'IN-992011', 'Mumbai Textiles Ltd',     'India',       NULL,                       3.8, 1),  -- sin email
(4, 'DE-110045', 'Berlin Machinery GmbH',   'Germany',     'sales@berlinmach.de',      4.7, 1),
(5, 'BR-556678', 'São Paulo Agro SA',       'Brazil',      NULL,                       3.5, 1),  -- sin email
(6, 'ID-223390', 'Jakarta Rubber Corp',     'Indonesia',   'export@jakartarubber.id',  3.9, 0),  -- inactivo
(7, 'VN-771122', 'Hanoi Garments JSC',      'Vietnam',     'sales@hanoigarments.vn',   4.0, 1),
(8, 'MX-440099', 'Monterrey Auto Parts SA', 'Mexico',      'ventas@monterreyap.mx',    4.1, 1),
(9, 'TR-665533', 'Istanbul Textile Group',  'Turkey',      NULL,                       3.6, 1),  -- sin email
(10,'TH-882211', 'Bangkok Rubber Exports',  'Thailand',    'info@bangkokrubber.th',    3.7, 1);

INSERT INTO products VALUES
(1,  'ELEC-LAP-001', 'Laptop 15"',           'Electronics',  850.00, 'Laptop empresarial Intel i7'),
(2,  'ELEC-PHN-002', 'Smartphone X12',       'Electronics',  620.00, NULL),               -- sin descripción
(3,  'TEXT-COT-003', 'Cotton Fabric 100m',   'Textiles',      45.00, 'Algodón 100% pima'),
(4,  'MACH-MOT-004', 'Industrial Motor 5HP', 'Machinery',   1200.00, NULL),               -- sin descripción
(5,  'AGRO-SOY-005', 'Soybean Oil 1L',       'Agriculture',    2.80, 'Aceite refinado grado A'),
(6,  'RAWM-RUB-006', 'Natural Rubber Sheet', 'Raw Material',  18.50, NULL),               -- sin descripción
(7,  'ELEC-USB-007', 'USB-C Cable 2m',       'Electronics',    4.20, 'Cable trenzado 100W'),
(8,  'TEXT-DEN-008', 'Denim Jeans Bulk',     'Textiles',      28.00, NULL),               -- sin descripción
(9,  'MACH-CNC-009', 'CNC Spindle Part',     'Machinery',    340.00, 'Husillo de precisión 0.01mm'),
(10, 'AGRO-COF-010', 'Coffee Beans 1kg',     'Agriculture',    9.50, 'Café arábica tostado medio');

INSERT INTO shipments VALUES
(101, 'TRK-2024-0101', 1, 1,  200, 170000.00, '2024-01-10', '2024-01-28', 'delivered'),
(102, 'TRK-2024-0102', 1, 2,  500, 310000.00, '2024-01-22', '2024-02-08', 'delivered'),
(103, 'TRK-2024-0103', 1, 7, 5000,  21000.00, '2024-02-05', '2024-02-20', 'delivered'),
(104, 'TRK-2024-0104', 1, 1,  150, 127500.00, '2024-02-18', NULL,         'in_transit'),
(105, 'TRK-2024-0105', 1, 2,  300, 186000.00, '2024-03-01', '2024-03-18', 'delivered'),
(106, 'TRK-2024-0106', 1, 7, 8000,  33600.00, '2024-03-15', '2024-03-29', 'delivered'),
(107, 'TRK-2024-0107', 1, 1,  100,  85000.00, '2024-04-02', NULL,         'pending'),
(108, 'TRK-2024-0108', 1, 2,  400, 248000.00, '2024-04-20', NULL,         'in_transit'),
(109, 'TRK-2024-0109', 1, 7, 6000,  25200.00, '2024-05-08', '2024-05-22', 'delivered'),
(110, 'TRK-2024-0110', 1, 1,  220, 187000.00, '2024-05-30', '2024-06-15', 'delivered'),
(201, 'TRK-2024-0201', 2, 2,  800, 496000.00, '2024-01-15', '2024-02-01', 'delivered'),
(202, 'TRK-2024-0202', 2, 1,  120, 102000.00, '2024-02-10', '2024-02-25', 'delivered'),
(203, 'TRK-2024-0203', 2, 7,10000,  42000.00, '2024-03-05', NULL,         'in_transit'),
(204, 'TRK-2024-0204', 2, 2,  600, 372000.00, '2024-04-12', '2024-04-28', 'delivered'),
(205, 'TRK-2024-0205', 2, 1,  250, 212500.00, '2024-05-01', '2024-05-17', 'delivered'),
(206, 'TRK-2024-0206', 2, 2,  350, 217000.00, '2024-05-22', NULL,         'pending'),
(207, 'TRK-2024-0207', 2, 7, 7000,  29400.00, '2024-06-10', '2024-06-24', 'delivered'),
(301, 'TRK-2024-0301', 3, 3,  400,  18000.00, '2024-01-08', '2024-01-22', 'delivered'),
(302, 'TRK-2024-0302', 3, 8,  500,  14000.00, '2024-02-14', '2024-02-28', 'delivered'),
(303, 'TRK-2024-0303', 3, 3,  600,  27000.00, '2024-03-22', '2024-04-05', 'delivered'),
(304, 'TRK-2024-0304', 3, 8,  700,  19600.00, '2024-04-18', NULL,         'in_transit'),
(305, 'TRK-2024-0305', 3, 3,  350,  15750.00, '2024-05-10', NULL,         'pending'),
(306, 'TRK-2024-0306', 3, 8,  450,  12600.00, '2024-06-01', '2024-06-15', 'delivered'),
(401, 'TRK-2024-0401', 4, 4,   50,  60000.00, '2024-01-20', '2024-02-05', 'delivered'),
(402, 'TRK-2024-0402', 4, 9,  100,  34000.00, '2024-02-28', '2024-03-14', 'delivered'),
(403, 'TRK-2024-0403', 4, 4,   80,  96000.00, '2024-03-30', '2024-04-13', 'delivered'),
(404, 'TRK-2024-0404', 4, 9,  150,  51000.00, '2024-04-25', NULL,         'in_transit'),
(405, 'TRK-2024-0405', 4, 4,   60,  72000.00, '2024-05-18', NULL,         'pending'),
(406, 'TRK-2024-0406', 4, 9,  200,  68000.00, '2024-06-15', '2024-06-28', 'delivered'),
(501, 'TRK-2024-0501', 5, 5, 5000,  14000.00, '2024-02-05', '2024-02-19', 'delivered'),
(502, 'TRK-2024-0502', 5,10, 2000,  19000.00, '2024-03-18', '2024-04-01', 'delivered'),
(503, 'TRK-2024-0503', 5, 5, 8000,  22400.00, '2024-04-30', '2024-05-14', 'delivered'),
(504, 'TRK-2024-0504', 5,10, 1500,  14250.00, '2024-06-08', NULL,         'in_transit'),
(601, 'TRK-2024-0601', 6, 6, 3000,  55500.00, '2024-03-10', '2024-03-24', 'delivered'),
(602, 'TRK-2024-0602', 6, 6, 2000,  37000.00, '2024-05-25', NULL,         'pending');

INSERT INTO customs VALUES
(1001, 101,  8500.00, 1, '2024-01-30', NULL),
(1002, 102, 15500.00, 1, '2024-02-10', NULL),
(1003, 103,  1050.00, 1, '2024-02-22', NULL),
(1004, 104,  6375.00, 0, NULL,         NULL),
(1005, 105,  9300.00, 1, '2024-03-20', NULL),
(1006, 106,  1680.00, 1, '2024-03-31', NULL),
(1007, 107,  4250.00, 0, NULL,         'Documentos incompletos'),
(1008, 108, 12400.00, 0, NULL,         NULL),
(1009, 109,  1260.00, 1, '2024-05-24', NULL),
(1010, 110,  9350.00, 1, '2024-06-17', NULL),
(1011, 201, 24800.00, 1, '2024-02-03', NULL),
(1012, 202,  5100.00, 1, '2024-02-27', NULL),
(1013, 203,  2100.00, 0, NULL,         'En revisión fitosanitaria'),
(1014, 204, 18600.00, 1, '2024-04-30', NULL),
(1015, 205, 10625.00, 1, '2024-05-19', NULL),
(1016, 206, 10850.00, 0, NULL,         NULL),
(1017, 207,  1470.00, 1, '2024-06-26', NULL),
(1018, 301,   900.00, 1, '2024-01-24', NULL),
(1019, 302,   700.00, 1, '2024-03-01', NULL),
(1020, 303,  1350.00, 1, '2024-04-07', NULL),
(1021, 304,   980.00, 0, NULL,         NULL),
(1022, 305,   787.50, 0, NULL,         'Certificado de origen pendiente'),
(1023, 306,   630.00, 1, '2024-06-17', NULL),
(1024, 401,  3000.00, 1, '2024-02-07', NULL),
(1025, 402,  1700.00, 1, '2024-03-16', NULL),
(1026, 403,  4800.00, 1, '2024-04-15', NULL),
(1027, 404,  2550.00, 0, NULL,         NULL),
(1028, 405,  3600.00, 0, NULL,         'Requiere inspección técnica'),
(1029, 406,  3400.00, 1, '2024-06-30', NULL),
(1030, 501,   700.00, 1, '2024-02-21', NULL),
(1031, 502,   950.00, 1, '2024-04-03', NULL),
(1032, 503,  1120.00, 1, '2024-05-16', NULL),
(1033, 504,   712.50, 0, NULL,         NULL),
(1034, 601,  2775.00, 1, '2024-03-26', NULL),
(1035, 602,  1850.00, 0, NULL,         'Proveedor inactivo — revisión especial');

-- ============================================================
-- 3. CONSULTAS DE REPORTE (SELECT)
-- ============================================================

-- ------------------------------------------------------------
-- REPORTE 1 — TOTALES GLOBALES (COUNT, SUM, AVG)
-- Visión general de toda la operación de importación
-- ------------------------------------------------------------
SELECT
    COUNT(*)                       AS total_envios,
    SUM(total_value)               AS valor_total_importado,
    ROUND(AVG(total_value), 2)     AS valor_promedio_envio,
    MIN(total_value)               AS envio_minimo,
    MAX(total_value)               AS envio_maximo
FROM shipments;

-- ------------------------------------------------------------
-- REPORTE 2 — REPORTE POR CATEGORÍA (GROUP BY + ORDER BY)
-- Cuánto se ha importado de cada categoría de producto
-- ------------------------------------------------------------
SELECT
    p.category                     AS categoria,
    COUNT(sh.shipment_id)          AS num_envios,
    SUM(sh.total_value)            AS facturado_total,
    ROUND(AVG(sh.total_value), 2)  AS promedio_por_envio
FROM products p
JOIN shipments sh ON p.product_id = sh.product_id
GROUP BY p.category
ORDER BY facturado_total DESC;

-- ------------------------------------------------------------
-- REPORTE 3 — GRUPOS CON UMBRAL (GROUP BY + HAVING)
-- Proveedores cuyo valor total importado supera los 500.000 USD
-- (sirve para detectar concentración de riesgo por proveedor)
-- ------------------------------------------------------------
SELECT
    s.name                         AS proveedor,
    s.country                      AS pais,
    COUNT(sh.shipment_id)          AS total_envios,
    SUM(sh.total_value)            AS valor_total
FROM suppliers s
JOIN shipments sh ON s.supplier_id = sh.supplier_id
GROUP BY s.supplier_id, s.name, s.country
HAVING SUM(sh.total_value) > 500000
ORDER BY valor_total DESC;

-- ------------------------------------------------------------
-- REPORTE 4 — MANEJO DE NULL (IS NULL / COALESCE)
-- Envíos sin fecha de llegada confirmada; se muestra el estado
-- actual en lugar del NULL para que el reporte sea legible
-- ------------------------------------------------------------
SELECT
    sh.tracking_code               AS codigo_seguimiento,
    s.name                         AS proveedor,
    sh.ship_date                   AS fecha_envio,
    COALESCE(sh.arrival_date, '— ' || sh.status) AS llegada
FROM shipments sh
JOIN suppliers s ON sh.supplier_id = s.supplier_id
WHERE sh.arrival_date IS NULL
ORDER BY sh.ship_date;

-- ------------------------------------------------------------
-- REPORTE 5 — BÚSQUEDA COMBINADA (WHERE + rango/patrón)
-- Envíos de Electronics entregados con valor entre 100.000 y 300.000 USD
-- ------------------------------------------------------------
SELECT
    sh.tracking_code               AS codigo_seguimiento,
    p.name                         AS producto,
    p.category                     AS categoria,
    sh.total_value                 AS valor,
    sh.status                      AS estado
FROM shipments sh
JOIN products p ON sh.product_id = p.product_id
WHERE p.category = 'Electronics'
  AND sh.status = 'delivered'
  AND sh.total_value BETWEEN 100000 AND 300000
ORDER BY sh.total_value DESC;