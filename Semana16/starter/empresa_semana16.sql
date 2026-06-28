--  PROYECTO — SEMANA 16: Índices y Consultas Optimizadas
--  Motor: PostgreSQL
--  Dominio: Empresa de Importación (bc-sql)
--  Tabla principal: shipments (envíos de importación)


-- ------------------------------------------------------------
-- 0. LIMPIAR TABLA SI EXISTE (para poder re-ejecutar el script)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS shipments;

-- ============================================================
-- 1. ESQUEMA (DDL) — SIN índices adicionales todavía
--    Solo queda la PK (que ya trae su propio índice implícito).
--    Los índices estratégicos se agregan más abajo, DESPUÉS de
--    medir el rendimiento "antes" con EXPLAIN.
-- ============================================================

CREATE TABLE shipments (
    shipment_id     SERIAL PRIMARY KEY,
    tracking_code   TEXT    NOT NULL UNIQUE,
    supplier_name   TEXT    NOT NULL,
    product_name    TEXT    NOT NULL,
    category        TEXT    NOT NULL
                            CHECK (category IN (
                                'Electronics','Textiles','Machinery',
                                'Agriculture','Raw Material'
                            )),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC NOT NULL CHECK (unit_price > 0),
    total_value     NUMERIC NOT NULL CHECK (total_value > 0),
    ship_date       DATE    NOT NULL,
    status          TEXT    NOT NULL
                            CHECK (status IN ('delivered','in_transit','pending','cancelled'))
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    200 envíos con fechas distribuidas entre 2021-01 y 2024-06
--    (más de 3 años), para que AGE() y DATE_TRUNC() tengan
--    variación temporal real.
-- ============================================================

INSERT INTO shipments (tracking_code, supplier_name, product_name, category, quantity, unit_price, total_value, ship_date, status) VALUES
('TRK-2022-1000', 'Istanbul Textile Group', 'Soybean Oil 1L', 'Agriculture', 1467, 570.59, 837055.53, '2022-08-17', 'delivered'),
('TRK-2023-1001', 'Bangkok Rubber Exports', 'Laptop 15 inch', 'Electronics', 840, 236.72, 198844.8, '2023-11-19', 'in_transit'),
('TRK-2022-1002', 'Madrid Olive Oil SL', 'Conveyor Belt 10m', 'Machinery', 4861, 608.76, 2959182.36, '2022-10-30', 'delivered'),
('TRK-2023-1003', 'Detroit Steel Supply', 'Hydraulic Pump', 'Machinery', 5076, 240.25, 1219509.0, '2023-11-13', 'delivered'),
('TRK-2022-1004', 'Sao Paulo Agro SA', 'USB-C Cable 2m', 'Electronics', 902, 1414.79, 1276140.58, '2022-08-17', 'delivered'),
('TRK-2022-1005', 'Seoul Electronics Co', 'Cocoa Beans 1kg', 'Agriculture', 3920, 1375.5, 5391960.0, '2022-01-22', 'delivered'),
('TRK-2023-1006', 'Milano Leather Works', 'Cotton Fabric 100m', 'Textiles', 375, 1011.23, 379211.25, '2023-06-13', 'in_transit'),
('TRK-2024-1007', 'Jakarta Rubber Corp', 'Conveyor Belt 10m', 'Machinery', 5185, 681.54, 3533784.9, '2024-01-13', 'delivered'),
('TRK-2021-1008', 'Monterrey Auto Parts SA', 'Rice Sack 25kg', 'Agriculture', 5068, 1229.78, 6232525.04, '2021-03-31', 'delivered'),
('TRK-2024-1009', 'Berlin Machinery GmbH', 'Laptop 15 inch', 'Electronics', 4771, 1130.68, 5394474.28, '2024-02-13', 'delivered'),
('TRK-2022-1010', 'Bangkok Rubber Exports', 'CNC Spindle Part', 'Machinery', 3333, 169.06, 563476.98, '2022-11-28', 'delivered'),
('TRK-2023-1011', 'Bangkok Rubber Exports', 'Cotton Fabric 100m', 'Textiles', 3569, 1141.55, 4074191.95, '2023-08-29', 'delivered'),
('TRK-2021-1012', 'Toronto Cold Chain Inc', 'Cotton Fabric 100m', 'Textiles', 5096, 974.85, 4967835.6, '2021-05-10', 'delivered'),
('TRK-2022-1013', 'Hanoi Garments JSC', 'USB-C Cable 2m', 'Electronics', 1481, 1032.98, 1529843.38, '2022-01-30', 'pending'),
('TRK-2021-1014', 'Sao Paulo Agro SA', 'Wireless Router', 'Electronics', 7891, 1467.17, 11577438.47, '2021-05-13', 'cancelled'),
('TRK-2022-1015', 'Jakarta Rubber Corp', 'Copper Wire Roll', 'Raw Material', 555, 427.64, 237340.2, '2022-09-07', 'delivered'),
('TRK-2021-1016', 'Istanbul Textile Group', 'Conveyor Belt 10m', 'Machinery', 616, 477.46, 294115.36, '2021-09-27', 'pending'),
('TRK-2023-1017', 'Seoul Electronics Co', 'Wool Sweater Lot', 'Textiles', 3263, 977.19, 3188570.97, '2023-06-28', 'delivered'),
('TRK-2023-1018', 'Milano Leather Works', 'Steel Coil', 'Raw Material', 2302, 1119.09, 2576145.18, '2023-10-28', 'pending'),
('TRK-2023-1019', 'Shenzhen Tech Imports', 'Denim Jeans Bulk', 'Textiles', 4607, 732.61, 3375134.27, '2023-10-30', 'delivered'),
('TRK-2021-1020', 'Madrid Olive Oil SL', 'Coffee Beans 1kg', 'Agriculture', 7751, 680.04, 5270990.04, '2021-09-27', 'delivered'),
('TRK-2023-1021', 'Jakarta Rubber Corp', 'Natural Rubber Sheet', 'Raw Material', 2634, 1450.97, 3821854.98, '2023-10-14', 'delivered'),
('TRK-2023-1022', 'Seoul Electronics Co', 'Wireless Router', 'Electronics', 7704, 953.13, 7342913.52, '2023-04-05', 'delivered'),
('TRK-2021-1023', 'Monterrey Auto Parts SA', 'Steel Coil', 'Raw Material', 1827, 236.24, 431610.48, '2021-10-30', 'in_transit'),
('TRK-2022-1024', 'Jakarta Rubber Corp', 'USB-C Cable 2m', 'Electronics', 133, 804.47, 106994.51, '2022-03-10', 'in_transit'),
('TRK-2023-1025', 'Berlin Machinery GmbH', 'Cotton Fabric 100m', 'Textiles', 652, 182.7, 119120.4, '2023-03-13', 'delivered'),
('TRK-2021-1026', 'Osaka Components KK', 'USB-C Cable 2m', 'Electronics', 3319, 194.06, 644085.14, '2021-11-28', 'in_transit'),
('TRK-2022-1027', 'Jakarta Rubber Corp', 'Bluetooth Speaker', 'Electronics', 4883, 1405.76, 6864326.08, '2022-08-15', 'delivered'),
('TRK-2021-1028', 'Seoul Electronics Co', 'Denim Jeans Bulk', 'Textiles', 151, 250.39, 37808.89, '2021-12-22', 'in_transit'),
('TRK-2023-1029', 'Toronto Cold Chain Inc', 'Wool Sweater Lot', 'Textiles', 5738, 1412.96, 8107564.48, '2023-02-13', 'pending'),
('TRK-2022-1030', 'Bangkok Rubber Exports', 'Silk Scarf Pack', 'Textiles', 7908, 225.26, 1781356.08, '2022-06-24', 'pending'),
('TRK-2023-1031', 'Osaka Components KK', 'Denim Jeans Bulk', 'Textiles', 3953, 269.72, 1066203.16, '2023-07-12', 'pending'),
('TRK-2024-1032', 'Monterrey Auto Parts SA', 'Rice Sack 25kg', 'Agriculture', 6483, 446.8, 2896604.4, '2024-03-29', 'pending'),
('TRK-2022-1033', 'Hanoi Garments JSC', 'Cocoa Beans 1kg', 'Agriculture', 3768, 170.08, 640861.44, '2022-07-25', 'in_transit'),
('TRK-2021-1034', 'Detroit Steel Supply', 'CNC Spindle Part', 'Machinery', 3954, 1339.67, 5297055.18, '2021-12-23', 'delivered'),
('TRK-2022-1035', 'Berlin Machinery GmbH', 'Conveyor Belt 10m', 'Machinery', 3537, 460.61, 1629177.57, '2022-07-14', 'delivered'),
('TRK-2022-1036', 'Seoul Electronics Co', 'Soybean Oil 1L', 'Agriculture', 1907, 1204.16, 2296333.12, '2022-09-10', 'delivered'),
('TRK-2022-1037', 'Osaka Components KK', 'Silk Scarf Pack', 'Textiles', 5413, 1066.27, 5771719.51, '2022-11-27', 'delivered'),
('TRK-2022-1038', 'Bangkok Rubber Exports', 'Bluetooth Speaker', 'Electronics', 410, 439.87, 180346.7, '2022-04-01', 'pending'),
('TRK-2021-1039', 'Detroit Steel Supply', 'Industrial Motor 5HP', 'Machinery', 7742, 523.12, 4049995.04, '2021-05-03', 'pending'),
('TRK-2021-1040', 'Shenzhen Tech Imports', 'Soybean Oil 1L', 'Agriculture', 2557, 575.79, 1472295.03, '2021-11-29', 'delivered'),
('TRK-2021-1041', 'Toronto Cold Chain Inc', 'Smartphone X12', 'Electronics', 4368, 42.08, 183805.44, '2021-06-08', 'cancelled'),
('TRK-2024-1042', 'Shenzhen Tech Imports', 'Laptop 15 inch', 'Electronics', 4541, 1152.27, 5232458.07, '2024-02-17', 'delivered'),
('TRK-2023-1043', 'Seoul Electronics Co', 'Rice Sack 25kg', 'Agriculture', 3698, 344.94, 1275588.12, '2023-12-29', 'delivered'),
('TRK-2024-1044', 'Shenzhen Tech Imports', 'Wireless Router', 'Electronics', 149, 1242.72, 185165.28, '2024-02-17', 'in_transit'),
('TRK-2024-1045', 'Toronto Cold Chain Inc', 'Bluetooth Speaker', 'Electronics', 6377, 330.78, 2109384.06, '2024-06-01', 'in_transit'),
('TRK-2024-1046', 'Istanbul Textile Group', 'Soybean Oil 1L', 'Agriculture', 3204, 725.52, 2324566.08, '2024-04-24', 'delivered'),
('TRK-2021-1047', 'Seoul Electronics Co', 'Wool Sweater Lot', 'Textiles', 943, 971.17, 915813.31, '2021-10-01', 'delivered'),
('TRK-2024-1048', 'Toronto Cold Chain Inc', 'Hydraulic Pump', 'Machinery', 2307, 350.04, 807542.28, '2024-01-03', 'delivered'),
('TRK-2022-1049', 'Istanbul Textile Group', 'Copper Wire Roll', 'Raw Material', 5722, 823.86, 4714126.92, '2022-11-12', 'delivered'),
('TRK-2023-1050', 'Madrid Olive Oil SL', 'Wireless Router', 'Electronics', 3297, 207.33, 683567.01, '2023-03-21', 'delivered'),
('TRK-2022-1051', 'Milano Leather Works', 'Silk Scarf Pack', 'Textiles', 3516, 504.16, 1772626.56, '2022-11-06', 'pending'),
('TRK-2022-1052', 'Jakarta Rubber Corp', 'Cocoa Beans 1kg', 'Agriculture', 5213, 831.23, 4333201.99, '2022-06-18', 'in_transit'),
('TRK-2024-1053', 'Detroit Steel Supply', 'Cotton Fabric 100m', 'Textiles', 3972, 1144.31, 4545199.32, '2024-05-10', 'in_transit'),
('TRK-2024-1054', 'Sao Paulo Agro SA', 'CNC Spindle Part', 'Machinery', 6015, 1149.42, 6913761.3, '2024-03-08', 'in_transit'),
('TRK-2022-1055', 'Monterrey Auto Parts SA', 'Cotton Fabric 100m', 'Textiles', 5057, 126.11, 637738.27, '2022-01-20', 'delivered'),
('TRK-2021-1056', 'Istanbul Textile Group', 'Denim Jeans Bulk', 'Textiles', 2688, 238.04, 639851.52, '2021-01-16', 'delivered'),
('TRK-2022-1057', 'Hanoi Garments JSC', 'Wireless Router', 'Electronics', 4598, 1391.71, 6399082.58, '2022-05-08', 'in_transit'),
('TRK-2022-1058', 'Madrid Olive Oil SL', 'Denim Jeans Bulk', 'Textiles', 3994, 1473.96, 5886996.24, '2022-09-09', 'in_transit'),
('TRK-2024-1059', 'Toronto Cold Chain Inc', 'Wool Sweater Lot', 'Textiles', 2488, 951.99, 2368551.12, '2024-01-31', 'in_transit'),
('TRK-2021-1060', 'Istanbul Textile Group', 'Industrial Motor 5HP', 'Machinery', 3071, 411.18, 1262733.78, '2021-04-04', 'pending'),
('TRK-2023-1061', 'Jakarta Rubber Corp', 'Natural Rubber Sheet', 'Raw Material', 6192, 602.28, 3729317.76, '2023-10-19', 'delivered'),
('TRK-2023-1062', 'Shenzhen Tech Imports', 'Denim Jeans Bulk', 'Textiles', 2140, 736.73, 1576602.2, '2023-05-06', 'delivered'),
('TRK-2022-1063', 'Istanbul Textile Group', 'Industrial Motor 5HP', 'Machinery', 20, 471.52, 9430.4, '2022-06-13', 'delivered'),
('TRK-2022-1064', 'Osaka Components KK', 'Wireless Router', 'Electronics', 5163, 1482.1, 7652082.3, '2022-01-25', 'delivered'),
('TRK-2023-1065', 'Detroit Steel Supply', 'Smartphone X12', 'Electronics', 2894, 650.13, 1881476.22, '2023-05-19', 'delivered'),
('TRK-2022-1066', 'Seoul Electronics Co', 'Aluminum Ingot', 'Raw Material', 147, 616.43, 90615.21, '2022-02-11', 'delivered'),
('TRK-2022-1067', 'Hanoi Garments JSC', 'Cocoa Beans 1kg', 'Agriculture', 6367, 765.17, 4871837.39, '2022-05-13', 'delivered'),
('TRK-2023-1068', 'Hanoi Garments JSC', 'Industrial Motor 5HP', 'Machinery', 1269, 471.12, 597851.28, '2023-11-26', 'delivered'),
('TRK-2024-1069', 'Hanoi Garments JSC', 'Natural Rubber Sheet', 'Raw Material', 4745, 1193.91, 5665102.95, '2024-05-04', 'pending'),
('TRK-2021-1070', 'Shenzhen Tech Imports', 'Conveyor Belt 10m', 'Machinery', 834, 512.71, 427600.14, '2021-12-26', 'in_transit'),
('TRK-2021-1071', 'Osaka Components KK', 'USB-C Cable 2m', 'Electronics', 1011, 772.66, 781159.26, '2021-04-15', 'delivered'),
('TRK-2021-1072', 'Shenzhen Tech Imports', 'Laptop 15 inch', 'Electronics', 393, 274.15, 107740.95, '2021-09-22', 'delivered'),
('TRK-2022-1073', 'Hanoi Garments JSC', 'USB-C Cable 2m', 'Electronics', 7509, 86.87, 652306.83, '2022-02-10', 'delivered'),
('TRK-2021-1074', 'Madrid Olive Oil SL', 'Bluetooth Speaker', 'Electronics', 1971, 646.92, 1275079.32, '2021-02-05', 'delivered'),
('TRK-2022-1075', 'Monterrey Auto Parts SA', 'USB-C Cable 2m', 'Electronics', 3843, 1236.33, 4751216.19, '2022-02-27', 'delivered'),
('TRK-2023-1076', 'Detroit Steel Supply', 'Cotton Fabric 100m', 'Textiles', 4072, 59.11, 240695.92, '2023-04-04', 'delivered'),
('TRK-2023-1077', 'Madrid Olive Oil SL', 'Hydraulic Pump', 'Machinery', 3421, 530.76, 1815729.96, '2023-06-29', 'in_transit'),
('TRK-2023-1078', 'Sao Paulo Agro SA', 'Natural Rubber Sheet', 'Raw Material', 6180, 698.63, 4317533.4, '2023-01-19', 'in_transit'),
('TRK-2021-1079', 'Mumbai Textiles Ltd', 'Hydraulic Pump', 'Machinery', 7433, 401.65, 2985464.45, '2021-03-06', 'delivered'),
('TRK-2022-1080', 'Osaka Components KK', 'Natural Rubber Sheet', 'Raw Material', 5412, 1231.12, 6662821.44, '2022-08-22', 'in_transit'),
('TRK-2023-1081', 'Shenzhen Tech Imports', 'Cocoa Beans 1kg', 'Agriculture', 1066, 1122.05, 1196105.3, '2023-06-28', 'pending'),
('TRK-2021-1082', 'Toronto Cold Chain Inc', 'Cotton Fabric 100m', 'Textiles', 4610, 1447.6, 6673436.0, '2021-06-27', 'in_transit'),
('TRK-2021-1083', 'Jakarta Rubber Corp', 'Cotton Fabric 100m', 'Textiles', 4983, 1171.42, 5837185.86, '2021-02-04', 'delivered'),
('TRK-2022-1084', 'Osaka Components KK', 'Soybean Oil 1L', 'Agriculture', 4961, 1043.13, 5174967.93, '2022-12-06', 'pending'),
('TRK-2023-1085', 'Berlin Machinery GmbH', 'CNC Spindle Part', 'Machinery', 1230, 433.47, 533168.1, '2023-05-01', 'in_transit'),
('TRK-2022-1086', 'Mumbai Textiles Ltd', 'Laptop 15 inch', 'Electronics', 5998, 1254.27, 7523111.46, '2022-06-18', 'delivered'),
('TRK-2023-1087', 'Milano Leather Works', 'Smartphone X12', 'Electronics', 1153, 1419.94, 1637190.82, '2023-12-10', 'pending'),
('TRK-2022-1088', 'Detroit Steel Supply', 'Soybean Oil 1L', 'Agriculture', 3231, 157.84, 509981.04, '2022-08-06', 'pending'),
('TRK-2023-1089', 'Shenzhen Tech Imports', 'Steel Coil', 'Raw Material', 494, 1416.07, 699538.58, '2023-03-27', 'in_transit'),
('TRK-2022-1090', 'Milano Leather Works', 'CNC Spindle Part', 'Machinery', 1960, 1170.77, 2294709.2, '2022-10-09', 'in_transit'),
('TRK-2022-1091', 'Madrid Olive Oil SL', 'USB-C Cable 2m', 'Electronics', 6088, 280.73, 1709084.24, '2022-03-26', 'in_transit'),
('TRK-2022-1092', 'Bangkok Rubber Exports', 'USB-C Cable 2m', 'Electronics', 1209, 129.64, 156734.76, '2022-05-14', 'delivered'),
('TRK-2023-1093', 'Toronto Cold Chain Inc', 'USB-C Cable 2m', 'Electronics', 4794, 561.11, 2689961.34, '2023-05-09', 'in_transit'),
('TRK-2023-1094', 'Hanoi Garments JSC', 'Cocoa Beans 1kg', 'Agriculture', 3426, 815.54, 2794040.04, '2023-03-10', 'delivered'),
('TRK-2021-1095', 'Detroit Steel Supply', 'Copper Wire Roll', 'Raw Material', 304, 1441.97, 438358.88, '2021-04-28', 'pending'),
('TRK-2023-1096', 'Monterrey Auto Parts SA', 'Cocoa Beans 1kg', 'Agriculture', 6153, 1319.75, 8120421.75, '2023-05-15', 'delivered'),
('TRK-2021-1097', 'Berlin Machinery GmbH', 'Cocoa Beans 1kg', 'Agriculture', 5894, 1289.67, 7601314.98, '2021-11-22', 'pending'),
('TRK-2021-1098', 'Toronto Cold Chain Inc', 'Soybean Oil 1L', 'Agriculture', 6793, 312.44, 2122404.92, '2021-09-14', 'delivered'),
('TRK-2021-1099', 'Istanbul Textile Group', 'Copper Wire Roll', 'Raw Material', 6179, 956.13, 5907927.27, '2021-05-28', 'cancelled'),
('TRK-2023-1100', 'Bangkok Rubber Exports', 'Bluetooth Speaker', 'Electronics', 7038, 1310.64, 9224284.32, '2023-11-13', 'cancelled'),
('TRK-2021-1101', 'Bangkok Rubber Exports', 'Conveyor Belt 10m', 'Machinery', 6210, 583.39, 3622851.9, '2021-01-03', 'pending'),
('TRK-2022-1102', 'Berlin Machinery GmbH', 'Natural Rubber Sheet', 'Raw Material', 5217, 93.89, 489824.13, '2022-01-14', 'in_transit'),
('TRK-2021-1103', 'Mumbai Textiles Ltd', 'Rice Sack 25kg', 'Agriculture', 1513, 721.78, 1092053.14, '2021-07-06', 'delivered'),
('TRK-2024-1104', 'Mumbai Textiles Ltd', 'USB-C Cable 2m', 'Electronics', 3131, 929.89, 2911485.59, '2024-01-26', 'delivered'),
('TRK-2023-1105', 'Berlin Machinery GmbH', 'CNC Spindle Part', 'Machinery', 924, 542.97, 501704.28, '2023-03-23', 'delivered'),
('TRK-2024-1106', 'Detroit Steel Supply', 'Industrial Motor 5HP', 'Machinery', 7088, 691.64, 4902344.32, '2024-05-11', 'cancelled'),
('TRK-2022-1107', 'Istanbul Textile Group', 'Coffee Beans 1kg', 'Agriculture', 5975, 1177.91, 7038012.25, '2022-01-29', 'in_transit'),
('TRK-2023-1108', 'Jakarta Rubber Corp', 'Natural Rubber Sheet', 'Raw Material', 3914, 35.34, 138320.76, '2023-04-29', 'delivered'),
('TRK-2022-1109', 'Osaka Components KK', 'Coffee Beans 1kg', 'Agriculture', 2600, 701.58, 1824108.0, '2022-10-05', 'delivered'),
('TRK-2021-1110', 'Hanoi Garments JSC', 'Silk Scarf Pack', 'Textiles', 1754, 1031.76, 1809707.04, '2021-11-15', 'delivered'),
('TRK-2023-1111', 'Shenzhen Tech Imports', 'Rice Sack 25kg', 'Agriculture', 2071, 240.51, 498096.21, '2023-06-08', 'delivered'),
('TRK-2023-1112', 'Monterrey Auto Parts SA', 'Laptop 15 inch', 'Electronics', 5899, 503.44, 2969792.56, '2023-11-27', 'delivered'),
('TRK-2022-1113', 'Berlin Machinery GmbH', 'Silk Scarf Pack', 'Textiles', 1955, 263.51, 515162.05, '2022-07-06', 'cancelled'),
('TRK-2021-1114', 'Istanbul Textile Group', 'Wool Sweater Lot', 'Textiles', 7160, 275.97, 1975945.2, '2021-01-05', 'in_transit'),
('TRK-2021-1115', 'Shenzhen Tech Imports', 'Natural Rubber Sheet', 'Raw Material', 1679, 716.9, 1203675.1, '2021-11-05', 'in_transit'),
('TRK-2023-1116', 'Istanbul Textile Group', 'Rice Sack 25kg', 'Agriculture', 6638, 191.63, 1272039.94, '2023-01-15', 'in_transit'),
('TRK-2022-1117', 'Shenzhen Tech Imports', 'Silk Scarf Pack', 'Textiles', 130, 988.12, 128455.6, '2022-11-05', 'delivered'),
('TRK-2021-1118', 'Seoul Electronics Co', 'Hydraulic Pump', 'Machinery', 7073, 21.02, 148674.46, '2021-08-27', 'cancelled'),
('TRK-2023-1119', 'Shenzhen Tech Imports', 'Hydraulic Pump', 'Machinery', 1169, 1184.4, 1384563.6, '2023-05-25', 'in_transit'),
('TRK-2023-1120', 'Monterrey Auto Parts SA', 'Coffee Beans 1kg', 'Agriculture', 3023, 485.24, 1466880.52, '2023-07-23', 'in_transit'),
('TRK-2022-1121', 'Istanbul Textile Group', 'Smartphone X12', 'Electronics', 4901, 437.39, 2143648.39, '2022-09-09', 'delivered'),
('TRK-2021-1122', 'Hanoi Garments JSC', 'Rice Sack 25kg', 'Agriculture', 1455, 337.45, 490989.75, '2021-03-01', 'cancelled'),
('TRK-2021-1123', 'Monterrey Auto Parts SA', 'Bluetooth Speaker', 'Electronics', 3306, 1311.81, 4336843.86, '2021-06-21', 'in_transit'),
('TRK-2023-1124', 'Jakarta Rubber Corp', 'CNC Spindle Part', 'Machinery', 4999, 995.06, 4974304.94, '2023-04-04', 'delivered'),
('TRK-2022-1125', 'Detroit Steel Supply', 'Silk Scarf Pack', 'Textiles', 3994, 1118.81, 4468527.14, '2022-12-01', 'in_transit'),
('TRK-2022-1126', 'Osaka Components KK', 'Laptop 15 inch', 'Electronics', 6485, 306.83, 1989792.55, '2022-01-16', 'delivered'),
('TRK-2022-1127', 'Istanbul Textile Group', 'Copper Wire Roll', 'Raw Material', 4884, 214.42, 1047227.28, '2022-02-24', 'pending'),
('TRK-2024-1128', 'Seoul Electronics Co', 'Soybean Oil 1L', 'Agriculture', 4616, 1296.81, 5986074.96, '2024-03-23', 'delivered'),
('TRK-2021-1129', 'Seoul Electronics Co', 'Smartphone X12', 'Electronics', 4913, 485.94, 2387423.22, '2021-03-21', 'in_transit'),
('TRK-2021-1130', 'Berlin Machinery GmbH', 'Wireless Router', 'Electronics', 699, 1018.39, 711854.61, '2021-11-01', 'delivered'),
('TRK-2021-1131', 'Bangkok Rubber Exports', 'Silk Scarf Pack', 'Textiles', 6174, 711.48, 4392677.52, '2021-10-06', 'in_transit'),
('TRK-2022-1132', 'Detroit Steel Supply', 'Rice Sack 25kg', 'Agriculture', 87, 162.6, 14146.2, '2022-07-17', 'delivered'),
('TRK-2022-1133', 'Istanbul Textile Group', 'Industrial Motor 5HP', 'Machinery', 5739, 1363.22, 7823519.58, '2022-12-11', 'delivered'),
('TRK-2021-1134', 'Milano Leather Works', 'Silk Scarf Pack', 'Textiles', 894, 1191.74, 1065415.56, '2021-07-20', 'delivered'),
('TRK-2023-1135', 'Bangkok Rubber Exports', 'Copper Wire Roll', 'Raw Material', 4257, 697.11, 2967597.27, '2023-05-01', 'delivered'),
('TRK-2022-1136', 'Seoul Electronics Co', 'Industrial Motor 5HP', 'Machinery', 3263, 1085.43, 3541758.09, '2022-03-21', 'delivered'),
('TRK-2021-1137', 'Osaka Components KK', 'Laptop 15 inch', 'Electronics', 2917, 306.41, 893797.97, '2021-04-03', 'delivered'),
('TRK-2021-1138', 'Osaka Components KK', 'Soybean Oil 1L', 'Agriculture', 269, 1397.54, 375938.26, '2021-11-26', 'in_transit'),
('TRK-2022-1139', 'Toronto Cold Chain Inc', 'Industrial Motor 5HP', 'Machinery', 2238, 87.85, 196608.3, '2022-05-30', 'delivered'),
('TRK-2021-1140', 'Hanoi Garments JSC', 'Denim Jeans Bulk', 'Textiles', 5540, 143.81, 796707.4, '2021-08-13', 'delivered'),
('TRK-2024-1141', 'Madrid Olive Oil SL', 'Soybean Oil 1L', 'Agriculture', 6846, 422.79, 2894420.34, '2024-03-29', 'delivered'),
('TRK-2022-1142', 'Monterrey Auto Parts SA', 'Copper Wire Roll', 'Raw Material', 1389, 1328.91, 1845855.99, '2022-08-20', 'delivered'),
('TRK-2024-1143', 'Milano Leather Works', 'Conveyor Belt 10m', 'Machinery', 2340, 703.96, 1647266.4, '2024-02-08', 'delivered'),
('TRK-2024-1144', 'Seoul Electronics Co', 'Laptop 15 inch', 'Electronics', 7475, 619.97, 4634275.75, '2024-02-06', 'in_transit'),
('TRK-2023-1145', 'Berlin Machinery GmbH', 'Industrial Motor 5HP', 'Machinery', 6604, 1241.61, 8199592.44, '2023-10-24', 'delivered'),
('TRK-2022-1146', 'Detroit Steel Supply', 'Steel Coil', 'Raw Material', 2890, 943.15, 2725703.5, '2022-05-07', 'delivered'),
('TRK-2022-1147', 'Detroit Steel Supply', 'Cocoa Beans 1kg', 'Agriculture', 1582, 793.95, 1256028.9, '2022-02-07', 'in_transit'),
('TRK-2022-1148', 'Milano Leather Works', 'Soybean Oil 1L', 'Agriculture', 7179, 443.86, 3186470.94, '2022-10-25', 'in_transit'),
('TRK-2022-1149', 'Toronto Cold Chain Inc', 'USB-C Cable 2m', 'Electronics', 7353, 1107.59, 8144109.27, '2022-10-30', 'cancelled'),
('TRK-2023-1150', 'Madrid Olive Oil SL', 'Steel Coil', 'Raw Material', 355, 35.28, 12524.4, '2023-09-02', 'delivered'),
('TRK-2021-1151', 'Hanoi Garments JSC', 'CNC Spindle Part', 'Machinery', 6330, 1327.0, 8399910.0, '2021-11-24', 'in_transit'),
('TRK-2022-1152', 'Seoul Electronics Co', 'Natural Rubber Sheet', 'Raw Material', 4989, 124.7, 622128.3, '2022-03-04', 'delivered'),
('TRK-2023-1153', 'Istanbul Textile Group', 'Denim Jeans Bulk', 'Textiles', 309, 279.75, 86442.75, '2023-12-02', 'in_transit'),
('TRK-2022-1154', 'Jakarta Rubber Corp', 'Industrial Motor 5HP', 'Machinery', 2526, 454.23, 1147384.98, '2022-11-06', 'delivered'),
('TRK-2021-1155', 'Milano Leather Works', 'Aluminum Ingot', 'Raw Material', 6798, 187.15, 1272245.7, '2021-03-05', 'pending'),
('TRK-2022-1156', 'Bangkok Rubber Exports', 'Smartphone X12', 'Electronics', 1674, 221.02, 369987.48, '2022-05-22', 'delivered'),
('TRK-2022-1157', 'Mumbai Textiles Ltd', 'Aluminum Ingot', 'Raw Material', 1852, 1244.91, 2305573.32, '2022-09-09', 'delivered'),
('TRK-2021-1158', 'Seoul Electronics Co', 'Natural Rubber Sheet', 'Raw Material', 3773, 453.43, 1710791.39, '2021-02-19', 'delivered'),
('TRK-2023-1159', 'Toronto Cold Chain Inc', 'Aluminum Ingot', 'Raw Material', 250, 838.7, 209675.0, '2023-09-12', 'delivered'),
('TRK-2021-1160', 'Sao Paulo Agro SA', 'Hydraulic Pump', 'Machinery', 7105, 808.46, 5744108.3, '2021-12-29', 'in_transit'),
('TRK-2021-1161', 'Jakarta Rubber Corp', 'Rice Sack 25kg', 'Agriculture', 3613, 895.1, 3233996.3, '2021-03-30', 'in_transit'),
('TRK-2022-1162', 'Shenzhen Tech Imports', 'Cocoa Beans 1kg', 'Agriculture', 2658, 1183.23, 3145025.34, '2022-02-21', 'delivered'),
('TRK-2023-1163', 'Milano Leather Works', 'Copper Wire Roll', 'Raw Material', 2154, 618.52, 1332292.08, '2023-11-17', 'cancelled'),
('TRK-2024-1164', 'Jakarta Rubber Corp', 'Steel Coil', 'Raw Material', 1587, 1285.62, 2040278.94, '2024-05-11', 'delivered'),
('TRK-2021-1165', 'Bangkok Rubber Exports', 'Cocoa Beans 1kg', 'Agriculture', 5243, 777.91, 4078582.13, '2021-02-25', 'delivered'),
('TRK-2022-1166', 'Milano Leather Works', 'Cotton Fabric 100m', 'Textiles', 3800, 872.11, 3314018.0, '2022-07-12', 'delivered'),
('TRK-2023-1167', 'Madrid Olive Oil SL', 'Rice Sack 25kg', 'Agriculture', 528, 1195.66, 631308.48, '2023-12-16', 'in_transit'),
('TRK-2021-1168', 'Istanbul Textile Group', 'USB-C Cable 2m', 'Electronics', 595, 1397.06, 831250.7, '2021-05-04', 'delivered'),
('TRK-2021-1169', 'Hanoi Garments JSC', 'Conveyor Belt 10m', 'Machinery', 3582, 1292.21, 4628696.22, '2021-07-28', 'delivered'),
('TRK-2022-1170', 'Bangkok Rubber Exports', 'Hydraulic Pump', 'Machinery', 7613, 935.26, 7120134.38, '2022-07-23', 'delivered'),
('TRK-2022-1171', 'Sao Paulo Agro SA', 'Wireless Router', 'Electronics', 3843, 195.15, 749961.45, '2022-04-08', 'delivered'),
('TRK-2022-1172', 'Bangkok Rubber Exports', 'Steel Coil', 'Raw Material', 6151, 63.62, 391326.62, '2022-12-21', 'in_transit'),
('TRK-2021-1173', 'Mumbai Textiles Ltd', 'Conveyor Belt 10m', 'Machinery', 4840, 155.79, 754023.6, '2021-10-26', 'pending'),
('TRK-2023-1174', 'Shenzhen Tech Imports', 'Industrial Motor 5HP', 'Machinery', 1091, 657.57, 717408.87, '2023-01-24', 'delivered'),
('TRK-2024-1175', 'Hanoi Garments JSC', 'Natural Rubber Sheet', 'Raw Material', 3064, 1272.07, 3897622.48, '2024-04-12', 'pending'),
('TRK-2023-1176', 'Jakarta Rubber Corp', 'CNC Spindle Part', 'Machinery', 7410, 593.88, 4400650.8, '2023-05-14', 'pending'),
('TRK-2022-1177', 'Seoul Electronics Co', 'CNC Spindle Part', 'Machinery', 6821, 1374.71, 9376896.91, '2022-11-05', 'pending'),
('TRK-2022-1178', 'Shenzhen Tech Imports', 'Industrial Motor 5HP', 'Machinery', 2175, 397.03, 863540.25, '2022-10-03', 'in_transit'),
('TRK-2021-1179', 'Berlin Machinery GmbH', 'Natural Rubber Sheet', 'Raw Material', 521, 718.93, 374562.53, '2021-07-25', 'delivered'),
('TRK-2021-1180', 'Berlin Machinery GmbH', 'Cotton Fabric 100m', 'Textiles', 2358, 831.96, 1961761.68, '2021-02-28', 'delivered'),
('TRK-2024-1181', 'Madrid Olive Oil SL', 'Coffee Beans 1kg', 'Agriculture', 7589, 405.05, 3073924.45, '2024-04-08', 'pending'),
('TRK-2022-1182', 'Mumbai Textiles Ltd', 'Coffee Beans 1kg', 'Agriculture', 1405, 717.16, 1007609.8, '2022-03-30', 'delivered'),
('TRK-2022-1183', 'Bangkok Rubber Exports', 'Coffee Beans 1kg', 'Agriculture', 6699, 350.46, 2347731.54, '2022-06-26', 'delivered'),
('TRK-2022-1184', 'Osaka Components KK', 'Copper Wire Roll', 'Raw Material', 3570, 1483.88, 5297451.6, '2022-10-17', 'delivered'),
('TRK-2024-1185', 'Osaka Components KK', 'Natural Rubber Sheet', 'Raw Material', 2472, 1431.57, 3538841.04, '2024-02-28', 'cancelled'),
('TRK-2021-1186', 'Istanbul Textile Group', 'Silk Scarf Pack', 'Textiles', 5497, 2.54, 13962.38, '2021-05-28', 'delivered'),
('TRK-2023-1187', 'Jakarta Rubber Corp', 'Smartphone X12', 'Electronics', 4329, 1091.93, 4726964.97, '2023-01-21', 'in_transit'),
('TRK-2023-1188', 'Berlin Machinery GmbH', 'Copper Wire Roll', 'Raw Material', 2431, 1277.65, 3105967.15, '2023-07-05', 'delivered'),
('TRK-2023-1189', 'Milano Leather Works', 'Smartphone X12', 'Electronics', 573, 1405.34, 805259.82, '2023-07-14', 'pending'),
('TRK-2022-1190', 'Jakarta Rubber Corp', 'Rice Sack 25kg', 'Agriculture', 4898, 602.22, 2949673.56, '2022-08-28', 'pending'),
('TRK-2022-1191', 'Istanbul Textile Group', 'Conveyor Belt 10m', 'Machinery', 2470, 1210.53, 2990009.1, '2022-10-30', 'pending'),
('TRK-2022-1192', 'Toronto Cold Chain Inc', 'USB-C Cable 2m', 'Electronics', 1028, 399.51, 410696.28, '2022-11-11', 'delivered'),
('TRK-2023-1193', 'Osaka Components KK', 'Natural Rubber Sheet', 'Raw Material', 4468, 1344.89, 6008968.52, '2023-06-23', 'in_transit'),
('TRK-2024-1194', 'Seoul Electronics Co', 'Hydraulic Pump', 'Machinery', 4807, 535.84, 2575782.88, '2024-03-03', 'in_transit'),
('TRK-2023-1195', 'Detroit Steel Supply', 'Soybean Oil 1L', 'Agriculture', 3562, 1403.74, 5000121.88, '2023-08-14', 'delivered'),
('TRK-2022-1196', 'Seoul Electronics Co', 'Coffee Beans 1kg', 'Agriculture', 2939, 1254.51, 3687004.89, '2022-12-09', 'delivered'),
('TRK-2021-1197', 'Sao Paulo Agro SA', 'Aluminum Ingot', 'Raw Material', 4759, 1032.77, 4914952.43, '2021-03-03', 'delivered'),
('TRK-2022-1198', 'Bangkok Rubber Exports', 'Denim Jeans Bulk', 'Textiles', 2875, 562.6, 1617475.0, '2022-01-13', 'delivered'),
('TRK-2022-1199', 'Toronto Cold Chain Inc', 'CNC Spindle Part', 'Machinery', 3511, 1155.97, 4058610.67, '2022-03-31', 'delivered');
-- ============================================================
-- 3. MEDICIÓN "ANTES" DEL ÍNDICE
-- ============================================================

-- ------------------------------------------------------------
-- EXPLAIN ANTES — búsqueda por proveedor (sin índice en supplier_name)
-- Sin índice, PostgreSQL debe recorrer TODA la tabla fila por fila
-- (Seq Scan) para encontrar las coincidencias, sin importar cuántas
-- haya. Con 200 filas la diferencia es modesta, pero el plan ya
-- muestra explícitamente "Seq Scan on shipments".
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT shipment_id, tracking_code, supplier_name, total_value
FROM shipments
WHERE supplier_name = 'Shenzhen Tech Imports';

-- ------------------------------------------------------------
-- EXPLAIN ANTES — búsqueda por rango de fechas (sin índice en ship_date)
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT shipment_id, tracking_code, ship_date, total_value
FROM shipments
WHERE ship_date BETWEEN '2023-01-01' AND '2023-12-31';

-- ============================================================
-- 4. ÍNDICES ESTRATÉGICOS
-- ============================================================

-- Índice sobre supplier_name: la consulta más frecuente del
-- negocio es "todos los envíos de tal proveedor", así que esta
-- columna es la primera candidata a indexar.
CREATE INDEX idx_shipments_supplier_name ON shipments(supplier_name);

-- Índice sobre ship_date: los reportes mensuales/anuales filtran
-- constantemente por rango de fechas.
CREATE INDEX idx_shipments_ship_date ON shipments(ship_date);

-- Índice compuesto sobre (category, status): útil para reportes
-- que cruzan ambas condiciones a la vez (ej. "envíos pendientes
-- de Electronics").
CREATE INDEX idx_shipments_category_status ON shipments(category, status);

-- ============================================================
-- 5. MEDICIÓN "DESPUÉS" DEL ÍNDICE
-- ============================================================

-- ------------------------------------------------------------
-- EXPLAIN DESPUÉS — misma búsqueda por proveedor, ya con índice
-- En tablas pequeñas (como esta, de 200 filas) el planificador de
-- PostgreSQL puede decidir que un Seq Scan sigue siendo más rápido
-- que usar el índice, porque el costo de saltar entre páginas del
-- índice no compensa para tan pocas filas. Esto es un
-- comportamiento NORMAL y esperado: el optimizador de costos
-- escoge el plan más barato, no el que "use" el índice por
-- principio. La diferencia real se nota a partir de varios miles
-- de filas, cuando el Index Scan empieza a ganar siempre.
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT shipment_id, tracking_code, supplier_name, total_value
FROM shipments
WHERE supplier_name = 'Shenzhen Tech Imports';

-- ------------------------------------------------------------
-- EXPLAIN DESPUÉS — misma búsqueda por rango de fechas, ya con índice
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT shipment_id, tracking_code, ship_date, total_value
FROM shipments
WHERE ship_date BETWEEN '2023-01-01' AND '2023-12-31';

-- ============================================================
-- 6. REPORTE FINAL — funciones de texto + fecha + numéricas
-- ============================================================

-- ------------------------------------------------------------
-- REPORTE — combina:
--   * Funciones de TEXTO: UPPER, INITCAP, SUBSTRING, CONCAT
--   * Funciones de FECHA: AGE, DATE_TRUNC, EXTRACT
--   * Funciones NUMÉRICAS: ROUND, CEIL, TO_CHAR (formato moneda)
-- para transformar y presentar los envíos de forma legible para
-- un reporte gerencial.
-- ------------------------------------------------------------
SELECT
    -- TEXTO: código en mayúsculas + nombre de proveedor con
    -- formato "Título" (primera letra de cada palabra en mayúscula)
    UPPER(tracking_code)                          AS codigo_seguimiento,
    INITCAP(supplier_name)                        AS proveedor,
    -- TEXTO: primeras 15 letras del nombre del producto + "..."
    -- si el nombre es más largo, para una vista compacta
    CONCAT(SUBSTRING(product_name, 1, 15), '...') AS producto_resumido,
    category                                       AS categoria,

    -- FECHA: mes/año truncado, útil para agrupar reportes mensuales
    DATE_TRUNC('month', ship_date)::date           AS mes_envio,
    -- FECHA: tiempo transcurrido desde el envío hasta hoy
    AGE(CURRENT_DATE, ship_date)                   AS antiguedad,
    -- FECHA: año extraído como número, para filtros rápidos
    EXTRACT(YEAR FROM ship_date)                   AS anio_envio,

    -- NUMÉRICO: valor total redondeado a 2 decimales y formateado
    -- como moneda, más el precio unitario redondeado hacia arriba
    TO_CHAR(ROUND(total_value, 2), 'FM999,999,999.00') AS valor_total_formateado,
    CEIL(unit_price)                                AS precio_unitario_redondeado,

    status                                          AS estado
FROM shipments
ORDER BY ship_date DESC
LIMIT 20;