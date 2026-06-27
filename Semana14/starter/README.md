# Semana 14 — Proyecto: Ranking con Window Functions

**Dominio asignado:** Empresa de Importación (bc-sql)
**Motor de base de datos:** PostgreSQL

---

## 📋 Descripción

Este proyecto aplica `ROW_NUMBER()`, `RANK()` y `DENSE_RANK()` sobre una
tabla de envíos "cruda" (`shipments_raw`) que simula un escenario real de
importación de datos desde varios sistemas: contiene **duplicados exactos**
por error de doble carga y **valores con empates reales** dentro de cada
categoría, para que las funciones de ranking se comporten de forma
distinguible entre sí.

---

## 🗂️ Estructura del esquema

| Tabla            | Rol               | Filas | Particularidad                                              |
|------------------|-------------------|-------|----------------------------------------------------------------|
| `shipments_raw`  | **Principal**     | 200   | 185 envíos únicos + 15 copias exactas duplicadas (a propósito) |

`total_value` se generó en múltiplos de 5.000 dentro de un rango por
categoría, para forzar **empates reales** entre envíos de la misma categoría.

---

## 🪟 Consultas con Window Functions incluidas

| # | Consulta | Función | Propósito |
|---|----------|---------|-----------|
| 1 | Deduplicar envíos | `ROW_NUMBER()` particionado por todas las columnas | Conserva solo `rn = 1`, eliminando las 15 copias duplicadas |
| 1b | Evidencia de duplicados | `ROW_NUMBER()` | Muestra únicamente las filas con `rn > 1` (las que se eliminaron) |
| 2 | Ranking por categoría | `RANK()` y `DENSE_RANK()` | Compara ambas funciones lado a lado sobre los mismos empates reales |
| 3 | Top 3 por categoría | CTE encadenado + `ROW_NUMBER()` | Filtra exactamente 3 envíos por categoría, sin duplicarse por empates |

---

## ✔️ Evidencia de resultados (ya validada)

| Verificación | Resultado obtenido |
|---|---|
| Total de filas cargadas en `shipments_raw` | 200 |
| Filas tras deduplicar con `ROW_NUMBER()` (Consulta 1) | **185** |
| Duplicados detectados (Consulta 1b) | **15** |
| Ejemplo de empate real en Electronics (valor = 150.000) | 4 proveedores empatados |

**Diferencia visible entre RANK() y DENSE_RANK()** (categoría Electronics,
después de deduplicar):

| proveedor | valor | RANK() | DENSE_RANK() |
|---|---|---|---|
| Seoul Electronics Co | 150000 | 1 | 1 |
| Madrid Olive Oil SL | 150000 | 1 | 1 |
| Hanoi Garments JSC | 150000 | 1 | 1 |
| Monterrey Auto Parts SA | 150000 | 1 | 1 |
| Monterrey Auto Parts SA | 140000 | **5** | **2** |
| Sao Paulo Agro SA | 140000 | **5** | **2** |
| Mumbai Textiles Ltd | 135000 | **7** | **3** |

👉 Con 4 envíos empatados en el primer lugar, `RANK()` salta directo a la
posición 5 (deja "huecos"), mientras que `DENSE_RANK()` continúa en la
posición 2 sin saltos. Esa es la diferencia que pide demostrar la rúbrica.

**Top 3 por categoría (Consulta 3)** — muestra para las 5 categorías:
`Agriculture`, `Electronics`, `Machinery`, `Raw Material`, `Textiles`,
cada una con exactamente 3 filas en el resultado, sin duplicarse por
empates de valor.

---

## ▶️ Cómo ejecutar el proyecto

### 1. Asegúrate de tener Docker Desktop corriendo

```bash
docker ps
```

Si responde sin errores (aunque sea una tabla vacía), Docker está listo.

### 2. Levanta el contenedor de PostgreSQL

Desde la carpeta `bootcamp/`:

```powershell
docker compose -f scripts/docker-compose.yml up -d
```

El warning `the attribute 'version' is obsolete` es solo informativo, no afecta la ejecución.

### 3. Carga el script completo de la Semana 14

⚠️ **Importante para PowerShell:** el operador `<` de redirección de bash
**no funciona** en PowerShell (da el error `RedirectionNotSupported`).
Usa en su lugar `Get-Content` con pipe `|`:

```powershell
Get-Content Semana14/starter/empresa_semana14.sql | docker compose -f scripts/docker-compose.yml exec -T postgres psql -U bootcamp -d bootcamp_db
```


### 4. Conecta e interactúa

```powershell
docker compose -f scripts/docker-compose.yml exec -it postgres psql -U bootcamp -d bootcamp_db
```

Esto te deja dentro del prompt interactivo `bootcamp_db=#`.

Dentro de `psql`, verifica que la tabla se creó:

```sql
\dt
```

```
               List of relations
 Schema |        Name        | Type  |  Owner
--------+--------------------+-------+----------
 public | estudiantes        | table | bootcamp
 public | product_categories | table | bootcamp
 public | shipments_raw      | table | bootcamp
(3 rows)
```

Verifica el total de filas cargadas y el resultado de la deduplicación:

```sql
-- Verificar el total de filas (incluye duplicados)
SELECT COUNT(*) FROM shipments_raw;

-- Verificar cuántos quedan tras deduplicar
WITH envios_numerados AS (
    SELECT raw_id,
           ROW_NUMBER() OVER (
               PARTITION BY tracking_code, supplier_name, category,
                            total_value, ship_date, status
               ORDER BY raw_id
           ) AS rn
    FROM shipments_raw
)
SELECT COUNT(*) FROM envios_numerados WHERE rn = 1;
```

**Resultado real obtenido (evidencia ya verificada):**

```
 count
-------
   200
(1 row)

 count
-------
   185
(1 row)
```

✅ 200 filas totales − 185 deduplicadas = **15 duplicados eliminados
correctamente**, tal como exige el criterio de evaluación.

### 5. Salir

```sql
\q
```

---

## 📁 Archivos del proyecto

```
.
├── proyecto_semana14.sql   # Script completo: DDL + DML + 4 consultas con window functions
└── README.md                # Este archivo
```

---

## ✅ Checklist de requisitos cumplidos

- [x] ≥200 filas en tabla principal (`shipments_raw`: 200)
- [x] Valores repetidos reales en la columna a rankear (`total_value`)
- [x] `ROW_NUMBER()` elimina duplicados correctamente (185 filas limpias de 200)
- [x] `RANK()` y `DENSE_RANK()` por categoría con empates visibles y diferenciados
- [x] CTE encadenado + Top-N por grupo funcional (Top 3 por categoría)
- [x] Comentarios en español explicando cada paso
- [x] Nomenclatura y estilo SQL consistentes (UPPERCASE keywords, aliases descriptivos)
- [x] Archivo ejecuta sin errores de principio a fin (validado en motor compatible)