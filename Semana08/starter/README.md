# Proyecto Integrador — Etapa 0
## Semana 08 — Evidencia de Producto

**Dominio asignado:** Empresa de Importación (bc-sql)

---

## 📋 Descripción

Este proyecto implementa un esquema relacional completo en SQLite para gestionar
las operaciones de una empresa de importación: proveedores, productos, envíos
y trámites de aduana. Integra los conceptos trabajados en las semanas 01 a 07
(DDL, DML, agregaciones, constraints y manejo de NULL).

---

## 🗂️ Estructura del esquema

| Tabla         | Rol                    | Descripción                                  |
|---------------|-------------------------|-----------------------------------------------|
| `suppliers`   | Referencia              | Proveedores internacionales (10 filas)        |
| `products`    | Referencia              | Catálogo de productos importados (10 filas)   |
| `shipments`   | **Principal**           | Envíos/importaciones registrados (35 filas)   |
| `customs`     | Dependiente (1:1)       | Trámites de aduana por envío (35 filas)       |

**Relaciones:**
- `suppliers (1) → (N) shipments`
- `products (1) → (N) shipments`
- `shipments (1) → (1) customs`

**Constraints aplicados:**
- `PRIMARY KEY` en las 4 tablas
- `UNIQUE`: `tax_code` (suppliers), `sku` (products), `tracking_code` y FK `shipment_id` (customs)
- `CHECK`: `rating` (1.0–5.0), `category` (lista cerrada), `unit_price > 0`, `quantity > 0`, `total_value > 0`, `status` (lista cerrada), `duty_amount >= 0`
- `DEFAULT`: `rating = 3.0`, `active = 1`, `status = 'pending'`, `cleared = 0`
- `FOREIGN KEY` con `ON DELETE/UPDATE` definidos
- Columnas opcionales con `NULL` real: `contact_email`, `description`, `arrival_date`, `cleared_date`, `inspector_notes`

---

## 📊 Consultas de reporte incluidas

| # | Reporte | Cláusulas |
|---|---------|-----------|
| 1 | Totales globales de importación | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` |
| 2 | Facturación por categoría de producto | `GROUP BY` + `ORDER BY` |
| 3 | Proveedores con riesgo de concentración (>500.000 USD) | `GROUP BY` + `HAVING` |
| 4 | Envíos sin fecha de llegada confirmada | `IS NULL` + `COALESCE` |
| 5 | Envíos de Electronics entregados en rango de valor | `WHERE` + `BETWEEN` |

---

## ▶️ Cómo ejecutar el proyecto

### Requisitos
- [SQLite3](https://www.sqlite.org/download.html) instalado (`sqlite3 --version` para verificar)
- VS Code con la extensión **SQLite Viewer** o **SQLite** (opcional, para inspección visual)

### Pasos

1. Clona o abre esta carpeta en VS Code.
2. Abre una terminal integrada (`Ctrl + ñ` / `Ctrl + \``).
3. Ejecuta el script contra la base de datos:

   ```bash
   sqlite3 empresa_semana08.db < proyecto.sql
   ```

4. Verifica que no se imprima ningún error en la terminal.
5. (Opcional) Inspecciona los datos abriendo `empresa_semana08.db` con la extensión SQLite de VS Code, o desde la terminal:

   ```bash
   sqlite3 empresa_semana08.db
   .tables
   SELECT * FROM shipments LIMIT 5;
   .quit
   ```

### Verificación rápida de conteos

```bash
sqlite3 empresa_semana08.db "SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'shipments', COUNT(*) FROM shipments
UNION ALL SELECT 'customs', COUNT(*) FROM customs;"
```

Resultado esperado:

```
suppliers|10
products|10
shipments|35
customs|35
```

---

## 📁 Archivos del proyecto

```
.
├── proyecto.sql           # Script completo: DDL + DML + consultas de reporte
├── empresa_semana08.db    # Base de datos generada (binario SQLite format 3)
└── README.md              # Este archivo
```

---

## ✅ Checklist de requisitos cumplidos

- [x] `PRAGMA foreign_keys = ON;` al inicio
- [x] 3+ tablas relacionadas con al menos 1 relación 1:N
- [x] PK en cada tabla
- [x] Al menos 1 columna `UNIQUE`, 1 `CHECK`, 1 `DEFAULT`
- [x] ≥3 registros en tablas de referencia (10 en suppliers, 10 en products)
- [x] ≥8 registros en tabla principal (35 en shipments)
- [x] ≥2 registros con columna opcional en `NULL`
- [x] 5 consultas de reporte con las cláusulas obligatorias
- [x] Archivo ejecuta sin errores de principio a fin