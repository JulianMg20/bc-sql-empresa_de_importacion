-- ============================================================
--  PROYECTO — SEMANA 14: Ranking con Window Functions
--  Motor: PostgreSQL
--  Dominio: Empresa de Importación (bc-sql)
--  Tabla principal: shipments_raw (envíos, con duplicados reales
--                    por error de doble carga, a propósito)
-- ============================================================

-- ------------------------------------------------------------
-- 0. LIMPIAR TABLA SI EXISTE (para poder re-ejecutar el script)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS shipments_raw;

-- ============================================================
-- 1. ESQUEMA (DDL)
-- ============================================================

-- shipments_raw: simula una carga de datos "cruda" desde varios
-- sistemas de origen, SIN constraint UNIQUE en tracking_code,
-- porque en la práctica algunos envíos quedaron duplicados por
-- error de doble importación. Ese problema se resuelve más abajo
-- con ROW_NUMBER().
CREATE TABLE shipments_raw (
    raw_id          SERIAL PRIMARY KEY,
    tracking_code   TEXT    NOT NULL,
    supplier_name   TEXT    NOT NULL,
    category        TEXT    NOT NULL
                            CHECK (category IN (
                                'Electronics','Textiles','Machinery',
                                'Agriculture','Raw Material'
                            )),
    total_value     NUMERIC NOT NULL CHECK (total_value > 0),
    ship_date       DATE    NOT NULL,
    status          TEXT    NOT NULL
                            CHECK (status IN ('delivered','in_transit','pending','cancelled'))
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    200 filas en total:
--      - 185 envíos únicos
--      - 15 filas DUPLICADAS EXACTAS (mismo tracking_code y mismos
--        valores), simulando un error real de doble carga de datos
--    El valor (total_value) se generó en múltiplos de 5.000 dentro
--    de un rango por categoría, para producir EMPATES REALES y que
--    RANK() y DENSE_RANK() se comporten distinto entre sí.
-- ============================================================

INSERT INTO shipments_raw (tracking_code, supplier_name, category, total_value, ship_date, status) VALUES
('TRK-2024-1173', 'Milano Leather Works', 'Machinery', 145000, '2024-07-19', 'cancelled'),
('TRK-2024-1114', 'Sao Paulo Agro SA', 'Electronics', 140000, '2024-10-22', 'pending'),
('TRK-2024-1027', 'Sao Paulo Agro SA', 'Machinery', 185000, '2024-01-18', 'delivered'),
('TRK-2024-1015', 'Shenzhen Tech Imports', 'Agriculture', 35000, '2024-02-17', 'delivered'),
('TRK-2024-1082', 'Hanoi Garments JSC', 'Electronics', 60000, '2024-04-06', 'delivered'),
('TRK-2024-1009', 'Mumbai Textiles Ltd', 'Agriculture', 50000, '2024-04-05', 'in_transit'),
('TRK-2024-1060', 'Jakarta Rubber Corp', 'Textiles', 55000, '2024-04-20', 'pending'),
('TRK-2024-1127', 'Shenzhen Tech Imports', 'Textiles', 40000, '2024-05-14', 'in_transit'),
('TRK-2024-1178', 'Shenzhen Tech Imports', 'Machinery', 105000, '2024-06-23', 'delivered'),
('TRK-2024-1167', 'Berlin Machinery GmbH', 'Agriculture', 55000, '2024-03-26', 'in_transit'),
('TRK-2024-1118', 'Hanoi Garments JSC', 'Agriculture', 40000, '2024-10-15', 'in_transit'),
('TRK-2024-1108', 'Osaka Components KK', 'Agriculture', 60000, '2024-08-25', 'pending'),
('TRK-2024-1158', 'Monterrey Auto Parts SA', 'Textiles', 70000, '2024-05-07', 'in_transit'),
('TRK-2024-1098', 'Toronto Cold Chain Inc', 'Machinery', 80000, '2024-06-29', 'delivered'),
('TRK-2024-1160', 'Detroit Steel Supply', 'Raw Material', 100000, '2024-04-02', 'in_transit'),
('TRK-2024-1075', 'Monterrey Auto Parts SA', 'Agriculture', 60000, '2024-08-18', 'delivered'),
('TRK-2024-1039', 'Osaka Components KK', 'Electronics', 65000, '2024-05-24', 'delivered'),
('TRK-2024-1035', 'Shenzhen Tech Imports', 'Textiles', 75000, '2024-05-15', 'in_transit'),
('TRK-2024-1135', 'Shenzhen Tech Imports', 'Textiles', 30000, '2024-05-18', 'delivered'),
('TRK-2024-1059', 'Toronto Cold Chain Inc', 'Textiles', 70000, '2024-02-13', 'delivered'),
('TRK-2024-1158', 'Monterrey Auto Parts SA', 'Textiles', 70000, '2024-05-07', 'in_transit'),
('TRK-2024-1134', 'Bangkok Rubber Exports', 'Raw Material', 100000, '2024-02-14', 'delivered'),
('TRK-2024-1141', 'Berlin Machinery GmbH', 'Electronics', 85000, '2024-10-17', 'delivered'),
('TRK-2024-1045', 'Detroit Steel Supply', 'Raw Material', 40000, '2024-04-29', 'delivered'),
('TRK-2024-1119', 'Madrid Olive Oil SL', 'Raw Material', 85000, '2024-02-06', 'pending'),
('TRK-2024-1018', 'Mumbai Textiles Ltd', 'Raw Material', 35000, '2024-03-28', 'in_transit'),
('TRK-2024-1028', 'Seoul Electronics Co', 'Textiles', 50000, '2024-06-22', 'in_transit'),
('TRK-2024-1004', 'Milano Leather Works', 'Textiles', 80000, '2024-04-28', 'pending'),
('TRK-2024-1164', 'Hanoi Garments JSC', 'Textiles', 75000, '2024-01-15', 'in_transit'),
('TRK-2024-1078', 'Milano Leather Works', 'Textiles', 65000, '2024-08-09', 'delivered'),
('TRK-2024-1109', 'Berlin Machinery GmbH', 'Textiles', 70000, '2024-05-09', 'delivered'),
('TRK-2024-1058', 'Hanoi Garments JSC', 'Agriculture', 30000, '2024-07-16', 'delivered'),
('TRK-2024-1019', 'Milano Leather Works', 'Machinery', 135000, '2024-06-05', 'delivered'),
('TRK-2024-1103', 'Jakarta Rubber Corp', 'Raw Material', 40000, '2024-10-03', 'in_transit'),
('TRK-2024-1139', 'Hanoi Garments JSC', 'Electronics', 150000, '2024-03-03', 'pending'),
('TRK-2024-1111', 'Monterrey Auto Parts SA', 'Raw Material', 95000, '2024-04-15', 'delivered'),
('TRK-2024-1138', 'Seoul Electronics Co', 'Textiles', 60000, '2024-03-26', 'delivered'),
('TRK-2024-1091', 'Istanbul Textile Group', 'Textiles', 75000, '2024-08-04', 'delivered'),
('TRK-2024-1088', 'Monterrey Auto Parts SA', 'Electronics', 140000, '2024-05-20', 'in_transit'),
('TRK-2024-1113', 'Hanoi Garments JSC', 'Textiles', 30000, '2024-03-13', 'delivered'),
('TRK-2024-1177', 'Osaka Components KK', 'Machinery', 110000, '2024-03-23', 'pending'),
('TRK-2024-1005', 'Madrid Olive Oil SL', 'Electronics', 115000, '2024-07-27', 'in_transit'),
('TRK-2024-1044', 'Monterrey Auto Parts SA', 'Electronics', 110000, '2024-02-02', 'delivered'),
('TRK-2024-1073', 'Berlin Machinery GmbH', 'Electronics', 80000, '2024-01-18', 'delivered'),
('TRK-2024-1038', 'Osaka Components KK', 'Textiles', 20000, '2024-08-16', 'pending'),
('TRK-2024-1145', 'Monterrey Auto Parts SA', 'Agriculture', 60000, '2024-04-03', 'delivered'),
('TRK-2024-1063', 'Jakarta Rubber Corp', 'Electronics', 75000, '2024-04-13', 'delivered'),
('TRK-2024-1172', 'Sao Paulo Agro SA', 'Raw Material', 75000, '2024-08-16', 'pending'),
('TRK-2024-1129', 'Madrid Olive Oil SL', 'Textiles', 65000, '2024-08-15', 'delivered'),
('TRK-2024-1056', 'Osaka Components KK', 'Electronics', 55000, '2024-08-10', 'delivered'),
('TRK-2024-1099', 'Shenzhen Tech Imports', 'Machinery', 175000, '2024-07-11', 'in_transit'),
('TRK-2024-1041', 'Mumbai Textiles Ltd', 'Raw Material', 40000, '2024-04-04', 'pending'),
('TRK-2024-1095', 'Toronto Cold Chain Inc', 'Agriculture', 15000, '2024-05-23', 'in_transit'),
('TRK-2024-1006', 'Istanbul Textile Group', 'Electronics', 100000, '2024-09-11', 'in_transit'),
('TRK-2024-1010', 'Seoul Electronics Co', 'Agriculture', 30000, '2024-04-11', 'delivered'),
('TRK-2024-1102', 'Toronto Cold Chain Inc', 'Agriculture', 40000, '2024-02-12', 'delivered'),
('TRK-2024-1169', 'Shenzhen Tech Imports', 'Raw Material', 60000, '2024-03-11', 'in_transit'),
('TRK-2024-1179', 'Berlin Machinery GmbH', 'Machinery', 190000, '2024-09-15', 'delivered'),
('TRK-2024-1010', 'Seoul Electronics Co', 'Agriculture', 30000, '2024-04-11', 'delivered'),
('TRK-2024-1153', 'Monterrey Auto Parts SA', 'Electronics', 150000, '2024-04-21', 'in_transit'),
('TRK-2024-1176', 'Mumbai Textiles Ltd', 'Machinery', 135000, '2024-09-28', 'delivered'),
('TRK-2024-1003', 'Jakarta Rubber Corp', 'Electronics', 50000, '2024-10-26', 'delivered'),
('TRK-2024-1154', 'Berlin Machinery GmbH', 'Machinery', 195000, '2024-01-24', 'delivered'),
('TRK-2024-1168', 'Osaka Components KK', 'Agriculture', 45000, '2024-05-30', 'pending'),
('TRK-2024-1043', 'Istanbul Textile Group', 'Raw Material', 85000, '2024-01-30', 'pending'),
('TRK-2024-1165', 'Berlin Machinery GmbH', 'Machinery', 120000, '2024-04-28', 'pending'),
('TRK-2024-1148', 'Hanoi Garments JSC', 'Agriculture', 35000, '2024-05-30', 'delivered'),
('TRK-2024-1046', 'Madrid Olive Oil SL', 'Raw Material', 55000, '2024-01-22', 'delivered'),
('TRK-2024-1183', 'Sao Paulo Agro SA', 'Machinery', 145000, '2024-06-16', 'delivered'),
('TRK-2024-1150', 'Madrid Olive Oil SL', 'Textiles', 80000, '2024-03-17', 'delivered'),
('TRK-2024-1159', 'Hanoi Garments JSC', 'Raw Material', 95000, '2024-04-07', 'delivered'),
('TRK-2024-1062', 'Sao Paulo Agro SA', 'Agriculture', 45000, '2024-07-14', 'pending'),
('TRK-2024-1084', 'Mumbai Textiles Ltd', 'Agriculture', 40000, '2024-05-18', 'delivered'),
('TRK-2024-1083', 'Bangkok Rubber Exports', 'Agriculture', 55000, '2024-10-01', 'in_transit'),
('TRK-2024-1025', 'Milano Leather Works', 'Electronics', 120000, '2024-07-27', 'pending'),
('TRK-2024-1126', 'Istanbul Textile Group', 'Machinery', 180000, '2024-07-07', 'delivered'),
('TRK-2024-1048', 'Bangkok Rubber Exports', 'Raw Material', 65000, '2024-02-20', 'delivered'),
('TRK-2024-1152', 'Madrid Olive Oil SL', 'Electronics', 105000, '2024-08-05', 'delivered'),
('TRK-2024-1171', 'Osaka Components KK', 'Electronics', 60000, '2024-06-16', 'delivered'),
('TRK-2024-1024', 'Toronto Cold Chain Inc', 'Agriculture', 30000, '2024-05-05', 'delivered'),
('TRK-2024-1086', 'Mumbai Textiles Ltd', 'Electronics', 60000, '2024-09-19', 'delivered'),
('TRK-2024-1170', 'Monterrey Auto Parts SA', 'Electronics', 75000, '2024-02-26', 'pending'),
('TRK-2024-1110', 'Monterrey Auto Parts SA', 'Agriculture', 30000, '2024-09-01', 'delivered'),
('TRK-2024-1116', 'Milano Leather Works', 'Raw Material', 90000, '2024-09-04', 'in_transit'),
('TRK-2024-1050', 'Madrid Olive Oil SL', 'Machinery', 125000, '2024-09-26', 'pending'),
('TRK-2024-1053', 'Seoul Electronics Co', 'Electronics', 150000, '2024-08-17', 'delivered'),
('TRK-2024-1055', 'Toronto Cold Chain Inc', 'Raw Material', 60000, '2024-07-24', 'delivered'),
('TRK-2024-1149', 'Seoul Electronics Co', 'Machinery', 170000, '2024-09-06', 'delivered'),
('TRK-2024-1062', 'Sao Paulo Agro SA', 'Agriculture', 45000, '2024-07-14', 'pending'),
('TRK-2024-1132', 'Bangkok Rubber Exports', 'Agriculture', 55000, '2024-04-24', 'delivered'),
('TRK-2024-1147', 'Mumbai Textiles Ltd', 'Raw Material', 95000, '2024-05-28', 'delivered'),
('TRK-2024-1070', 'Hanoi Garments JSC', 'Machinery', 190000, '2024-03-21', 'pending'),
('TRK-2024-1065', 'Bangkok Rubber Exports', 'Raw Material', 50000, '2024-07-11', 'in_transit'),
('TRK-2024-1001', 'Milano Leather Works', 'Agriculture', 30000, '2024-08-31', 'pending'),
('TRK-2024-1089', 'Shenzhen Tech Imports', 'Agriculture', 25000, '2024-02-23', 'delivered'),
('TRK-2024-1076', 'Mumbai Textiles Ltd', 'Electronics', 135000, '2024-02-18', 'cancelled'),
('TRK-2024-1110', 'Monterrey Auto Parts SA', 'Agriculture', 30000, '2024-09-01', 'delivered'),
('TRK-2024-1026', 'Detroit Steel Supply', 'Agriculture', 15000, '2024-05-27', 'delivered'),
('TRK-2024-1008', 'Mumbai Textiles Ltd', 'Electronics', 120000, '2024-10-09', 'in_transit'),
('TRK-2024-1072', 'Mumbai Textiles Ltd', 'Machinery', 185000, '2024-07-15', 'in_transit'),
('TRK-2024-1037', 'Mumbai Textiles Ltd', 'Textiles', 30000, '2024-02-18', 'delivered'),
('TRK-2024-1014', 'Hanoi Garments JSC', 'Agriculture', 55000, '2024-06-11', 'cancelled'),
('TRK-2024-1181', 'Detroit Steel Supply', 'Textiles', 30000, '2024-06-14', 'in_transit'),
('TRK-2024-1082', 'Hanoi Garments JSC', 'Electronics', 60000, '2024-04-06', 'delivered'),
('TRK-2024-1177', 'Osaka Components KK', 'Machinery', 110000, '2024-03-23', 'pending'),
('TRK-2024-1011', 'Seoul Electronics Co', 'Raw Material', 85000, '2024-03-03', 'in_transit'),
('TRK-2024-1032', 'Hanoi Garments JSC', 'Raw Material', 90000, '2024-09-05', 'in_transit'),
('TRK-2024-1064', 'Seoul Electronics Co', 'Agriculture', 25000, '2024-10-10', 'delivered'),
('TRK-2024-1031', 'Milano Leather Works', 'Textiles', 45000, '2024-03-19', 'pending'),
('TRK-2024-1034', 'Madrid Olive Oil SL', 'Textiles', 80000, '2024-01-06', 'delivered'),
('TRK-2024-1068', 'Shenzhen Tech Imports', 'Machinery', 90000, '2024-06-13', 'delivered'),
('TRK-2024-1163', 'Sao Paulo Agro SA', 'Textiles', 75000, '2024-06-16', 'in_transit'),
('TRK-2024-1054', 'Madrid Olive Oil SL', 'Electronics', 150000, '2024-08-14', 'delivered'),
('TRK-2024-1151', 'Sao Paulo Agro SA', 'Agriculture', 20000, '2024-08-14', 'pending'),
('TRK-2024-1096', 'Milano Leather Works', 'Textiles', 70000, '2024-09-30', 'in_transit'),
('TRK-2024-1106', 'Istanbul Textile Group', 'Textiles', 60000, '2024-07-08', 'pending'),
('TRK-2024-1033', 'Mumbai Textiles Ltd', 'Agriculture', 35000, '2024-09-30', 'in_transit'),
('TRK-2024-1174', 'Sao Paulo Agro SA', 'Raw Material', 35000, '2024-06-27', 'delivered'),
('TRK-2024-1092', 'Istanbul Textile Group', 'Textiles', 35000, '2024-01-21', 'in_transit'),
('TRK-2024-1118', 'Hanoi Garments JSC', 'Agriculture', 40000, '2024-10-15', 'in_transit'),
('TRK-2024-1048', 'Bangkok Rubber Exports', 'Raw Material', 65000, '2024-02-20', 'delivered'),
('TRK-2024-1115', 'Monterrey Auto Parts SA', 'Agriculture', 30000, '2024-04-26', 'pending'),
('TRK-2024-1122', 'Madrid Olive Oil SL', 'Machinery', 90000, '2024-06-06', 'delivered'),
('TRK-2024-1128', 'Seoul Electronics Co', 'Agriculture', 15000, '2024-09-18', 'delivered'),
('TRK-2024-1069', 'Istanbul Textile Group', 'Textiles', 70000, '2024-04-12', 'delivered'),
('TRK-2024-1022', 'Toronto Cold Chain Inc', 'Textiles', 50000, '2024-03-24', 'cancelled'),
('TRK-2024-1085', 'Osaka Components KK', 'Machinery', 125000, '2024-01-05', 'pending'),
('TRK-2024-1052', 'Jakarta Rubber Corp', 'Machinery', 90000, '2024-08-03', 'delivered'),
('TRK-2024-1166', 'Detroit Steel Supply', 'Electronics', 80000, '2024-07-12', 'cancelled'),
('TRK-2024-1058', 'Hanoi Garments JSC', 'Agriculture', 30000, '2024-07-16', 'delivered'),
('TRK-2024-1107', 'Seoul Electronics Co', 'Raw Material', 50000, '2024-03-23', 'delivered'),
('TRK-2024-1123', 'Milano Leather Works', 'Textiles', 30000, '2024-05-15', 'delivered'),
('TRK-2024-1081', 'Monterrey Auto Parts SA', 'Raw Material', 100000, '2024-01-10', 'in_transit'),
('TRK-2024-1156', 'Istanbul Textile Group', 'Electronics', 115000, '2024-04-12', 'delivered'),
('TRK-2024-1049', 'Bangkok Rubber Exports', 'Electronics', 130000, '2024-06-14', 'cancelled'),
('TRK-2024-1071', 'Hanoi Garments JSC', 'Agriculture', 45000, '2024-08-23', 'in_transit'),
('TRK-2024-1121', 'Toronto Cold Chain Inc', 'Agriculture', 20000, '2024-04-11', 'in_transit'),
('TRK-2024-1143', 'Sao Paulo Agro SA', 'Electronics', 110000, '2024-06-11', 'pending'),
('TRK-2024-1131', 'Jakarta Rubber Corp', 'Machinery', 100000, '2024-07-24', 'pending'),
('TRK-2024-1074', 'Seoul Electronics Co', 'Machinery', 80000, '2024-09-13', 'in_transit'),
('TRK-2024-1120', 'Osaka Components KK', 'Electronics', 105000, '2024-05-08', 'in_transit'),
('TRK-2024-1087', 'Sao Paulo Agro SA', 'Textiles', 45000, '2024-06-29', 'delivered'),
('TRK-2024-1117', 'Toronto Cold Chain Inc', 'Electronics', 105000, '2024-03-08', 'delivered'),
('TRK-2024-1061', 'Madrid Olive Oil SL', 'Raw Material', 80000, '2024-05-14', 'delivered'),
('TRK-2024-1051', 'Bangkok Rubber Exports', 'Textiles', 25000, '2024-06-15', 'cancelled'),
('TRK-2024-1020', 'Toronto Cold Chain Inc', 'Textiles', 25000, '2024-03-30', 'pending'),
('TRK-2024-1013', 'Hanoi Garments JSC', 'Textiles', 60000, '2024-05-29', 'delivered'),
('TRK-2024-1130', 'Jakarta Rubber Corp', 'Raw Material', 70000, '2024-08-09', 'in_transit'),
('TRK-2024-1136', 'Berlin Machinery GmbH', 'Machinery', 125000, '2024-01-25', 'delivered'),
('TRK-2024-1094', 'Monterrey Auto Parts SA', 'Machinery', 155000, '2024-03-23', 'pending'),
('TRK-2024-1029', 'Madrid Olive Oil SL', 'Textiles', 30000, '2024-09-02', 'delivered'),
('TRK-2024-1137', 'Shenzhen Tech Imports', 'Textiles', 30000, '2024-03-21', 'pending'),
('TRK-2024-1100', 'Toronto Cold Chain Inc', 'Textiles', 30000, '2024-10-01', 'delivered'),
('TRK-2024-1090', 'Sao Paulo Agro SA', 'Machinery', 165000, '2024-07-28', 'delivered'),
('TRK-2024-1066', 'Mumbai Textiles Ltd', 'Agriculture', 20000, '2024-08-09', 'delivered'),
('TRK-2024-1077', 'Jakarta Rubber Corp', 'Textiles', 55000, '2024-01-02', 'delivered'),
('TRK-2024-1080', 'Berlin Machinery GmbH', 'Raw Material', 45000, '2024-10-21', 'pending'),
('TRK-2024-1105', 'Shenzhen Tech Imports', 'Raw Material', 90000, '2024-04-17', 'in_transit'),
('TRK-2024-1040', 'Hanoi Garments JSC', 'Raw Material', 55000, '2024-09-09', 'pending'),
('TRK-2024-1180', 'Jakarta Rubber Corp', 'Electronics', 75000, '2024-10-20', 'in_transit'),
('TRK-2024-1017', 'Bangkok Rubber Exports', 'Raw Material', 45000, '2024-06-12', 'in_transit'),
('TRK-2024-1077', 'Jakarta Rubber Corp', 'Textiles', 55000, '2024-01-02', 'delivered'),
('TRK-2024-1057', 'Bangkok Rubber Exports', 'Machinery', 190000, '2024-07-26', 'in_transit'),
('TRK-2024-1076', 'Mumbai Textiles Ltd', 'Electronics', 135000, '2024-02-18', 'cancelled'),
('TRK-2024-1144', 'Shenzhen Tech Imports', 'Machinery', 145000, '2024-10-22', 'delivered'),
('TRK-2024-1046', 'Madrid Olive Oil SL', 'Raw Material', 55000, '2024-01-22', 'delivered'),
('TRK-2024-1067', 'Osaka Components KK', 'Machinery', 135000, '2024-10-24', 'in_transit'),
('TRK-2024-1125', 'Milano Leather Works', 'Textiles', 55000, '2024-09-10', 'delivered'),
('TRK-2024-1175', 'Monterrey Auto Parts SA', 'Agriculture', 35000, '2024-06-09', 'pending'),
('TRK-2024-1101', 'Berlin Machinery GmbH', 'Agriculture', 30000, '2024-09-20', 'in_transit'),
('TRK-2024-1155', 'Jakarta Rubber Corp', 'Machinery', 175000, '2024-08-10', 'delivered'),
('TRK-2024-1093', 'Osaka Components KK', 'Raw Material', 70000, '2024-03-30', 'delivered'),
('TRK-2024-1104', 'Mumbai Textiles Ltd', 'Machinery', 170000, '2024-01-14', 'pending'),
('TRK-2024-1146', 'Milano Leather Works', 'Electronics', 90000, '2024-08-29', 'in_transit'),
('TRK-2024-1023', 'Toronto Cold Chain Inc', 'Raw Material', 30000, '2024-06-26', 'delivered'),
('TRK-2024-1117', 'Toronto Cold Chain Inc', 'Electronics', 105000, '2024-03-08', 'delivered'),
('TRK-2024-1016', 'Monterrey Auto Parts SA', 'Agriculture', 15000, '2024-02-05', 'in_transit'),
('TRK-2024-1161', 'Jakarta Rubber Corp', 'Agriculture', 25000, '2024-07-07', 'pending'),
('TRK-2024-1000', 'Madrid Olive Oil SL', 'Textiles', 50000, '2024-08-02', 'in_transit'),
('TRK-2024-1162', 'Osaka Components KK', 'Textiles', 40000, '2024-02-10', 'pending'),
('TRK-2024-1036', 'Hanoi Garments JSC', 'Textiles', 65000, '2024-05-11', 'in_transit'),
('TRK-2024-1133', 'Detroit Steel Supply', 'Textiles', 20000, '2024-08-20', 'pending'),
('TRK-2024-1079', 'Berlin Machinery GmbH', 'Electronics', 95000, '2024-08-01', 'delivered'),
('TRK-2024-1007', 'Mumbai Textiles Ltd', 'Machinery', 80000, '2024-02-15', 'delivered'),
('TRK-2024-1002', 'Istanbul Textile Group', 'Raw Material', 40000, '2024-09-27', 'delivered'),
('TRK-2024-1182', 'Milano Leather Works', 'Textiles', 65000, '2024-04-11', 'delivered'),
('TRK-2024-1030', 'Istanbul Textile Group', 'Textiles', 70000, '2024-09-02', 'delivered'),
('TRK-2024-1140', 'Madrid Olive Oil SL', 'Textiles', 75000, '2024-04-16', 'delivered'),
('TRK-2024-1042', 'Madrid Olive Oil SL', 'Textiles', 75000, '2024-10-08', 'pending'),
('TRK-2024-1021', 'Osaka Components KK', 'Machinery', 105000, '2024-01-19', 'in_transit'),
('TRK-2024-1142', 'Bangkok Rubber Exports', 'Textiles', 50000, '2024-09-23', 'in_transit'),
('TRK-2024-1182', 'Milano Leather Works', 'Textiles', 65000, '2024-04-11', 'delivered'),
('TRK-2024-1021', 'Osaka Components KK', 'Machinery', 105000, '2024-01-19', 'in_transit'),
('TRK-2024-1124', 'Osaka Components KK', 'Raw Material', 50000, '2024-04-21', 'delivered'),
('TRK-2024-1097', 'Hanoi Garments JSC', 'Electronics', 95000, '2024-04-17', 'pending'),
('TRK-2024-1012', 'Hanoi Garments JSC', 'Raw Material', 95000, '2024-04-12', 'delivered'),
('TRK-2024-1112', 'Monterrey Auto Parts SA', 'Machinery', 170000, '2024-06-03', 'in_transit'),
('TRK-2024-1157', 'Mumbai Textiles Ltd', 'Textiles', 35000, '2024-06-21', 'delivered'),
('TRK-2024-1184', 'Milano Leather Works', 'Agriculture', 45000, '2024-05-31', 'in_transit'),
('TRK-2024-1047', 'Madrid Olive Oil SL', 'Textiles', 40000, '2024-05-31', 'pending');
-- ============================================================
-- 3. CONSULTAS CON WINDOW FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 1 — ROW_NUMBER(): eliminar duplicados correctamente
-- ROW_NUMBER() asigna un número secuencial (1, 2, 3...) a cada
-- fila DENTRO de cada grupo definido por PARTITION BY. Aquí
-- agrupamos por todas las columnas que definen un envío único
-- (tracking_code, supplier_name, category, total_value, ship_date,
-- status). Si un envío está duplicado, sus copias recibirán
-- rn = 1, 2, 3... en ese grupo. Nos quedamos solo con rn = 1
-- para eliminar los duplicados y conservar una sola copia limpia.
-- ------------------------------------------------------------
WITH envios_numerados AS (
    SELECT
        raw_id,
        tracking_code,
        supplier_name,
        category,
        total_value,
        ship_date,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY tracking_code, supplier_name, category,
                         total_value, ship_date, status
            ORDER BY raw_id
        ) AS rn
    FROM shipments_raw
)
SELECT
    raw_id,
    tracking_code,
    supplier_name,
    category,
    total_value,
    ship_date,
    status
FROM envios_numerados
WHERE rn = 1
ORDER BY raw_id;

-- ------------------------------------------------------------
-- CONSULTA 1b — Evidencia de los duplicados detectados
-- Muestra únicamente las filas que ROW_NUMBER() identificó como
-- copias repetidas (rn > 1), para comprobar visualmente que la
-- limpieza de la consulta 1 sí está funcionando.
-- ------------------------------------------------------------
WITH envios_numerados AS (
    SELECT
        raw_id,
        tracking_code,
        total_value,
        ROW_NUMBER() OVER (
            PARTITION BY tracking_code, supplier_name, category,
                         total_value, ship_date, status
            ORDER BY raw_id
        ) AS rn
    FROM shipments_raw
)
SELECT
    raw_id,
    tracking_code,
    total_value,
    rn AS copia_numero
FROM envios_numerados
WHERE rn > 1
ORDER BY tracking_code;

-- ------------------------------------------------------------
-- CONSULTA 2 — RANK() y DENSE_RANK() por categoría, con empates
-- Trabajamos sobre los envíos YA DEDUPLICADOS (rn = 1 del CTE
-- anterior). Dentro de cada categoría (PARTITION BY category),
-- clasificamos los envíos de mayor a menor valor. RANK() deja
-- "huecos" en la numeración cuando hay empate (ej. 1,1,3), mientras
-- que DENSE_RANK() no deja huecos (ej. 1,1,2). La diferencia entre
-- ambas columnas es visible porque los datos tienen empates reales.
-- ------------------------------------------------------------
WITH envios_limpios AS (
    SELECT DISTINCT ON (tracking_code, supplier_name, category, total_value, ship_date, status)
        raw_id, supplier_name, category, total_value
    FROM shipments_raw
)
SELECT
    el.category                AS categoria,
    el.supplier_name           AS proveedor,
    el.total_value             AS valor_envio,
    RANK() OVER (
        PARTITION BY el.category ORDER BY el.total_value DESC
    )                          AS posicion_rank,
    DENSE_RANK() OVER (
        PARTITION BY el.category ORDER BY el.total_value DESC
    )                          AS posicion_dense_rank
FROM envios_limpios AS el
ORDER BY el.category, posicion_rank;

-- ------------------------------------------------------------
-- CONSULTA 3 — CTE + Top-N por grupo (Top 3 envíos por categoría)
-- El CTE "ranking_categoria" deduplica y calcula el ROW_NUMBER()
-- de cada envío dentro de su categoría, ordenado por valor
-- descendente (usamos ROW_NUMBER aquí para que el Top-N tenga
-- EXACTAMENTE 3 filas por categoría, sin duplicarse por empates
-- como podría pasar con RANK). La consulta exterior filtra
-- únicamente las primeras 3 posiciones de cada categoría.
-- ------------------------------------------------------------
WITH envios_limpios AS (
    SELECT DISTINCT ON (tracking_code, supplier_name, category, total_value, ship_date, status)
        raw_id, tracking_code, supplier_name, category, total_value, status
    FROM shipments_raw
),
ranking_categoria AS (
    SELECT
        tracking_code,
        supplier_name,
        category,
        total_value,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY category ORDER BY total_value DESC
        ) AS posicion
    FROM envios_limpios
)
SELECT
    category                   AS categoria,
    posicion                   AS top_n,
    supplier_name              AS proveedor,
    total_value                AS valor_envio,
    status                     AS estado
FROM ranking_categoria
WHERE posicion <= 3
ORDER BY categoria, top_n;