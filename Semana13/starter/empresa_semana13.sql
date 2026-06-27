--  PROYECTO — SEMANA 13: Jerarquías con CTEs Recursivas
--  Motor: PostgreSQL
--  Dominio: Empresa de Importación (bc-sql)
--  Entidad jerárquica: product_categories (categorías de productos)
--  Columna auto-referencial: parent_category_id
--  Jerarquía: Categoría raíz -> Subcategoría -> Sub-subcategoría (hoja)
--  Ejemplo: Electronics -> Computers -> Computers Premium

-- ------------------------------------------------------------
-- 0. LIMPIAR TABLA SI EXISTE (para poder re-ejecutar el script)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS product_categories;

-- ============================================================
-- 1. ESQUEMA (DDL)
-- ============================================================

-- product_categories: tabla con AUTO-REFERENCIA (parent_category_id
-- apunta a category_id de la misma tabla). Las categorías raíz tienen
-- parent_category_id = NULL.
CREATE TABLE product_categories (
    category_id          INTEGER PRIMARY KEY,
    category_code        TEXT    NOT NULL UNIQUE,
    name                 TEXT    NOT NULL,
    parent_category_id   INTEGER
                                 REFERENCES product_categories(category_id)
                                 ON DELETE RESTRICT
                                 ON UPDATE CASCADE
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    200 filas en 3 niveles jerárquicos:
--      Nivel 1 (raíz, parent_category_id = NULL): 10 filas
--      Nivel 2 (subcategoría):                     50 filas
--      Nivel 3 (hoja):                             140 filas
-- ============================================================

INSERT INTO product_categories (category_id, category_code, name, parent_category_id) VALUES
(1, 'CAT-0001', 'Electronics', NULL),
(2, 'CAT-0002', 'Textiles', NULL),
(3, 'CAT-0003', 'Machinery', NULL),
(4, 'CAT-0004', 'Agriculture', NULL),
(5, 'CAT-0005', 'Raw Material', NULL),
(6, 'CAT-0006', 'Automotive Parts', NULL),
(7, 'CAT-0007', 'Furniture', NULL),
(8, 'CAT-0008', 'Chemicals', NULL),
(9, 'CAT-0009', 'Toys & Games', NULL),
(10, 'CAT-0010', 'Sporting Goods', NULL),
(11, 'CAT-0011', 'Computers', 1),
(12, 'CAT-0012', 'Mobile Devices', 1),
(13, 'CAT-0013', 'Audio Equipment', 1),
(14, 'CAT-0014', 'Cables & Connectors', 1),
(15, 'CAT-0015', 'Home Appliances', 1),
(16, 'CAT-0016', 'Cotton Products', 2),
(17, 'CAT-0017', 'Synthetic Fabrics', 2),
(18, 'CAT-0018', 'Denim Goods', 2),
(19, 'CAT-0019', 'Wool Products', 2),
(20, 'CAT-0020', 'Silk Products', 2),
(21, 'CAT-0021', 'Industrial Motors', 3),
(22, 'CAT-0022', 'CNC Components', 3),
(23, 'CAT-0023', 'Hydraulic Systems', 3),
(24, 'CAT-0024', 'Pneumatic Tools', 3),
(25, 'CAT-0025', 'Conveyor Systems', 3),
(26, 'CAT-0026', 'Oils & Fats', 4),
(27, 'CAT-0027', 'Grains', 4),
(28, 'CAT-0028', 'Coffee & Cocoa', 4),
(29, 'CAT-0029', 'Spices', 4),
(30, 'CAT-0030', 'Seeds', 4),
(31, 'CAT-0031', 'Metals', 5),
(32, 'CAT-0032', 'Rubber & Polymers', 5),
(33, 'CAT-0033', 'Glass Materials', 5),
(34, 'CAT-0034', 'Wood Materials', 5),
(35, 'CAT-0035', 'Ceramics', 5),
(36, 'CAT-0036', 'Engine Components', 6),
(37, 'CAT-0037', 'Electrical Systems', 6),
(38, 'CAT-0038', 'Body Parts', 6),
(39, 'CAT-0039', 'Brake Systems', 6),
(40, 'CAT-0040', 'Suspension Parts', 6),
(41, 'CAT-0041', 'Office Furniture', 7),
(42, 'CAT-0042', 'Home Furniture', 7),
(43, 'CAT-0043', 'Outdoor Furniture', 7),
(44, 'CAT-0044', 'Storage Furniture', 7),
(45, 'CAT-0045', 'Kids Furniture', 7),
(46, 'CAT-0046', 'Industrial Chemicals', 8),
(47, 'CAT-0047', 'Agrochemicals', 8),
(48, 'CAT-0048', 'Cleaning Chemicals', 8),
(49, 'CAT-0049', 'Paints & Coatings', 8),
(50, 'CAT-0050', 'Adhesives & Sealants', 8),
(51, 'CAT-0051', 'Educational Toys', 9),
(52, 'CAT-0052', 'Outdoor Toys', 9),
(53, 'CAT-0053', 'Board Games', 9),
(54, 'CAT-0054', 'Electronic Toys', 9),
(55, 'CAT-0055', 'Plush Toys', 9),
(56, 'CAT-0056', 'Fitness Equipment', 10),
(57, 'CAT-0057', 'Team Sports Gear', 10),
(58, 'CAT-0058', 'Outdoor Sports', 10),
(59, 'CAT-0059', 'Cycling Gear', 10),
(60, 'CAT-0060', 'Water Sports Gear', 10),
(61, 'CAT-0061', 'Computers Standard', 11),
(62, 'CAT-0062', 'Computers Premium', 11),
(63, 'CAT-0063', 'Computers Economy', 11),
(64, 'CAT-0064', 'Mobile Devices Industrial Grade', 12),
(65, 'CAT-0065', 'Mobile Devices Export Grade', 12),
(66, 'CAT-0066', 'Mobile Devices Bulk Pack', 12),
(67, 'CAT-0067', 'Audio Equipment Compact', 13),
(68, 'CAT-0068', 'Audio Equipment Heavy Duty', 13),
(69, 'CAT-0069', 'Audio Equipment Eco-Friendly', 13),
(70, 'CAT-0070', 'Cables & Connectors Wholesale Lot', 14),
(71, 'CAT-0071', 'Cables & Connectors Custom Order', 14),
(72, 'CAT-0072', 'Cables & Connectors OEM', 14),
(73, 'CAT-0073', 'Home Appliances Standard', 15),
(74, 'CAT-0074', 'Home Appliances Premium', 15),
(75, 'CAT-0075', 'Home Appliances Economy', 15),
(76, 'CAT-0076', 'Cotton Products Industrial Grade', 16),
(77, 'CAT-0077', 'Cotton Products Export Grade', 16),
(78, 'CAT-0078', 'Cotton Products Bulk Pack', 16),
(79, 'CAT-0079', 'Synthetic Fabrics Compact', 17),
(80, 'CAT-0080', 'Synthetic Fabrics Heavy Duty', 17),
(81, 'CAT-0081', 'Synthetic Fabrics Eco-Friendly', 17),
(82, 'CAT-0082', 'Denim Goods Wholesale Lot', 18),
(83, 'CAT-0083', 'Denim Goods Custom Order', 18),
(84, 'CAT-0084', 'Denim Goods OEM', 18),
(85, 'CAT-0085', 'Wool Products Standard', 19),
(86, 'CAT-0086', 'Wool Products Premium', 19),
(87, 'CAT-0087', 'Wool Products Economy', 19),
(88, 'CAT-0088', 'Silk Products Industrial Grade', 20),
(89, 'CAT-0089', 'Silk Products Export Grade', 20),
(90, 'CAT-0090', 'Silk Products Bulk Pack', 20),
(91, 'CAT-0091', 'Industrial Motors Compact', 21),
(92, 'CAT-0092', 'Industrial Motors Heavy Duty', 21),
(93, 'CAT-0093', 'Industrial Motors Eco-Friendly', 21),
(94, 'CAT-0094', 'CNC Components Wholesale Lot', 22),
(95, 'CAT-0095', 'CNC Components Custom Order', 22),
(96, 'CAT-0096', 'CNC Components OEM', 22),
(97, 'CAT-0097', 'Hydraulic Systems Standard', 23),
(98, 'CAT-0098', 'Hydraulic Systems Premium', 23),
(99, 'CAT-0099', 'Hydraulic Systems Economy', 23),
(100, 'CAT-0100', 'Pneumatic Tools Industrial Grade', 24),
(101, 'CAT-0101', 'Pneumatic Tools Export Grade', 24),
(102, 'CAT-0102', 'Pneumatic Tools Bulk Pack', 24),
(103, 'CAT-0103', 'Conveyor Systems Compact', 25),
(104, 'CAT-0104', 'Conveyor Systems Heavy Duty', 25),
(105, 'CAT-0105', 'Conveyor Systems Eco-Friendly', 25),
(106, 'CAT-0106', 'Oils & Fats Wholesale Lot', 26),
(107, 'CAT-0107', 'Oils & Fats Custom Order', 26),
(108, 'CAT-0108', 'Oils & Fats OEM', 26),
(109, 'CAT-0109', 'Grains Standard', 27),
(110, 'CAT-0110', 'Grains Premium', 27),
(111, 'CAT-0111', 'Grains Economy', 27),
(112, 'CAT-0112', 'Coffee & Cocoa Industrial Grade', 28),
(113, 'CAT-0113', 'Coffee & Cocoa Export Grade', 28),
(114, 'CAT-0114', 'Coffee & Cocoa Bulk Pack', 28),
(115, 'CAT-0115', 'Spices Compact', 29),
(116, 'CAT-0116', 'Spices Heavy Duty', 29),
(117, 'CAT-0117', 'Spices Eco-Friendly', 29),
(118, 'CAT-0118', 'Seeds Wholesale Lot', 30),
(119, 'CAT-0119', 'Seeds Custom Order', 30),
(120, 'CAT-0120', 'Seeds OEM', 30),
(121, 'CAT-0121', 'Metals Standard', 31),
(122, 'CAT-0122', 'Metals Premium', 31),
(123, 'CAT-0123', 'Metals Economy', 31),
(124, 'CAT-0124', 'Rubber & Polymers Industrial Grade', 32),
(125, 'CAT-0125', 'Rubber & Polymers Export Grade', 32),
(126, 'CAT-0126', 'Rubber & Polymers Bulk Pack', 32),
(127, 'CAT-0127', 'Glass Materials Compact', 33),
(128, 'CAT-0128', 'Glass Materials Heavy Duty', 33),
(129, 'CAT-0129', 'Glass Materials Eco-Friendly', 33),
(130, 'CAT-0130', 'Wood Materials Wholesale Lot', 34),
(131, 'CAT-0131', 'Wood Materials Custom Order', 34),
(132, 'CAT-0132', 'Wood Materials OEM', 34),
(133, 'CAT-0133', 'Ceramics Standard', 35),
(134, 'CAT-0134', 'Ceramics Premium', 35),
(135, 'CAT-0135', 'Ceramics Economy', 35),
(136, 'CAT-0136', 'Engine Components Industrial Grade', 36),
(137, 'CAT-0137', 'Engine Components Export Grade', 36),
(138, 'CAT-0138', 'Engine Components Bulk Pack', 36),
(139, 'CAT-0139', 'Electrical Systems Compact', 37),
(140, 'CAT-0140', 'Electrical Systems Heavy Duty', 37),
(141, 'CAT-0141', 'Electrical Systems Eco-Friendly', 37),
(142, 'CAT-0142', 'Body Parts Wholesale Lot', 38),
(143, 'CAT-0143', 'Body Parts Custom Order', 38),
(144, 'CAT-0144', 'Body Parts OEM', 38),
(145, 'CAT-0145', 'Brake Systems Standard', 39),
(146, 'CAT-0146', 'Brake Systems Premium', 39),
(147, 'CAT-0147', 'Brake Systems Economy', 39),
(148, 'CAT-0148', 'Suspension Parts Industrial Grade', 40),
(149, 'CAT-0149', 'Suspension Parts Export Grade', 40),
(150, 'CAT-0150', 'Suspension Parts Bulk Pack', 40),
(151, 'CAT-0151', 'Office Furniture Compact', 41),
(152, 'CAT-0152', 'Office Furniture Heavy Duty', 41),
(153, 'CAT-0153', 'Office Furniture Eco-Friendly', 41),
(154, 'CAT-0154', 'Home Furniture Wholesale Lot', 42),
(155, 'CAT-0155', 'Home Furniture Custom Order', 42),
(156, 'CAT-0156', 'Home Furniture OEM', 42),
(157, 'CAT-0157', 'Outdoor Furniture Standard', 43),
(158, 'CAT-0158', 'Outdoor Furniture Premium', 43),
(159, 'CAT-0159', 'Outdoor Furniture Economy', 43),
(160, 'CAT-0160', 'Storage Furniture Industrial Grade', 44),
(161, 'CAT-0161', 'Storage Furniture Export Grade', 44),
(162, 'CAT-0162', 'Storage Furniture Bulk Pack', 44),
(163, 'CAT-0163', 'Kids Furniture Compact', 45),
(164, 'CAT-0164', 'Kids Furniture Heavy Duty', 45),
(165, 'CAT-0165', 'Kids Furniture Eco-Friendly', 45),
(166, 'CAT-0166', 'Industrial Chemicals Wholesale Lot', 46),
(167, 'CAT-0167', 'Industrial Chemicals Custom Order', 46),
(168, 'CAT-0168', 'Industrial Chemicals OEM', 46),
(169, 'CAT-0169', 'Agrochemicals Standard', 47),
(170, 'CAT-0170', 'Agrochemicals Premium', 47),
(171, 'CAT-0171', 'Agrochemicals Economy', 47),
(172, 'CAT-0172', 'Cleaning Chemicals Industrial Grade', 48),
(173, 'CAT-0173', 'Cleaning Chemicals Export Grade', 48),
(174, 'CAT-0174', 'Cleaning Chemicals Bulk Pack', 48),
(175, 'CAT-0175', 'Paints & Coatings Compact', 49),
(176, 'CAT-0176', 'Paints & Coatings Heavy Duty', 49),
(177, 'CAT-0177', 'Paints & Coatings Eco-Friendly', 49),
(178, 'CAT-0178', 'Adhesives & Sealants Wholesale Lot', 50),
(179, 'CAT-0179', 'Adhesives & Sealants Custom Order', 50),
(180, 'CAT-0180', 'Adhesives & Sealants OEM', 50),
(181, 'CAT-0181', 'Educational Toys Standard', 51),
(182, 'CAT-0182', 'Educational Toys Premium', 51),
(183, 'CAT-0183', 'Outdoor Toys Economy', 52),
(184, 'CAT-0184', 'Outdoor Toys Industrial Grade', 52),
(185, 'CAT-0185', 'Board Games Export Grade', 53),
(186, 'CAT-0186', 'Board Games Bulk Pack', 53),
(187, 'CAT-0187', 'Electronic Toys Compact', 54),
(188, 'CAT-0188', 'Electronic Toys Heavy Duty', 54),
(189, 'CAT-0189', 'Plush Toys Eco-Friendly', 55),
(190, 'CAT-0190', 'Plush Toys Wholesale Lot', 55),
(191, 'CAT-0191', 'Fitness Equipment Custom Order', 56),
(192, 'CAT-0192', 'Fitness Equipment OEM', 56),
(193, 'CAT-0193', 'Team Sports Gear Standard', 57),
(194, 'CAT-0194', 'Team Sports Gear Premium', 57),
(195, 'CAT-0195', 'Outdoor Sports Economy', 58),
(196, 'CAT-0196', 'Outdoor Sports Industrial Grade', 58),
(197, 'CAT-0197', 'Cycling Gear Export Grade', 59),
(198, 'CAT-0198', 'Cycling Gear Bulk Pack', 59),
(199, 'CAT-0199', 'Water Sports Gear Compact', 60),
(200, 'CAT-0200', 'Water Sports Gear Heavy Duty', 60);
-- ============================================================
-- 3. CONSULTAS CON WITH RECURSIVE
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 1 — Árbol completo con depth y path
-- CASO BASE: arranca desde las categorías raíz (parent_category_id
-- IS NULL), con depth = 0 y path = su propio nombre.
-- CASO RECURSIVO: por cada categoría hija (c) que referencia a un
-- nodo ya incluido en el árbol (a), se suma 1 al depth del padre
-- y se concatena el nombre de la hija al path acumulado. La
-- recursión termina sola cuando ya no hay más hijos que unir.
-- ------------------------------------------------------------
WITH RECURSIVE arbol_categorias AS (
    -- Caso base: categorías raíz
    SELECT
        category_id,
        name,
        parent_category_id,
        0                       AS depth,
        name::text              AS path
    FROM product_categories
    WHERE parent_category_id IS NULL

    UNION ALL

    -- Caso recursivo: hijos de los nodos ya visitados
    SELECT
        c.category_id,
        c.name,
        c.parent_category_id,
        a.depth + 1             AS depth,
        a.path || ' > ' || c.name AS path
    FROM product_categories AS c
    INNER JOIN arbol_categorias AS a
        ON c.parent_category_id = a.category_id
)
SELECT
    category_id,
    name,
    depth,
    path
FROM arbol_categorias
ORDER BY path;

-- ------------------------------------------------------------
-- CONSULTA 2 — Nodos de un nivel específico (depth = 2)
-- Reutiliza la misma CTE recursiva y filtra en la consulta
-- exterior solo los nodos cuyo nivel de profundidad sea 2
-- (las hojas del árbol, el tercer nivel jerárquico).
-- ------------------------------------------------------------
WITH RECURSIVE arbol_categorias AS (
    SELECT
        category_id,
        name,
        parent_category_id,
        0                       AS depth,
        name::text              AS path
    FROM product_categories
    WHERE parent_category_id IS NULL

    UNION ALL

    SELECT
        c.category_id,
        c.name,
        c.parent_category_id,
        a.depth + 1             AS depth,
        a.path || ' > ' || c.name AS path
    FROM product_categories AS c
    INNER JOIN arbol_categorias AS a
        ON c.parent_category_id = a.category_id
)
SELECT
    category_id,
    name,
    path
FROM arbol_categorias
WHERE depth = 2
ORDER BY path;

-- ------------------------------------------------------------
-- CONSULTA 3 — Hojas del árbol (nodos sin hijos)
-- Un nodo "h" es hoja si NO existe ningún otro nodo "c" en la
-- misma tabla cuyo parent_category_id apunte al id de "h".
-- Se usa NOT EXISTS correlacionado, sin necesidad de recursión,
-- porque solo se compara cada fila contra la tabla original.
-- ------------------------------------------------------------
SELECT
    h.category_id   AS id_categoria,
    h.name          AS categoria,
    h.parent_category_id AS id_padre
FROM product_categories AS h
WHERE NOT EXISTS (
    SELECT 1
    FROM product_categories AS c
    WHERE c.parent_category_id = h.category_id
)
ORDER BY h.name;