-- ============================================================
--  PROYECTO — SEMANA 10: SELF JOIN en tu dominio
--  Dominio: Empresa de Importación (bc-sql)
--  Entidad jerárquica: product_categories (categorías de productos)
--  Columna auto-referencial: parent_category_id
--  Jerarquía: Categoría raíz -> Subcategoría -> Sub-subcategoría (hoja)
--  Ejemplo: Electronics -> Computers -> Laptops
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- 0. LIMPIAR TABLA SI EXISTE (para poder re-ejecutar el script)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS product_categories;

-- ============================================================
-- 1. ESQUEMA (DDL)
-- ============================================================

-- product_categories: tabla con AUTO-REFERENCIA (parent_category_id
-- apunta a category_id de la misma tabla). category_level es solo
-- informativo para validar visualmente la profundidad del árbol
-- (1 = raíz, 2 = subcategoría, 3 = hoja).
CREATE TABLE product_categories (
    category_id          INTEGER PRIMARY KEY,
    category_code        TEXT    NOT NULL UNIQUE,
    name                 TEXT    NOT NULL,
    parent_category_id   INTEGER
                                 REFERENCES product_categories(category_id)
                                 ON DELETE RESTRICT
                                 ON UPDATE CASCADE,
    category_level       INTEGER NOT NULL
                                 CHECK (category_level IN (1, 2, 3))
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    80 filas en 3 niveles jerárquicos:
--      Nivel 1 (raíz, parent_category_id = NULL): 8 filas
--      Nivel 2 (subcategoría):                    22 filas
--      Nivel 3 (hoja):                             50 filas
-- ============================================================

INSERT INTO product_categories (category_id, category_code, name, parent_category_id, category_level) VALUES
(1, 'CAT-001', 'Electronics', NULL, 1),
(2, 'CAT-002', 'Textiles', NULL, 1),
(3, 'CAT-003', 'Machinery', NULL, 1),
(4, 'CAT-004', 'Agriculture', NULL, 1),
(5, 'CAT-005', 'Raw Material', NULL, 1),
(6, 'CAT-006', 'Automotive Parts', NULL, 1),
(7, 'CAT-007', 'Furniture', NULL, 1),
(8, 'CAT-008', 'Chemicals', NULL, 1),
(9, 'CAT-009', 'Computers', 1, 2),
(10, 'CAT-010', 'Mobile Devices', 1, 2),
(11, 'CAT-011', 'Audio Equipment', 1, 2),
(12, 'CAT-012', 'Cables & Connectors', 1, 2),
(13, 'CAT-013', 'Cotton Products', 2, 2),
(14, 'CAT-014', 'Synthetic Fabrics', 2, 2),
(15, 'CAT-015', 'Denim Goods', 2, 2),
(16, 'CAT-016', 'Industrial Motors', 3, 2),
(17, 'CAT-017', 'CNC Components', 3, 2),
(18, 'CAT-018', 'Hydraulic Systems', 3, 2),
(19, 'CAT-019', 'Oils & Fats', 4, 2),
(20, 'CAT-020', 'Grains', 4, 2),
(21, 'CAT-021', 'Coffee & Cocoa', 4, 2),
(22, 'CAT-022', 'Metals', 5, 2),
(23, 'CAT-023', 'Rubber & Polymers', 5, 2),
(24, 'CAT-024', 'Engine Components', 6, 2),
(25, 'CAT-025', 'Electrical Systems', 6, 2),
(26, 'CAT-026', 'Body Parts', 6, 2),
(27, 'CAT-027', 'Office Furniture', 7, 2),
(28, 'CAT-028', 'Home Furniture', 7, 2),
(29, 'CAT-029', 'Industrial Chemicals', 8, 2),
(30, 'CAT-030', 'Agrochemicals', 8, 2),
(31, 'CAT-031', 'Laptops', 9, 3),
(32, 'CAT-032', 'Desktop PCs', 9, 3),
(33, 'CAT-033', 'Tablets', 9, 3),
(34, 'CAT-034', 'Smartphones', 10, 3),
(35, 'CAT-035', 'Smartwatches', 10, 3),
(36, 'CAT-036', 'Bluetooth Speakers', 11, 3),
(37, 'CAT-037', 'Headphones', 11, 3),
(38, 'CAT-038', 'USB Cables', 12, 3),
(39, 'CAT-039', 'HDMI Cables', 12, 3),
(40, 'CAT-040', 'Raw Cotton Bales', 13, 3),
(41, 'CAT-041', 'Cotton Fabric Rolls', 13, 3),
(42, 'CAT-042', 'Polyester Rolls', 14, 3),
(43, 'CAT-043', 'Nylon Rolls', 14, 3),
(44, 'CAT-044', 'Denim Jeans', 15, 3),
(45, 'CAT-045', 'Denim Jackets', 15, 3),
(46, 'CAT-046', 'Electric Motors 5HP', 16, 3),
(47, 'CAT-047', 'Electric Motors 10HP', 16, 3),
(48, 'CAT-048', 'Spindle Parts', 17, 3),
(49, 'CAT-049', 'Control Boards', 17, 3),
(50, 'CAT-050', 'Hydraulic Pumps', 18, 3),
(51, 'CAT-051', 'Hydraulic Valves', 18, 3),
(52, 'CAT-052', 'Soybean Oil', 19, 3),
(53, 'CAT-053', 'Palm Oil', 19, 3),
(54, 'CAT-054', 'Rice', 20, 3),
(55, 'CAT-055', 'Wheat', 20, 3),
(56, 'CAT-056', 'Coffee Beans', 21, 3),
(57, 'CAT-057', 'Cocoa Beans', 21, 3),
(58, 'CAT-058', 'Steel Coils', 22, 3),
(59, 'CAT-059', 'Aluminum Ingots', 22, 3),
(60, 'CAT-060', 'Copper Wire', 22, 3),
(61, 'CAT-061', 'Natural Rubber Sheets', 23, 3),
(62, 'CAT-062', 'PVC Pellets', 23, 3),
(63, 'CAT-063', 'Pistons', 24, 3),
(64, 'CAT-064', 'Spark Plugs', 24, 3),
(65, 'CAT-065', 'Alternators', 25, 3),
(66, 'CAT-066', 'Wiring Harnesses', 25, 3),
(67, 'CAT-067', 'Bumpers', 26, 3),
(68, 'CAT-068', 'Side Mirrors', 26, 3),
(69, 'CAT-069', 'Office Chairs', 27, 3),
(70, 'CAT-070', 'Office Desks', 27, 3),
(71, 'CAT-071', 'Sofas', 28, 3),
(72, 'CAT-072', 'Dining Tables', 28, 3),
(73, 'CAT-073', 'Solvents', 29, 3),
(74, 'CAT-074', 'Adhesives', 29, 3),
(75, 'CAT-075', 'Fertilizers', 30, 3),
(76, 'CAT-076', 'Pesticides', 30, 3),
(77, 'CAT-077', 'Computers Export Grade Line', 9, 3),
(78, 'CAT-078', 'Mobile Devices Industrial Grade Line', 10, 3),
(79, 'CAT-079', 'Audio Equipment Economy Line', 11, 3),
(80, 'CAT-080', 'Cables & Connectors Standard Line', 12, 3);
-- ============================================================
-- 3. CONSULTAS CON SELF JOIN
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 1 — SELF JOIN básico (INNER JOIN)
-- Muestra cada categoría hija junto con el nombre de su categoría
-- padre. Usa dos aliases distintos de la MISMA tabla: "h" (hijo)
-- y "p" (padre). Al ser INNER JOIN, excluye automáticamente las
-- categorías raíz (las que tienen parent_category_id = NULL,
-- porque no encuentran coincidencia en el lado "p").
-- ------------------------------------------------------------
SELECT
    h.name           AS categoria_hija,
    p.name           AS categoria_padre,
    h.category_level AS nivel
FROM product_categories AS h
INNER JOIN product_categories AS p
    ON h.parent_category_id = p.category_id
ORDER BY p.name, h.name;

-- ------------------------------------------------------------
-- CONSULTA 2 — Incluir la raíz (LEFT JOIN + COALESCE)
-- Igual que la consulta 1, pero con LEFT JOIN para conservar
-- también las categorías raíz (sin padre). COALESCE reemplaza
-- el NULL del padre por una etiqueta legible.
-- ------------------------------------------------------------
SELECT
    h.name                                      AS categoria,
    COALESCE(p.name, 'Categoría raíz (sin padre)') AS categoria_padre,
    h.category_level                            AS nivel
FROM product_categories AS h
LEFT JOIN product_categories AS p
    ON h.parent_category_id = p.category_id
ORDER BY h.category_level, categoria;

-- ------------------------------------------------------------
-- CONSULTA 3 — Contar hijos por padre
-- Para cada categoría padre, cuenta cuántas subcategorías hijas
-- tiene directamente. HAVING filtra para quedarnos solo con los
-- padres que SÍ tienen al menos un hijo (excluye hojas sin hijos).
-- ------------------------------------------------------------
SELECT
    p.name              AS categoria_padre,
    p.category_level    AS nivel_padre,
    COUNT(h.category_id) AS total_hijos
FROM product_categories AS p
LEFT JOIN product_categories AS h
    ON h.parent_category_id = p.category_id
GROUP BY p.category_id, p.name, p.category_level
HAVING COUNT(h.category_id) >= 1
ORDER BY total_hijos DESC;

-- ------------------------------------------------------------
-- CONSULTA 4 — Dos niveles jerárquicos (nieto -> padre -> abuelo)
-- Encadena TRES aliases de la misma tabla para reconstruir la
-- cadena completa: hoja (h) -> subcategoría/padre (p) -> raíz/abuelo (a).
-- Se usa LEFT JOIN en cada nivel para no perder registros que no
-- tengan padre o abuelo (por ejemplo, las categorías de nivel 1 o 2).
-- ------------------------------------------------------------
SELECT
    h.name                                  AS categoria_hoja,
    COALESCE(p.name, '— sin padre —')       AS categoria_padre,
    COALESCE(a.name, '— sin abuelo —')      AS categoria_abuelo
FROM product_categories AS h
LEFT JOIN product_categories AS p
    ON h.parent_category_id = p.category_id
LEFT JOIN product_categories AS a
    ON p.parent_category_id = a.category_id
ORDER BY categoria_abuelo, categoria_padre, categoria_hoja;