# Semana 07 — NULL y Constraints

**Programa:** Análisis y Desarrollo de Software (ADSO) — SENA
**Trimestre:** Cuarto · Bootcamp bc-sql  
**Instructor:** Erick Granados  
**Dominio:** Empresa de Importación

---

## Descripción

Ampliación del esquema de importaciones internacionales aplicando constraints de integridad (`NOT NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY`) y manejo seguro de valores `NULL` mediante `IS NULL`, `IS NOT NULL` y `COALESCE`.

---

## Estructura del dominio

```
suppliers ──┐
            ├──► shipments ──► customs
products  ──┘
```

| Tabla | Descripción | Filas |
|-------|-------------|-------|
| `suppliers` | Proveedores internacionales | 6 |
| `products` | Productos importados por categoría | 10 |
| `shipments` | Envíos realizados (tabla principal) | 35 |
| `customs` | Trámites de aduana por envío | 35 |

---

## Columnas opcionales (NULL permitido)

| Tabla | Columna | Razón del NULL |
|-------|---------|----------------|
| `suppliers` | `contact_email` | No todos los proveedores tienen email registrado |
| `products` | `description` | Descripción opcional para el catálogo |
| `shipments` | `arrival_date` | NULL mientras el envío no ha llegado |
| `customs` | `cleared_date` | NULL mientras el trámite no ha sido liberado |
| `customs` | `inspector_notes` | NULL cuando no hay observaciones del inspector |

---

## Constraints implementados

| Constraint | Tabla | Columna | Regla |
|------------|-------|---------|-------|
| `NOT NULL` | Todas | Campos clave | Nombre, país, cantidad, valor, fecha de envío |
| `UNIQUE` | `suppliers` | `tax_code` | NIT/RUT único por proveedor |
| `UNIQUE` | `products` | `sku` | Código de producto único |
| `UNIQUE` | `shipments` | `tracking_code` | Código de seguimiento único por envío |
| `CHECK` | `suppliers` | `rating` | Entre 1.0 y 5.0 |
| `CHECK` | `suppliers` | `active` | Solo 0 o 1 |
| `CHECK` | `products` | `category` | Lista fija de categorías permitidas |
| `CHECK` | `products` | `unit_price` | Mayor que 0 |
| `CHECK` | `shipments` | `quantity` | Mayor que 0 |
| `CHECK` | `shipments` | `status` | `delivered`, `in_transit`, `pending`, `cancelled` |
| `CHECK` | `customs` | `duty_amount` | Mayor o igual a 0 |
| `FOREIGN KEY` | `shipments` | `supplier_id` | Referencia a `suppliers` |
| `FOREIGN KEY` | `shipments` | `product_id` | Referencia a `products` |
| `FOREIGN KEY` | `customs` | `shipment_id` | Referencia a `shipments` con `ON DELETE CASCADE` |

---

## Consultas implementadas

| # | Consulta | Técnica |
|---|----------|---------|
| 1 | Envíos sin fecha de llegada registrada | `IS NULL` |
| 2 | Trámites no liberados sin notas del inspector | `IS NULL` |
| 3 | Email de proveedor con valor por defecto si falta | `COALESCE` |
| 4 | Fecha de llegada o estado actual si aún no llegó | `COALESCE` |
| 5 | Observaciones de aduana con texto estándar si NULL | `COALESCE` |
| 6 | Proveedores activos con email registrado | `IS NOT NULL` |
| 7 | Productos sin descripción en el catálogo | `IS NULL` |

---

## Cómo ejecutar

```powershell
sqlite3 -header -column empresa.db ".read semana07.sql"
```

> El archivo incluye `PRAGMA foreign_keys = ON` al inicio y `DROP TABLE IF EXISTS` para poder re-ejecutarse sin errores.

---

## Requisitos cubiertos

| Requisito | Estado |
|-----------|--------|
| `NOT NULL` — columnas obligatorias | ✅ |
| `UNIQUE` — tax_code, sku, tracking_code | ✅ |
| `CHECK` — validaciones de negocio | ✅ |
| `FOREIGN KEY` con `PRAGMA foreign_keys = ON` | ✅ |
| `IS NULL` — filtro de valores desconocidos | ✅ |
| `COALESCE` — reemplazo de NULL en SELECT | ✅ |