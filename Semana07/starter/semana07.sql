PRAGMA foreign_keys = ON;
DROP TABLE IF EXISTS customs;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;

CREATE TABLE suppliers (
    supplier_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,                 -- nombre único
    country TEXT NOT NULL,
    rating REAL DEFAULT 3.0 CHECK(rating BETWEEN 1 AND 5) -- validación de negocio
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    unit_price REAL NOT NULL CHECK(unit_price > 0)
);

CREATE TABLE shipments (
    shipment_id INTEGER PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    total_value REAL NOT NULL CHECK(total_value >= 0),
    ship_date TEXT NOT NULL,   -- formato YYYY-MM-DD
    status TEXT NOT NULL CHECK(status IN ('delivered','in_transit','pending'))
);

CREATE TABLE customs (
    customs_id INTEGER PRIMARY KEY,
    shipment_id INTEGER NOT NULL REFERENCES shipments(shipment_id),
    duty_amount REAL NOT NULL CHECK(duty_amount >= 0),
    cleared INTEGER NOT NULL DEFAULT 0 CHECK(cleared IN (0,1)), -- 0=pendiente, 1=liberado
    cleared_date TEXT   -- puede ser NULL
);

-- Datos de ejemplo
INSERT INTO suppliers (name, country, rating) VALUES
    ('Acuamarine Imports', 'Chile', 4.7),
    ('Global Trade SA', 'México', 3.9),
    ('Oceanic Exports', 'Perú', 4.2);

INSERT INTO products (name, category, unit_price) VALUES
    ('Aceite de oliva', 'Alimentos', 12.50),
    ('Café en grano', 'Bebidas', 8.30),
    ('Vino tinto', 'Bebidas', 18.00);

INSERT INTO shipments (supplier_id, product_id, quantity, total_value, ship_date, status) VALUES
    (1, 1, 100, 1250.00, '2026-06-01', 'delivered'),
    (2, 2, 50, 415.00, '2026-06-05', 'pending'),
    (3, 3, 20, 360.00, '2026-06-07', 'in_transit');

INSERT INTO customs (shipment_id, duty_amount, cleared, cleared_date) VALUES
    (1, 75.00, 1, '2026-06-03'),
    (2, 30.00, 0, NULL),
    (3, 48.00, 0, NULL);

-- 1) Envíos con proveedor y producto
SELECT s.shipment_id,
       p.name AS producto,
       sup.name AS proveedor,
       s.quantity,
       s.total_value,
       s.status,
       s.ship_date
FROM shipments s
JOIN products p ON s.product_id = p.product_id
JOIN suppliers sup ON s.supplier_id = sup.supplier_id;

-- 2) Trámites de aduana pendientes
SELECT c.customs_id,
       c.shipment_id,
       sup.name AS proveedor,
       p.name AS producto,
       c.duty_amount,
       c.cleared,
       COALESCE(c.cleared_date, 'Pendiente') AS fecha_liberacion
FROM customs c
JOIN shipments s ON c.shipment_id = s.shipment_id
JOIN suppliers sup ON s.supplier_id = sup.supplier_id
JOIN products p ON s.product_id = p.product_id
WHERE c.cleared = 0;

-- 3) Estado de los envíos y monto total
SELECT shipment_id,
       status,
       total_value,
       CASE
           WHEN status = 'delivered' THEN 'Entregado'
           WHEN status = 'in_transit' THEN 'En tránsito'
           ELSE 'Pendiente'
       END AS estado_descripcion
FROM shipments;
