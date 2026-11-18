"""
Contraste chi-cuadrado: retraso en la entrega vs. satisfacción del cliente (Olist)

Requisitos:  pip install scipy numpy

Datos de entrada: tabla de contingencia obtenida en Power BI con una MATRIZ:
    Filas:    Pedidos[TramoRetraso]
    Columnas: Resenas[Satisfecho]
    Valores:  Reseñas Total
"""

import numpy as np
from scipy.stats import chi2_contingency

# --- 1. Recuentos copiados de Power BI ------------------------------------
#                 Satisfecho = TRUE   Satisfecho = FALSE
recuentos = {
    "A tiempo":       (73734, 15448),
    "1-3 días":       (984, 867),
    "4-7 días":       (393, 1355),
    "Más de 7 días":  (326, 2454),
    "No entregado":   (401, 2368),
}


def contraste(nombre, tabla, etiquetas):
    """Chi-cuadrado de independencia + V de Cramér (tamaño del efecto)."""
    tabla = np.array(tabla)
    chi2, p, gl, esperados = chi2_contingency(tabla)
    n = tabla.sum()
    k = min(tabla.shape) - 1
    v_cramer = np.sqrt(chi2 / (n * k))

    print(f"\n=== {nombre} ===")
    for etiqueta, (si, no) in zip(etiquetas, tabla):
        print(f"  {etiqueta:<15} satisfechos {si:>7,}  insatisfechos {no:>7,}  CSAT {si / (si + no):6.1%}")
    print(f"  n = {n:,}")
    print(f"  Chi-cuadrado = {chi2:,.2f}   gl = {gl}   p = {p:.3g}")
    print(f"  V de Cramér  = {v_cramer:.3f}  ({interpretar_v(v_cramer, k)})")
    if (esperados < 5).any():
        print("  Aviso: hay frecuencias esperadas < 5; el contraste puede no ser fiable.")


def interpretar_v(v, k):
    """Umbrales de Cohen (1988) para gl* = 1; aproximación para tablas mayores."""
    pequeno, medio, grande = 0.10 / np.sqrt(k), 0.30 / np.sqrt(k), 0.50 / np.sqrt(k)
    if v < pequeno:
        return "efecto despreciable"
    if v < medio:
        return "efecto pequeño"
    if v < grande:
        return "efecto medio"
    return "efecto grande"


# --- 2. H2: a tiempo vs. con retraso (solo pedidos entregados) -------------
tarde = np.sum([recuentos[t] for t in ("1-3 días", "4-7 días", "Más de 7 días")], axis=0)
contraste(
    "H2 · A tiempo vs. con retraso",
    [recuentos["A tiempo"], tarde],
    ["A tiempo", "Con retraso"],
)

# --- 3. H3: los cuatro tramos de entregados --------------------------------
tramos = ["A tiempo", "1-3 días", "4-7 días", "Más de 7 días"]
contraste(
    "H3 · Tramos de retraso (entregados)",
    [recuentos[t] for t in tramos],
    tramos,
)

# --- 4. Complementario: los cinco tramos, incluidos los no entregados ------
contraste(
    "Complementario · Cinco tramos (incluye no entregados)",
    list(recuentos.values()),
    list(recuentos.keys()),
)