# Retrasos en la entrega y satisfacción del cliente en Olist

Proyecto final de Análisis de Datos · Luis Rayón

Análisis de 99.092 pedidos reales del marketplace brasileño Olist (enero de 2017 – agosto de 2018) para medir cómo se asocian los retrasos en la entrega con la satisfacción del cliente (CSAT).

**Hallazgo principal:** el cliente penaliza menos la lentitud que el incumplimiento del plazo prometido. Los pedidos a tiempo tienen un CSAT del 82,7 %; con más de 7 días de retraso, del 11,7 %. Cumplir siempre el plazo subiría el CSAT global del 77,1 % al 82,7 %.

## Estructura del repositorio

| Carpeta | Contenido |
| --- | --- |
| `01_datos/` | Los CSV originales del dataset de Olist, sin modificar |
| `02_powerbi/` | `TFDA_Olist.pbix`, su exportación `TFDA_Olist_PowerBI.pdf` y `Formulas_DAX_TFDA_Olist.pdf` |
| `03_informe/` | `Informe_TFDA_Olist_Luis_Rayon.pdf` (formato artículo, 4 páginas) |
| `04_presentacion/` | `Presentacion_TFDA_Olist.pptx`, usada en la defensa |
| `05_estadistica/` | `chi_cuadrado.py`: prueba chi-cuadrado y V de Cramér |

## Datos

*Brazilian E-Commerce Public Dataset by Olist* (Olist y Sionek, 2018), disponible en [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Datos comerciales reales y anonimizados: 99.441 pedidos entre septiembre de 2016 y octubre de 2018 en nueve tablas CSV. Se usan ocho; `olist_geolocation_dataset.csv` no interviene en el análisis.

## Herramientas

- **Power BI Desktop:** limpieza en Power Query, modelo relacional (copo de nieve, relaciones varios a uno con filtro único), medidas DAX y visualización.
- **Python 3 (SciPy, NumPy):** prueba chi-cuadrado de independencia y tamaño del efecto.

## Cómo reproducir

1. Descarga los CSV en `01_datos/` y abre `02_powerbi/TFDA_Olist.pbix`. Si cambia la ruta, actualízala en **Transformar datos → Configuración de origen de datos**.
2. Para el contraste estadístico: `pip install scipy numpy` y `python 05_estadistica/chi_cuadrado.py`.

## Resultados clave

| Indicador | Valor |
| --- | --- |
| CSAT global | 77,1 % |
| CSAT a tiempo / con más de 7 días de retraso | 82,7 % / 11,7 % |
| Chi-cuadrado (4 tramos de entregados) | χ²(3) = 12.395,86; p < 0,001; V de Cramér = 0,36 |
| Correlación por estado: % tardías vs. CSAT | r = −0,73 (−0,83 con estados de ≥ 100 pedidos) |
| Correlación por estado: días de entrega vs. CSAT | r = −0,51 |
| Clientes insatisfechos asociados a fallos de entrega | 5.459 |
