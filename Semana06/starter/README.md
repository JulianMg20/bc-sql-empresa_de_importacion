# Semana 06 — funciones de agregación

**Programa:** Análisis y Desarrollo de Software (ADSO) — SENA
**Trimestre:** Cuarto · Bootcamp bc-sql  
**Instructor:** Erick Granados  
**Dominio:** Empresa de Importación


# 📦 Proyecto SQL — Empresa de Importación

Este repositorio contiene el desarrollo de una base de datos en **SQLite** para simular el dominio de una empresa de importación.  
La evidencia corresponde a la **Semana 06** del bootcamp, enfocada en **funciones de agregación**.

---

## 📂 Estructura del proyecto
```
bc-sql-empresa_de_importacion/
└── Semana06/
└── starter/
├── empresa_importacion.sql   # Script SQL con tablas, datos y consultas
└── empresa.db                # Base de datos generada en SQLite
```
---

---

## 🗄️ Tablas principales

- **suppliers** → proveedores internacionales con país y rating.  
- **products** → catálogo de productos importados con categoría y precio unitario.  
- **shipments** → envíos registrados con cantidad, valor total, fecha y estado logístico.  
- **customs** → trámites de aduana con aranceles y estado de liberación.

---

## 📊 Datos semilla

- **35 envíos** registrados en la tabla `shipments`.  
- Distribución desigual: algunos proveedores dominan el volumen, otros tienen pocos envíos.  
- En la tabla `customs`, varios registros incluyen valores **NULL** en `cleared_date` para simular trámites pendientes.

---

## 📈 Consultas implementadas

1. **COUNT** → total de envíos registrados.  
2. **SUM + AVG + MIN + MAX** → valor total, promedio, envío más pequeño y más grande.  
3. **GROUP BY proveedor** → resumen de envíos, valor total y promedio por proveedor.  
4. **GROUP BY categoría** → facturación total y promedio por categoría de producto.  
5. **HAVING** → proveedores con valor total superior a 500.000 USD.  
6. **HAVING** → categorías con más de 5 envíos.  
7. **BONUS** → resumen por estado del envío (`delivered`, `in_transit`, `pending`).  
8. **BONUS** → aranceles de aduana por proveedor, con filtro de carga arancelaria alta.

---

## 🚀 Cómo ejecutar

1. Abre SQLite en la terminal:
   ```bash
   sqlite3 empresa.db
   ```
2. Ejecuta el script SQL:
   ```bash
   .read empresa_importacion.sql
   ```
