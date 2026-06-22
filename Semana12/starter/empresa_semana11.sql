-- ============================================================
--  PROYECTO — SEMANA 12: CTEs y CASE WHEN en tu dominio
--  Dominio: Empresa de Importación (bc-sql)
--  Tabla principal:   shipments  (envíos)
--  Tabla secundaria:  customs    (trámites de aduana, 1:1 con shipments)
--  Tablas de referencia: suppliers (proveedores), products (productos)
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

CREATE TABLE suppliers (
    supplier_id     INTEGER PRIMARY KEY,
    tax_code        TEXT    NOT NULL UNIQUE,
    name            TEXT    NOT NULL,
    country         TEXT    NOT NULL,
    contact_email   TEXT,
    rating          REAL    NOT NULL DEFAULT 3.0
                            CHECK (rating >= 1.0 AND rating <= 5.0),
    active          INTEGER NOT NULL DEFAULT 1
                            CHECK (active IN (0, 1))
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    sku             TEXT    NOT NULL UNIQUE,
    name            TEXT    NOT NULL,
    category        TEXT    NOT NULL
                            CHECK (category IN (
                                'Electronics','Textiles','Machinery',
                                'Agriculture','Raw Material'
                            )),
    unit_price      REAL    NOT NULL
                            CHECK (unit_price > 0),
    description     TEXT
);

-- TABLA PRINCIPAL: 80 filas, relación N:1 con suppliers y products
CREATE TABLE shipments (
    shipment_id     INTEGER PRIMARY KEY,
    tracking_code   TEXT    NOT NULL UNIQUE,
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
    ship_date       TEXT    NOT NULL,
    arrival_date    TEXT,
    status          TEXT    NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('delivered','in_transit','pending','cancelled'))
);

-- TABLA SECUNDARIA (hija de shipments): NO todos los envíos tienen trámite
-- de aduana todavía -> usamos esto para detectar "huérfanos" con LEFT JOIN
CREATE TABLE customs (
    customs_id      INTEGER PRIMARY KEY,
    shipment_id     INTEGER NOT NULL UNIQUE
                            REFERENCES shipments(shipment_id)
                            ON DELETE CASCADE,
    duty_amount     REAL    NOT NULL
                            CHECK (duty_amount >= 0),
    cleared         INTEGER NOT NULL DEFAULT 0
                            CHECK (cleared IN (0, 1)),
    cleared_date    TEXT,
    inspector_notes TEXT
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    suppliers: 20 filas (5 SIN envíos -> huérfanos del lado padre)
--    products:  20 filas (5 SIN envíos -> huérfanos del lado padre)
--    shipments: 80 filas (tabla principal)
--    customs:   65 filas (15 envíos SIN trámite -> huérfanos para LEFT JOIN)
-- ============================================================

INSERT INTO suppliers VALUES
(1, 'CN-770487', 'Shenzhen Tech Imports', 'China', 'contact1@shenzhen.com', 3.2, 1),
(2, 'KR-877572', 'Seoul Electronics Co', 'Korea', 'contact2@seoul.com', 3.6, 1),
(3, 'IN-334053', 'Mumbai Textiles Ltd', 'India', 'contact3@mumbai.com', 3.3, 1),
(4, 'DE-207473', 'Berlin Machinery GmbH', 'Germany', NULL, 4.4, 1),
(5, 'BR-671858', 'Sao Paulo Agro SA', 'Brazil', 'contact5@sao.com', 3.2, 1),
(6, 'ID-542417', 'Jakarta Rubber Corp', 'Indonesia', 'contact6@jakarta.com', 3.1, 0),
(7, 'VN-198246', 'Hanoi Garments JSC', 'Vietnam', 'contact7@hanoi.com', 3.4, 1),
(8, 'MX-629903', 'Monterrey Auto Parts SA', 'Mexico', NULL, 4.2, 1),
(9, 'TR-688508', 'Istanbul Textile Group', 'Turkey', 'contact9@istanbul.com', 3.4, 1),
(10, 'TH-781453', 'Bangkok Rubber Exports', 'Thailand', 'contact10@bangkok.com', 4.4, 1),
(11, 'JP-539898', 'Osaka Components KK', 'Japan', 'contact11@osaka.com', 3.4, 1),
(12, 'ES-717889', 'Madrid Olive Oil SL', 'Spain', NULL, 3.6, 1),
(13, 'IT-106814', 'Milano Leather Works', 'Italy', 'contact13@milano.com', 4.5, 1),
(14, 'US-267414', 'Detroit Steel Supply', 'USA', 'contact14@detroit.com', 4.4, 1),
(15, 'CA-456778', 'Toronto Cold Chain Inc', 'Canada', 'contact15@toronto.com', 3.6, 0),
(16, 'CL-325772', 'Santiago Copper Traders', 'Chile', NULL, 4.9, 1),
(17, 'PE-452944', 'Lima Andes Textiles', 'Peru', 'contact17@lima.com', 3.2, 1),
(18, 'EG-498382', 'Cairo Cotton Co', 'Egypt', 'contact18@cairo.com', 3.2, 1),
(19, 'PL-988662', 'Warsaw Furniture Exports', 'Poland', 'contact19@warsaw.com', 3.7, 1),
(20, 'NL-377370', 'Rotterdam Logistics BV', 'Netherlands', NULL, 4.6, 1);

INSERT INTO products VALUES
(1, 'ELEC-001', 'Laptop 15"', 'Electronics', 1095.14, 'Descripcion de Laptop 15"'),
(2, 'ELEC-002', 'Smartphone X12', 'Electronics', 805.27, 'Descripcion de Smartphone X12'),
(3, 'ELEC-003', 'USB-C Cable 2m', 'Electronics', 1459.73, NULL),
(4, 'ELEC-004', 'Wireless Router', 'Electronics', 569.04, 'Descripcion de Wireless Router'),
(5, 'TEXT-005', 'Cotton Fabric 100m', 'Textiles', 828.96, 'Descripcion de Cotton Fabric 100m'),
(6, 'TEXT-006', 'Denim Jeans Bulk', 'Textiles', 1244.45, NULL),
(7, 'TEXT-007', 'Silk Scarf Pack', 'Textiles', 928.54, 'Descripcion de Silk Scarf Pack'),
(8, 'TEXT-008', 'Wool Sweater Lot', 'Textiles', 1292.84, 'Descripcion de Wool Sweater Lot'),
(9, 'MACH-009', 'Industrial Motor 5HP', 'Machinery', 866.87, NULL),
(10, 'MACH-010', 'CNC Spindle Part', 'Machinery', 1057.45, 'Descripcion de CNC Spindle Part'),
(11, 'MACH-011', 'Hydraulic Pump', 'Machinery', 70.64, 'Descripcion de Hydraulic Pump'),
(12, 'MACH-012', 'Conveyor Belt 10m', 'Machinery', 343.39, NULL),
(13, 'AGRI-013', 'Soybean Oil 1L', 'Agriculture', 435.5, 'Descripcion de Soybean Oil 1L'),
(14, 'AGRI-014', 'Coffee Beans 1kg', 'Agriculture', 121.53, 'Descripcion de Coffee Beans 1kg'),
(15, 'AGRI-015', 'Rice Sack 25kg', 'Agriculture', 350.72, NULL),
(16, 'AGRI-016', 'Cocoa Beans 1kg', 'Agriculture', 153.3, 'Descripcion de Cocoa Beans 1kg'),
(17, 'RAWM-017', 'Natural Rubber Sheet', 'Raw Material', 418.4, 'Descripcion de Natural Rubber Sheet'),
(18, 'RAWM-018', 'Steel Coil', 'Raw Material', 954.26, NULL),
(19, 'RAWM-019', 'Aluminum Ingot', 'Raw Material', 548.52, 'Descripcion de Aluminum Ingot'),
(20, 'RAWM-020', 'Copper Wire Roll', 'Raw Material', 556.53, 'Descripcion de Copper Wire Roll');

INSERT INTO shipments VALUES
(101, 'TRK-2024-101', 4, 11, 2207, 155902.48, '2024-06-28', NULL, 'pending'),
(102, 'TRK-2024-102', 11, 2, 5010, 4034402.7, '2024-06-11', '2024-06-28', 'delivered'),
(103, 'TRK-2024-103', 3, 8, 3128, 4044003.52, '2024-03-10', NULL, 'cancelled'),
(104, 'TRK-2024-104', 11, 12, 4582, 1573412.98, '2024-02-26', NULL, 'in_transit'),
(105, 'TRK-2024-105', 14, 13, 6376, 2776748.0, '2024-01-15', '2024-01-26', 'delivered'),
(106, 'TRK-2024-106', 13, 6, 3306, 4114151.7, '2024-03-09', '2024-03-29', 'delivered'),
(107, 'TRK-2024-107', 4, 11, 4109, 290259.76, '2024-04-11', NULL, 'pending'),
(108, 'TRK-2024-108', 11, 8, 1190, 1538479.6, '2024-03-08', '2024-03-26', 'delivered'),
(109, 'TRK-2024-109', 12, 10, 3529, 3731741.05, '2024-05-29', '2024-06-15', 'delivered'),
(110, 'TRK-2024-110', 3, 9, 4062, 3521225.94, '2024-01-24', NULL, 'pending'),
(111, 'TRK-2024-111', 14, 2, 1272, 1024303.44, '2024-06-09', '2024-07-02', 'delivered'),
(112, 'TRK-2024-112', 10, 2, 3172, 2554316.44, '2024-04-07', NULL, 'in_transit'),
(113, 'TRK-2024-113', 8, 9, 2079, 1802222.73, '2024-05-21', NULL, 'pending'),
(114, 'TRK-2024-114', 1, 11, 5924, 418471.36, '2024-01-30', NULL, 'in_transit'),
(115, 'TRK-2024-115', 9, 13, 2205, 960277.5, '2024-06-13', '2024-07-02', 'delivered'),
(116, 'TRK-2024-116', 7, 3, 3736, 5453551.28, '2024-01-01', NULL, 'cancelled'),
(117, 'TRK-2024-117', 15, 12, 2177, 747560.03, '2024-05-08', NULL, 'pending'),
(118, 'TRK-2024-118', 9, 15, 891, 312491.52, '2024-06-09', '2024-06-25', 'delivered'),
(119, 'TRK-2024-119', 3, 6, 6266, 7797723.7, '2024-02-11', '2024-02-21', 'delivered'),
(120, 'TRK-2024-120', 10, 6, 4022, 5005177.9, '2024-01-05', '2024-01-26', 'delivered'),
(121, 'TRK-2024-121', 15, 14, 6629, 805622.37, '2024-03-19', '2024-04-05', 'delivered'),
(122, 'TRK-2024-122', 15, 10, 7777, 8223788.65, '2024-01-21', '2024-02-15', 'delivered'),
(123, 'TRK-2024-123', 14, 2, 6250, 5032937.5, '2024-05-16', NULL, 'pending'),
(124, 'TRK-2024-124', 3, 11, 3913, 276414.32, '2024-05-20', '2024-06-12', 'delivered'),
(125, 'TRK-2024-125', 4, 15, 4437, 1556144.64, '2024-06-25', '2024-07-14', 'delivered'),
(126, 'TRK-2024-126', 7, 11, 5343, 377429.52, '2024-04-05', '2024-04-29', 'delivered'),
(127, 'TRK-2024-127', 2, 4, 1860, 1058414.4, '2024-01-17', '2024-02-03', 'delivered'),
(128, 'TRK-2024-128', 10, 4, 78, 44385.12, '2024-01-19', NULL, 'in_transit'),
(129, 'TRK-2024-129', 1, 4, 572, 325490.88, '2024-01-09', NULL, 'pending'),
(130, 'TRK-2024-130', 2, 9, 1969, 1706867.03, '2024-03-12', NULL, 'in_transit'),
(131, 'TRK-2024-131', 4, 9, 1103, 956157.61, '2024-05-26', NULL, 'in_transit'),
(132, 'TRK-2024-132', 4, 13, 3894, 1695837.0, '2024-04-14', '2024-04-27', 'delivered'),
(133, 'TRK-2024-133', 11, 7, 2922, 2713193.88, '2024-04-18', '2024-04-29', 'delivered'),
(134, 'TRK-2024-134', 11, 11, 5313, 375310.32, '2024-01-26', '2024-02-15', 'delivered'),
(135, 'TRK-2024-135', 13, 14, 915, 111199.95, '2024-03-04', '2024-03-28', 'delivered'),
(136, 'TRK-2024-136', 3, 7, 1523, 1414166.42, '2024-03-12', '2024-03-24', 'delivered'),
(137, 'TRK-2024-137', 8, 13, 7076, 3081598.0, '2024-05-20', '2024-05-30', 'delivered'),
(138, 'TRK-2024-138', 2, 15, 6193, 2172008.96, '2024-03-01', '2024-03-26', 'delivered'),
(139, 'TRK-2024-139', 8, 4, 7103, 4041891.12, '2024-04-12', NULL, 'pending'),
(140, 'TRK-2024-140', 3, 7, 37, 34355.98, '2024-04-09', '2024-05-03', 'delivered'),
(141, 'TRK-2024-141', 5, 7, 5726, 5316820.04, '2024-05-22', NULL, 'in_transit'),
(142, 'TRK-2024-142', 8, 3, 1575, 2299074.75, '2024-03-16', '2024-03-27', 'delivered'),
(143, 'TRK-2024-143', 10, 12, 4461, 1531862.79, '2024-01-16', NULL, 'in_transit'),
(144, 'TRK-2024-144', 1, 1, 4805, 5262147.7, '2024-05-02', '2024-05-17', 'delivered'),
(145, 'TRK-2024-145', 1, 9, 676, 586004.12, '2024-02-17', '2024-02-29', 'delivered'),
(146, 'TRK-2024-146', 11, 14, 1946, 236497.38, '2024-04-13', '2024-04-30', 'delivered'),
(147, 'TRK-2024-147', 10, 10, 345, 364820.25, '2024-06-07', '2024-06-27', 'delivered'),
(148, 'TRK-2024-148', 15, 5, 1693, 1403429.28, '2024-06-20', NULL, 'in_transit'),
(149, 'TRK-2024-149', 4, 5, 3262, 2704067.52, '2024-02-03', NULL, 'in_transit'),
(150, 'TRK-2024-150', 5, 8, 2610, 3374312.4, '2024-01-19', '2024-02-01', 'delivered'),
(151, 'TRK-2024-151', 2, 9, 1766, 1530892.42, '2024-05-09', '2024-05-30', 'delivered'),
(152, 'TRK-2024-152', 15, 2, 7222, 5815659.94, '2024-03-03', '2024-03-18', 'delivered'),
(153, 'TRK-2024-153', 8, 14, 4470, 543239.1, '2024-06-29', '2024-07-09', 'delivered'),
(154, 'TRK-2024-154', 11, 14, 4563, 554541.39, '2024-03-17', NULL, 'pending'),
(155, 'TRK-2024-155', 2, 15, 1120, 392806.4, '2024-03-08', '2024-03-21', 'delivered'),
(156, 'TRK-2024-156', 12, 9, 1293, 1120862.91, '2024-03-10', '2024-03-26', 'delivered'),
(157, 'TRK-2024-157', 12, 6, 1687, 2099387.15, '2024-06-24', NULL, 'in_transit'),
(158, 'TRK-2024-158', 5, 9, 4022, 3486551.14, '2024-03-05', NULL, 'pending'),
(159, 'TRK-2024-159', 14, 1, 776, 849828.64, '2024-06-11', '2024-06-29', 'delivered'),
(160, 'TRK-2024-160', 1, 1, 2752, 3013825.28, '2024-02-03', NULL, 'in_transit'),
(161, 'TRK-2024-161', 5, 3, 6092, 8892675.16, '2024-04-23', NULL, 'in_transit'),
(162, 'TRK-2024-162', 7, 9, 99, 85820.13, '2024-01-29', '2024-02-12', 'delivered'),
(163, 'TRK-2024-163', 9, 1, 6857, 7509374.98, '2024-04-04', NULL, 'in_transit'),
(164, 'TRK-2024-164', 3, 7, 1064, 987966.56, '2024-01-11', '2024-01-22', 'delivered'),
(165, 'TRK-2024-165', 15, 6, 1740, 2165343.0, '2024-06-23', '2024-07-06', 'delivered'),
(166, 'TRK-2024-166', 6, 13, 4606, 2005913.0, '2024-04-14', NULL, 'cancelled'),
(167, 'TRK-2024-167', 12, 3, 7603, 11098327.19, '2024-03-01', NULL, 'pending'),
(168, 'TRK-2024-168', 13, 13, 1470, 640185.0, '2024-04-15', '2024-05-05', 'delivered'),
(169, 'TRK-2024-169', 13, 15, 3392, 1189642.24, '2024-06-20', NULL, 'pending'),
(170, 'TRK-2024-170', 13, 4, 2205, 1254733.2, '2024-02-10', NULL, 'pending'),
(171, 'TRK-2024-171', 2, 7, 7164, 6652060.56, '2024-01-10', NULL, 'pending'),
(172, 'TRK-2024-172', 4, 4, 6709, 3817689.36, '2024-04-27', '2024-05-14', 'delivered'),
(173, 'TRK-2024-173', 4, 1, 5426, 5942229.64, '2024-02-19', '2024-03-08', 'delivered'),
(174, 'TRK-2024-174', 14, 2, 7940, 6393843.8, '2024-03-12', '2024-04-03', 'delivered'),
(175, 'TRK-2024-175', 11, 14, 4412, 536190.36, '2024-03-25', NULL, 'pending'),
(176, 'TRK-2024-176', 2, 15, 7969, 2794887.68, '2024-03-07', '2024-03-25', 'delivered'),
(177, 'TRK-2024-177', 1, 2, 4907, 3951459.89, '2024-04-21', '2024-05-11', 'delivered'),
(178, 'TRK-2024-178', 7, 10, 4209, 4450807.05, '2024-01-30', '2024-02-15', 'delivered'),
(179, 'TRK-2024-179', 5, 1, 5826, 6380285.64, '2024-04-21', '2024-05-07', 'delivered'),
(180, 'TRK-2024-180', 6, 7, 593, 550624.22, '2024-06-19', NULL, 'pending');

INSERT INTO customs VALUES
(1001, 101, 13882.37, 0, NULL, NULL),
(1002, 102, 433454.82, 1, '2024-06-11', NULL),
(1003, 103, 443594.3, 1, '2024-03-10', NULL),
(1004, 105, 137992.44, 1, '2024-01-15', NULL),
(1005, 106, 421165.24, 1, '2024-03-09', NULL),
(1006, 107, 26887.36, 1, '2024-04-11', NULL),
(1007, 108, 53107.78, 1, '2024-03-08', NULL),
(1008, 110, 184610.29, 0, NULL, NULL),
(1009, 111, 104609.54, 1, '2024-06-09', NULL),
(1010, 113, 162347.82, 1, '2024-05-21', NULL),
(1011, 114, 48334.93, 1, '2024-01-30', NULL),
(1012, 115, 81756.79, 1, '2024-06-13', NULL),
(1013, 116, 516640.31, 1, '2024-01-01', NULL),
(1014, 117, 78307.83, 1, '2024-05-08', NULL),
(1015, 119, 863587.99, 1, '2024-02-11', NULL),
(1016, 120, 485146.84, 1, '2024-01-05', NULL),
(1017, 121, 58585.42, 1, '2024-03-19', NULL),
(1018, 122, 438551.95, 1, '2024-01-21', NULL),
(1019, 123, 262978.92, 1, '2024-05-16', NULL),
(1020, 125, 153938.86, 1, '2024-06-25', NULL),
(1021, 128, 3413.97, 0, NULL, 'Documentos incompletos'),
(1022, 129, 30667.44, 0, NULL, 'En revision fitosanitaria'),
(1023, 130, 188391.04, 0, NULL, 'Documentos incompletos'),
(1024, 131, 61646.52, 0, NULL, NULL),
(1025, 132, 60678.06, 1, '2024-04-14', NULL),
(1026, 133, 180926.47, 1, '2024-04-18', NULL),
(1027, 134, 29587.59, 1, '2024-01-26', NULL),
(1028, 135, 7497.07, 1, '2024-03-04', NULL),
(1029, 136, 68749.83, 1, '2024-03-12', NULL),
(1030, 137, 208972.15, 1, '2024-05-20', NULL),
(1031, 138, 242038.82, 1, '2024-03-01', NULL),
(1032, 139, 333727.42, 0, NULL, NULL),
(1033, 140, 3397.93, 1, '2024-04-09', NULL),
(1034, 141, 341522.17, 0, NULL, NULL),
(1035, 142, 130760.2, 1, '2024-03-16', NULL),
(1036, 143, 99722.43, 1, '2024-01-16', NULL),
(1037, 144, 412762.08, 1, '2024-05-02', NULL),
(1038, 146, 22731.43, 1, '2024-04-13', NULL),
(1039, 147, 37207.34, 1, '2024-06-07', NULL),
(1040, 149, 299618.85, 1, '2024-02-03', NULL),
(1041, 150, 167865.11, 1, '2024-01-19', NULL),
(1042, 151, 105976.39, 1, '2024-05-09', NULL),
(1043, 152, 189661.66, 1, '2024-03-03', NULL),
(1044, 153, 32731.06, 1, '2024-06-29', NULL),
(1045, 154, 50531.35, 1, '2024-03-17', NULL),
(1046, 156, 106679.61, 1, '2024-03-10', NULL),
(1047, 157, 221790.83, 0, NULL, NULL),
(1048, 158, 272198.98, 1, '2024-03-05', NULL),
(1049, 159, 70765.53, 1, '2024-06-11', NULL),
(1050, 160, 270249.65, 0, NULL, NULL),
(1051, 163, 316992.9, 1, '2024-04-04', NULL),
(1052, 164, 45797.79, 1, '2024-01-11', NULL),
(1053, 165, 115659.78, 1, '2024-06-23', NULL),
(1054, 167, 659925.85, 1, '2024-03-01', NULL),
(1055, 168, 38037.31, 1, '2024-04-15', NULL),
(1056, 169, 117192.46, 1, '2024-06-20', NULL),
(1057, 171, 366150.0, 1, '2024-01-10', NULL),
(1058, 172, 201209.17, 1, '2024-04-27', NULL),
(1059, 173, 222070.4, 1, '2024-02-19', NULL),
(1060, 174, 202969.35, 1, '2024-03-12', NULL),
(1061, 176, 219532.04, 1, '2024-03-07', NULL),
(1062, 177, 474142.41, 1, '2024-04-21', NULL),
(1063, 178, 273708.75, 1, '2024-01-30', NULL),
(1064, 179, 564738.02, 1, '2024-04-21', NULL),
(1065, 180, 55233.65, 0, NULL, NULL);


-- ============================================================
-- 3. CONSULTAS CON SUBQUERIES
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 1 — Subquery escalar en WHERE
-- La subquery (SELECT AVG(total_value) FROM shipments) calcula
-- UN SOLO VALOR: el valor promedio de todos los envíos. La consulta
-- exterior compara cada envío contra ese promedio para encontrar
-- los envíos "por encima del promedio" (de alto valor).
-- ------------------------------------------------------------
SELECT
    sh.tracking_code   AS codigo_seguimiento,
    sh.total_value      AS valor_envio,
    sh.status           AS estado
FROM shipments AS sh
WHERE sh.total_value > (
    SELECT AVG(total_value) FROM shipments
)
ORDER BY sh.total_value DESC;

-- ------------------------------------------------------------
-- CONSULTA 2 — Subquery escalar en SELECT
-- La subquery (SELECT AVG(total_value) FROM shipments) se repite
-- en cada fila del resultado, agregando una columna de referencia
-- global para que el usuario pueda comparar visualmente cada envío
-- contra el promedio general sin tener que calcularlo aparte.
-- ------------------------------------------------------------
SELECT
    sh.tracking_code                          AS codigo_seguimiento,
    sh.total_value                            AS valor_envio,
    (SELECT ROUND(AVG(total_value), 2) FROM shipments) AS promedio_general,
    ROUND(sh.total_value - (SELECT AVG(total_value) FROM shipments), 2) AS diferencia_vs_promedio
FROM shipments AS sh
ORDER BY diferencia_vs_promedio DESC
LIMIT 15;

-- ------------------------------------------------------------
-- CONSULTA 3 — NOT EXISTS
-- La subquery correlacionada busca, para cada proveedor (s),
-- si existe AL MENOS UN envío (sh) cuyo supplier_id coincida con
-- el proveedor actual. NOT EXISTS devuelve los proveedores para
-- los que esa búsqueda NO encuentra nada: proveedores que nunca
-- han enviado mercancía. Es la alternativa segura a NOT IN porque
-- no falla si la tabla relacionada tiene valores NULL.
-- ------------------------------------------------------------
SELECT
    s.supplier_id   AS id_proveedor,
    s.name          AS proveedor,
    s.country       AS pais,
    s.active        AS activo
FROM suppliers AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM shipments AS sh
    WHERE sh.supplier_id = s.supplier_id
);

-- ------------------------------------------------------------
-- CONSULTA 3b — NOT EXISTS sobre envíos sin trámite de aduana
-- Misma lógica de correlación, ahora detectando envíos (sh) para
-- los que NO existe ningún registro en customs (c) con su mismo
-- shipment_id: envíos que aún no han iniciado el trámite aduanero.
-- ------------------------------------------------------------
SELECT
    sh.shipment_id      AS id_envio,
    sh.tracking_code    AS codigo_seguimiento,
    sh.status           AS estado,
    sh.total_value      AS valor_envio
FROM shipments AS sh
WHERE NOT EXISTS (
    SELECT 1
    FROM customs AS c
    WHERE c.shipment_id = sh.shipment_id
)
ORDER BY sh.ship_date;

-- ------------------------------------------------------------
-- CONSULTA 4 — Tabla derivada en FROM
-- La subquery "resumen_proveedor" agrupa los envíos por proveedor
-- y calcula, por cada uno, el total de envíos y el valor acumulado
-- importado. La consulta exterior trata ese resultado como si
-- fuera una tabla más (con alias "rp") y filtra solo los proveedores
-- cuyo valor acumulado supera 1.000.000 USD.
-- ------------------------------------------------------------
SELECT
    rp.proveedor        AS proveedor,
    rp.total_envios      AS total_envios,
    rp.valor_acumulado   AS valor_acumulado
FROM (
    SELECT
        s.name                AS proveedor,
        COUNT(sh.shipment_id) AS total_envios,
        SUM(sh.total_value)   AS valor_acumulado
    FROM suppliers AS s
    JOIN shipments AS sh ON sh.supplier_id = s.supplier_id
    GROUP BY s.supplier_id, s.name
) AS rp
WHERE rp.valor_acumulado > 1000000
ORDER BY rp.valor_acumulado DESC;

-- ============================================================
-- 3. CONSULTAS CON CTEs Y CASE WHEN
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 1 — CTE simple + clasificación CASE WHEN
-- El CTE "envios_validos" pre-procesa los datos: descarta los
-- envíos cancelados, ya que no representan valor real importado.
-- La consulta principal toma ese resultado y clasifica cada envío
-- por rango de valor usando CASE WHEN (3 ramas: alto/medio/bajo).
-- ------------------------------------------------------------
WITH envios_validos AS (
    SELECT
        shipment_id,
        tracking_code,
        total_value,
        status
    FROM shipments
    WHERE status != 'cancelled'
)
SELECT
    ev.tracking_code   AS codigo_seguimiento,
    ev.total_value      AS valor_envio,
    ev.status           AS estado,
    CASE
        WHEN ev.total_value > 3000000 THEN 'Alto valor'
        WHEN ev.total_value > 1000000 THEN 'Valor medio'
        ELSE 'Valor bajo'
    END AS categoria_valor
FROM envios_validos AS ev
ORDER BY ev.total_value DESC;

-- ------------------------------------------------------------
-- CONSULTA 2 — Dos CTEs encadenados
-- Primer CTE "metricas_proveedor": agrega, por cada proveedor,
-- el total de envíos realizados y el valor acumulado importado.
-- Segundo CTE "proveedores_destacados": filtra ese resultado,
-- quedándose solo con los proveedores que tienen 5 o más envíos
-- Y un valor acumulado superior a 5.000.000 USD (referencia el
-- primer CTE, no las tablas originales).
-- La consulta final muestra esos proveedores destacados, ya
-- clasificados por nivel de actividad con CASE WHEN.
-- ------------------------------------------------------------
WITH metricas_proveedor AS (
    SELECT
        s.supplier_id          AS supplier_id,
        s.name                 AS proveedor,
        s.country               AS pais,
        COUNT(sh.shipment_id)   AS total_envios,
        SUM(sh.total_value)     AS valor_acumulado
    FROM suppliers AS s
    JOIN shipments AS sh ON sh.supplier_id = s.supplier_id
    GROUP BY s.supplier_id, s.name, s.country
),
proveedores_destacados AS (
    SELECT
        mp.proveedor,
        mp.pais,
        mp.total_envios,
        mp.valor_acumulado
    FROM metricas_proveedor AS mp
    WHERE mp.total_envios >= 5
      AND mp.valor_acumulado > 5000000
)
SELECT
    pd.proveedor          AS proveedor,
    pd.pais                AS pais,
    pd.total_envios         AS total_envios,
    pd.valor_acumulado      AS valor_acumulado,
    CASE
        WHEN pd.valor_acumulado > 15000000 THEN 'Proveedor estratégico'
        WHEN pd.valor_acumulado > 8000000  THEN 'Proveedor relevante'
        ELSE 'Proveedor destacado'
    END AS nivel_importancia
FROM proveedores_destacados AS pd
ORDER BY pd.valor_acumulado DESC;

-- ------------------------------------------------------------
-- CONSULTA 3 — CTE con CASE WHEN y agregación condicional
-- El CTE "envios_con_aduana" combina shipments y customs mediante
-- LEFT JOIN, para que también queden incluidos los envíos que aún
-- no tienen trámite aduanero (cleared queda NULL en ese caso).
-- La consulta principal agrupa por proveedor y usa
-- COUNT(CASE WHEN ...) para contar, dentro del mismo SELECT,
-- cuántos envíos están liberados, cuántos pendientes y cuántos
-- todavía sin trámite registrado.
-- ------------------------------------------------------------
WITH envios_con_aduana AS (
    SELECT
        sh.shipment_id   AS shipment_id,
        sh.supplier_id    AS supplier_id,
        sh.total_value     AS total_value,
        c.cleared           AS cleared
    FROM shipments AS sh
    LEFT JOIN customs AS c ON c.shipment_id = sh.shipment_id
)
SELECT
    s.name                                                AS proveedor,
    COUNT(eca.shipment_id)                                AS total_envios,
    COUNT(CASE WHEN eca.cleared = 1 THEN 1 END)            AS liberados,
    COUNT(CASE WHEN eca.cleared = 0 THEN 1 END)            AS pendientes_aduana,
    COUNT(CASE WHEN eca.cleared IS NULL THEN 1 END)        AS sin_tramite
FROM suppliers AS s
JOIN envios_con_aduana AS eca ON eca.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.name
ORDER BY total_envios DESC;