# bc-sql — Empresa de Importación

Repositorio del bootcamp de SQL — proyecto integrador desarrollado a lo
largo de las Semanas 06 a 16, aplicado a un **dominio único**: una
empresa de importación que gestiona proveedores, productos, envíos,
trámites de aduana y categorías de productos.

## 👤 Autor
- **Nombre**: Julián Esneyde Machado Garzón
- **Ficha**:3228973B
- **GitHub**: [@JulianMg20](https://github.com/JulianMg20)
- **Proyecto**: SENA - Análisis y Desarrollo de Software
- **Trimestre**: 4 

**Motor de base de datos:** SQLite (Semanas 06–12) → PostgreSQL (Semanas 13–16)

---

## 🗺️ Recorrido del proyecto

| Semana | Tema | Carpeta |
|--------|------|---------|
| 06 | Funciones de agregación | [`Semana06`](./Semana06) |
| 07 | NULL y Constraints | [`Semana07`](./Semana07) |
| 08 | Proyecto integrador — Etapa 0 (esquema completo) | [`Semana08`](./Semana08) |
| 09 | JOINs (INNER / LEFT) | [`Semana09`](./Semana09) |
| 10 | SELF JOIN — jerarquías | [`Semana10`](./Semana10) |
| 11 | Subqueries (escalares, IN/EXISTS, tablas derivadas) | [`Semana11`](./Semana11) |
| 12 | CTEs y CASE WHEN | [`Semana12`](./Semana12) |
| 13 | CTEs recursivas — jerarquías en PostgreSQL | [`Semana13`](./Semana13) |
| 14 | Window Functions — ranking (ROW_NUMBER, RANK, DENSE_RANK) | [`Semana14`](./Semana14) |
| 15 | Window Functions temporales (LAG/LEAD) + Vistas | [`Semana15`](./Semana15) |
| 16 | Índices y consultas optimizadas (EXPLAIN ANALYZE) | [`Semana16`](./Semana16) |

Cada carpeta `SemanaXX/starter/` contiene:
- El script `.sql` completo (DDL + DML + consultas pedidas en esa semana)
- Un `README.md` propio con la descripción, instrucciones de ejecución y checklist de esa entrega

La carpeta [`scripts/`](./scripts) contiene el `docker-compose.yml` usado
desde la Semana 13 en adelante para levantar PostgreSQL.

---

## 🗂️ Dominio: Empresa de Importación

El proyecto modela el flujo de una empresa que importa mercancía desde
varios países, organizado alrededor de estas entidades principales:

| Entidad | Descripción |
|---|---|
| `suppliers` | Proveedores internacionales (con país, calificación, estado activo) |
| `products` | Catálogo de productos por categoría |
| `shipments` | Envíos/importaciones (tabla principal en la mayoría de semanas) |
| `customs` | Trámites de aduana asociados a cada envío |
| `product_categories` | Árbol jerárquico de categorías de producto (Semanas 10 y 13) |
| `monthly_shipments` | Resumen mensual de importaciones por categoría (Semana 15) |

A partir de la Semana 09, los datos de prueba se generaron en volúmenes
crecientes (80, luego 200 filas) para que JOINs, subqueries, CTEs
recursivas, window functions e índices tuvieran sentido analítico real
y no solo sintáctico.

---

## ▶️ Cómo ejecutar cualquier semana

### Semanas 06–12 (SQLite)

```bash
sqlite3 nombre_de_la_base.db
.read SemanaXX/starter/nombre_del_script.sql
.tables
```

### Semanas 13–16 (PostgreSQL vía Docker)

1. Levanta el contenedor (una sola vez, desde la raíz del repo):

   ```bash
   docker compose -f scripts/docker-compose.yml up -d
   ```

2. Carga el script de la semana que quieras revisar:

   ```bash
   # bash / Linux / macOS
   docker compose -f scripts/docker-compose.yml exec -T postgres \
     psql -U bootcamp -d bootcamp_db < SemanaXX/starter/nombre_del_script.sql
   ```

   ```powershell
   # PowerShell (Windows) — el operador `<` no funciona, usa Get-Content
   Get-Content SemanaXX/starter/nombre_del_script.sql | docker compose -f scripts/docker-compose.yml exec -T postgres psql -U bootcamp -d bootcamp_db
   ```

3. Conecta interactivamente para explorar:

   ```bash
   docker compose -f scripts/docker-compose.yml exec -it postgres psql -U bootcamp -d bootcamp_db
   ```

   ```sql
   \dt      -- listar tablas
   \dv      -- listar vistas
   \di      -- listar índices
   \q       -- salir
   ```

Cada `README.md` dentro de `SemanaXX/starter/` tiene el detalle exacto
de qué tabla(s) se crean, cuántas filas trae el seed de datos, y qué
consultas se piden para esa entrega puntual.

---

## ✅ Estado general del proyecto

- [x] Esquema relacional consistente desde la Semana 06 hasta la 16
- [x] Constraints (PK, FK, UNIQUE, CHECK, DEFAULT) aplicados desde la Semana 07
- [x] Volumen de datos creciente y realista (80 → 200 filas) desde la Semana 09
- [x] Jerarquías modeladas con SELF JOIN (Semana 10) y CTE recursiva (Semana 13)
- [x] Migración de SQLite a PostgreSQL para las semanas de funciones avanzadas
- [x] Window functions de ranking y temporales con datos diseñados para mostrar
      empates, duplicados y tendencias reales (Semanas 14 y 15)
- [x] Índices estratégicos verificados con `EXPLAIN ANALYZE` (Semana 16)
