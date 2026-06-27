--  PROYECTO — SEMANA 15: Análisis temporal con Window Functions y Vistas
--  Motor: PostgreSQL
--  Dominio: Empresa de Importación (bc-sql)
--  Tabla principal: monthly_shipments (resumen mensual de
--                    importaciones, por categoría)


-- ------------------------------------------------------------
-- 0. LIMPIAR OBJETOS SI EXISTEN (para poder re-ejecutar el script)
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_tendencia_mensual_categoria;
DROP TABLE IF EXISTS monthly_shipments;

-- ============================================================
-- 1. ESQUEMA (DDL)
-- ============================================================

-- monthly_shipments: una fila por (categoría, mes), con el total
-- de envíos y el valor total importado en ese mes. Es el resumen
-- temporal sobre el que se aplican las funciones de ventana.
CREATE TABLE monthly_shipments (
    monthly_id        SERIAL PRIMARY KEY,
    category          TEXT    NOT NULL
                              CHECK (category IN (
                                  'Electronics','Textiles','Machinery',
                                  'Agriculture','Raw Material'
                              )),
    period_month      DATE    NOT NULL,   -- primer día del mes (ej. 2021-01-01)
    total_shipments   INTEGER NOT NULL CHECK (total_shipments > 0),
    total_value        NUMERIC NOT NULL CHECK (total_value > 0)
);

-- ============================================================
-- 2. DATOS DE PRUEBA (DML)
--    200 filas: 5 categorías x 40 meses consecutivos
--    (enero 2021 a abril 2024 → más de 3 años de historia,
--    superando los 12 meses mínimos exigidos).
--    Cada categoría tiene una tendencia de crecimiento distinta;
--    "Agriculture" tiene tendencia DECRECIENTE a propósito, para
--    que LAG()/LEAD() también muestren caídas reales, no solo
--    crecimiento.
-- ============================================================

INSERT INTO monthly_shipments (category, period_month, total_shipments, total_value) VALUES
('Electronics', '2021-01-01', 23, 823402.04),
('Electronics', '2021-02-01', 11, 803076.22),
('Electronics', '2021-03-01', 20, 814829.03),
('Electronics', '2021-04-01', 8, 882796.01),
('Electronics', '2021-05-01', 22, 966376.4),
('Electronics', '2021-06-01', 13, 1052346.3),
('Electronics', '2021-07-01', 19, 1149784.81),
('Electronics', '2021-08-01', 12, 1166979.17),
('Electronics', '2021-09-01', 23, 1270805.05),
('Electronics', '2021-10-01', 16, 1206405.23),
('Electronics', '2021-11-01', 18, 1191302.85),
('Electronics', '2021-12-01', 22, 1288771.6),
('Electronics', '2022-01-01', 24, 1386170.12),
('Electronics', '2022-02-01', 11, 1394740.38),
('Electronics', '2022-03-01', 20, 1515354.08),
('Electronics', '2022-04-01', 10, 1606823.48),
('Electronics', '2022-05-01', 4, 1537346.31),
('Electronics', '2022-06-01', 12, 1520573.88),
('Electronics', '2022-07-01', 5, 1668424.72),
('Electronics', '2022-08-01', 6, 1765145.08),
('Electronics', '2022-09-01', 10, 1840272.87),
('Electronics', '2022-10-01', 13, 1877164.76),
('Electronics', '2022-11-01', 19, 1762694.62),
('Electronics', '2022-12-01', 20, 1839125.93),
('Electronics', '2023-01-01', 8, 1841100.25),
('Electronics', '2023-02-01', 4, 1929446.87),
('Electronics', '2023-03-01', 23, 1922370.72),
('Electronics', '2023-04-01', 20, 2033059.18),
('Electronics', '2023-05-01', 5, 2184176.33),
('Electronics', '2023-06-01', 6, 2100810.56),
('Electronics', '2023-07-01', 3, 2242207.02),
('Electronics', '2023-08-01', 11, 2123853.32),
('Electronics', '2023-09-01', 9, 2110487.66),
('Electronics', '2023-10-01', 15, 2208173.4),
('Electronics', '2023-11-01', 18, 2233010.76),
('Electronics', '2023-12-01', 21, 2376710.69),
('Electronics', '2024-01-01', 12, 2434327.47),
('Electronics', '2024-02-01', 3, 2472734.0),
('Electronics', '2024-03-01', 15, 2509793.79),
('Electronics', '2024-04-01', 14, 2658525.91),
('Textiles', '2021-01-01', 10, 282827.61),
('Textiles', '2021-02-01', 20, 262286.49),
('Textiles', '2021-03-01', 13, 269250.52),
('Textiles', '2021-04-01', 25, 286649.72),
('Textiles', '2021-05-01', 18, 304742.77),
('Textiles', '2021-06-01', 18, 317450.12),
('Textiles', '2021-07-01', 5, 295343.11),
('Textiles', '2021-08-01', 12, 315039.94),
('Textiles', '2021-09-01', 16, 314734.43),
('Textiles', '2021-10-01', 16, 338808.64),
('Textiles', '2021-11-01', 22, 327524.21),
('Textiles', '2021-12-01', 18, 353359.45),
('Textiles', '2022-01-01', 15, 348783.88),
('Textiles', '2022-02-01', 13, 340350.26),
('Textiles', '2022-03-01', 8, 323953.7),
('Textiles', '2022-04-01', 13, 347083.21),
('Textiles', '2022-05-01', 12, 355594.73),
('Textiles', '2022-06-01', 8, 380567.05),
('Textiles', '2022-07-01', 14, 398341.7),
('Textiles', '2022-08-01', 16, 421448.63),
('Textiles', '2022-09-01', 13, 452603.13),
('Textiles', '2022-10-01', 14, 485672.85),
('Textiles', '2022-11-01', 21, 507566.06),
('Textiles', '2022-12-01', 4, 522847.1),
('Textiles', '2023-01-01', 23, 554762.85),
('Textiles', '2023-02-01', 3, 592722.63),
('Textiles', '2023-03-01', 5, 569883.02),
('Textiles', '2023-04-01', 21, 599813.25),
('Textiles', '2023-05-01', 6, 562330.78),
('Textiles', '2023-06-01', 9, 538027.19),
('Textiles', '2023-07-01', 22, 514811.17),
('Textiles', '2023-08-01', 24, 482089.97),
('Textiles', '2023-09-01', 21, 505483.36),
('Textiles', '2023-10-01', 19, 502735.39),
('Textiles', '2023-11-01', 3, 519708.97),
('Textiles', '2023-12-01', 7, 552123.58),
('Textiles', '2024-01-01', 5, 547235.31),
('Textiles', '2024-02-01', 7, 577449.59),
('Textiles', '2024-03-01', 3, 576362.94),
('Textiles', '2024-04-01', 9, 587372.33),
('Machinery', '2021-01-01', 10, 635177.93),
('Machinery', '2021-02-01', 13, 660664.9),
('Machinery', '2021-03-01', 18, 654480.72),
('Machinery', '2021-04-01', 3, 700773.55),
('Machinery', '2021-05-01', 3, 737740.41),
('Machinery', '2021-06-01', 18, 782624.11),
('Machinery', '2021-07-01', 22, 837406.74),
('Machinery', '2021-08-01', 19, 824537.53),
('Machinery', '2021-09-01', 13, 785383.04),
('Machinery', '2021-10-01', 15, 744276.09),
('Machinery', '2021-11-01', 17, 752697.67),
('Machinery', '2021-12-01', 5, 734172.31),
('Machinery', '2022-01-01', 7, 746255.75),
('Machinery', '2022-02-01', 8, 726360.08),
('Machinery', '2022-03-01', 7, 725141.37),
('Machinery', '2022-04-01', 18, 691758.59),
('Machinery', '2022-05-01', 17, 705013.53),
('Machinery', '2022-06-01', 10, 693599.17),
('Machinery', '2022-07-01', 3, 647231.34),
('Machinery', '2022-08-01', 13, 611364.31),
('Machinery', '2022-09-01', 11, 587999.25),
('Machinery', '2022-10-01', 22, 570354.59),
('Machinery', '2022-11-01', 3, 607652.42),
('Machinery', '2022-12-01', 22, 614534.69),
('Machinery', '2023-01-01', 12, 610402.52),
('Machinery', '2023-02-01', 11, 662410.19),
('Machinery', '2023-03-01', 4, 641155.36),
('Machinery', '2023-04-01', 15, 626890.01),
('Machinery', '2023-05-01', 14, 682391.21),
('Machinery', '2023-06-01', 9, 645008.33),
('Machinery', '2023-07-01', 15, 667713.36),
('Machinery', '2023-08-01', 15, 657710.96),
('Machinery', '2023-09-01', 10, 617340.27),
('Machinery', '2023-10-01', 7, 641794.92),
('Machinery', '2023-11-01', 15, 651137.58),
('Machinery', '2023-12-01', 5, 671074.9),
('Machinery', '2024-01-01', 18, 716244.93),
('Machinery', '2024-02-01', 9, 689150.99),
('Machinery', '2024-03-01', 16, 738577.9),
('Machinery', '2024-04-01', 25, 789695.86),
('Agriculture', '2021-01-01', 15, 240358.55),
('Agriculture', '2021-02-01', 23, 255067.19),
('Agriculture', '2021-03-01', 21, 251393.87),
('Agriculture', '2021-04-01', 15, 257156.22),
('Agriculture', '2021-05-01', 17, 268519.92),
('Agriculture', '2021-06-01', 6, 273396.37),
('Agriculture', '2021-07-01', 17, 266568.77),
('Agriculture', '2021-08-01', 9, 250926.87),
('Agriculture', '2021-09-01', 6, 262978.41),
('Agriculture', '2021-10-01', 15, 247787.41),
('Agriculture', '2021-11-01', 8, 240036.43),
('Agriculture', '2021-12-01', 7, 251919.65),
('Agriculture', '2022-01-01', 6, 261314.14),
('Agriculture', '2022-02-01', 19, 272692.44),
('Agriculture', '2022-03-01', 7, 267858.25),
('Agriculture', '2022-04-01', 21, 284687.98),
('Agriculture', '2022-05-01', 15, 283578.94),
('Agriculture', '2022-06-01', 21, 304800.16),
('Agriculture', '2022-07-01', 15, 305089.46),
('Agriculture', '2022-08-01', 6, 279633.5),
('Agriculture', '2022-09-01', 17, 291511.79),
('Agriculture', '2022-10-01', 19, 290046.49),
('Agriculture', '2022-11-01', 8, 305232.82),
('Agriculture', '2022-12-01', 20, 305971.71),
('Agriculture', '2023-01-01', 22, 301456.01),
('Agriculture', '2023-02-01', 24, 298236.79),
('Agriculture', '2023-03-01', 11, 284444.14),
('Agriculture', '2023-04-01', 8, 261188.04),
('Agriculture', '2023-05-01', 12, 275124.73),
('Agriculture', '2023-06-01', 3, 294619.13),
('Agriculture', '2023-07-01', 12, 313657.69),
('Agriculture', '2023-08-01', 9, 327676.94),
('Agriculture', '2023-09-01', 4, 316192.6),
('Agriculture', '2023-10-01', 10, 331279.31),
('Agriculture', '2023-11-01', 16, 316807.48),
('Agriculture', '2023-12-01', 14, 334345.12),
('Agriculture', '2024-01-01', 6, 325016.97),
('Agriculture', '2024-02-01', 16, 307975.11),
('Agriculture', '2024-03-01', 20, 297707.45),
('Agriculture', '2024-04-01', 23, 307311.17),
('Raw Material', '2021-01-01', 23, 423926.46),
('Raw Material', '2021-02-01', 21, 444144.82),
('Raw Material', '2021-03-01', 23, 435504.08),
('Raw Material', '2021-04-01', 3, 422433.94),
('Raw Material', '2021-05-01', 6, 411568.35),
('Raw Material', '2021-06-01', 19, 393994.93),
('Raw Material', '2021-07-01', 3, 422386.44),
('Raw Material', '2021-08-01', 12, 449391.56),
('Raw Material', '2021-09-01', 16, 421524.4),
('Raw Material', '2021-10-01', 13, 426108.83),
('Raw Material', '2021-11-01', 16, 456979.75),
('Raw Material', '2021-12-01', 24, 485050.37),
('Raw Material', '2022-01-01', 11, 477752.65),
('Raw Material', '2022-02-01', 4, 470174.42),
('Raw Material', '2022-03-01', 20, 481139.17),
('Raw Material', '2022-04-01', 24, 488846.42),
('Raw Material', '2022-05-01', 17, 460653.44),
('Raw Material', '2022-06-01', 5, 500330.68),
('Raw Material', '2022-07-01', 22, 490346.8),
('Raw Material', '2022-08-01', 8, 481223.04),
('Raw Material', '2022-09-01', 7, 476422.89),
('Raw Material', '2022-10-01', 7, 496635.31),
('Raw Material', '2022-11-01', 17, 517874.84),
('Raw Material', '2022-12-01', 14, 547698.35),
('Raw Material', '2023-01-01', 12, 539023.11),
('Raw Material', '2023-02-01', 24, 524954.67),
('Raw Material', '2023-03-01', 12, 536616.64),
('Raw Material', '2023-04-01', 5, 511576.47),
('Raw Material', '2023-05-01', 21, 508718.2),
('Raw Material', '2023-06-01', 8, 541750.48),
('Raw Material', '2023-07-01', 18, 577943.92),
('Raw Material', '2023-08-01', 16, 597097.35),
('Raw Material', '2023-09-01', 23, 576972.21),
('Raw Material', '2023-10-01', 21, 615555.94),
('Raw Material', '2023-11-01', 20, 587482.69),
('Raw Material', '2023-12-01', 24, 628645.12),
('Raw Material', '2024-01-01', 6, 647682.46),
('Raw Material', '2024-02-01', 23, 602263.71),
('Raw Material', '2024-03-01', 8, 617663.31),
('Raw Material', '2024-04-01', 11, 606493.41);
-- ============================================================
-- 3. CONSULTAS CON WINDOW FUNCTIONS TEMPORALES
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 1 — LAG() / LEAD(): variación mes a mes (delta)
-- LAG() trae el valor del mes ANTERIOR dentro de la misma
-- categoría (PARTITION BY category, ordenado por period_month).
-- LEAD() trae el valor del mes SIGUIENTE. Con ambos calculamos
-- el delta (diferencia) y el porcentaje de variación respecto
-- al mes anterior, que es la base de cualquier reporte de
-- tendencia temporal.
-- ------------------------------------------------------------
SELECT
    category                                   AS categoria,
    period_month                                AS mes,
    total_value                                 AS valor_mes_actual,
    LAG(total_value) OVER (
        PARTITION BY category ORDER BY period_month
    )                                            AS valor_mes_anterior,
    total_value - LAG(total_value) OVER (
        PARTITION BY category ORDER BY period_month
    )                                            AS delta_valor,
    ROUND(
        100.0 * (total_value - LAG(total_value) OVER (
            PARTITION BY category ORDER BY period_month
        )) / LAG(total_value) OVER (
            PARTITION BY category ORDER BY period_month
        ), 2
    )                                            AS variacion_porcentual,
    LEAD(total_value) OVER (
        PARTITION BY category ORDER BY period_month
    )                                            AS valor_mes_siguiente
FROM monthly_shipments
ORDER BY category, period_month;

-- ------------------------------------------------------------
-- CONSULTA 2 — FIRST_VALUE() / LAST_VALUE() con frame correcto
-- FIRST_VALUE() trae el valor del PRIMER mes de la serie de cada
-- categoría. LAST_VALUE() necesita un FRAME explícito
-- (RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
-- para "ver" toda la partición completa; sin ese frame, por
-- defecto solo vería hasta la fila actual y devolvería el mismo
-- valor que la fila actual en cada caso. Con esto comparamos el
-- valor inicial contra el valor final de cada categoría a lo
-- largo de los 40 meses, para medir el crecimiento total.
-- ------------------------------------------------------------
SELECT DISTINCT
    category                                   AS categoria,
    FIRST_VALUE(total_value) OVER (
        PARTITION BY category ORDER BY period_month
    )                                            AS valor_primer_mes,
    LAST_VALUE(total_value) OVER (
        PARTITION BY category ORDER BY period_month
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                            AS valor_ultimo_mes,
    ROUND(
        100.0 * (
            LAST_VALUE(total_value) OVER (
                PARTITION BY category ORDER BY period_month
                RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) - FIRST_VALUE(total_value) OVER (
                PARTITION BY category ORDER BY period_month
            )
        ) / FIRST_VALUE(total_value) OVER (
            PARTITION BY category ORDER BY period_month
        ), 2
    )                                            AS crecimiento_total_porcentual
FROM monthly_shipments
ORDER BY crecimiento_total_porcentual DESC;

-- ------------------------------------------------------------
-- CONSULTA 3 — Vista reutilizable + consulta con WHERE
-- Encapsulamos el análisis de tendencia mensual (LAG + delta +
-- variación porcentual) dentro de una VISTA, para no tener que
-- repetir la misma lógica de window functions cada vez que se
-- necesite este reporte. La vista queda disponible como si
-- fuera una tabla más.
-- ------------------------------------------------------------
CREATE VIEW vw_tendencia_mensual_categoria AS
SELECT
    category                                   AS categoria,
    period_month                                AS mes,
    total_shipments                             AS total_envios,
    total_value                                 AS valor_mes,
    LAG(total_value) OVER (
        PARTITION BY category ORDER BY period_month
    )                                            AS valor_mes_anterior,
    ROUND(
        100.0 * (total_value - LAG(total_value) OVER (
            PARTITION BY category ORDER BY period_month
        )) / LAG(total_value) OVER (
            PARTITION BY category ORDER BY period_month
        ), 2
    )                                            AS variacion_porcentual
FROM monthly_shipments;

-- Consulta de evidencia: usamos la vista con un filtro WHERE para
-- encontrar los meses en los que una categoría tuvo una CAÍDA
-- (variación negativa) respecto al mes anterior.
SELECT
    categoria,
    mes,
    valor_mes,
    valor_mes_anterior,
    variacion_porcentual
FROM vw_tendencia_mensual_categoria
WHERE variacion_porcentual < 0
ORDER BY variacion_porcentual ASC
LIMIT 15;

-- Segunda consulta de evidencia sobre la misma vista: solo la
-- categoría "Agriculture" (la de tendencia decreciente diseñada
-- a propósito), para visualizar su caída mes a mes.
SELECT
    categoria,
    mes,
    valor_mes,
    valor_mes_anterior,
    variacion_porcentual
FROM vw_tendencia_mensual_categoria
WHERE categoria = 'Agriculture'
ORDER BY mes;