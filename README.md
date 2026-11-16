
# PIA de Control Óptimo | Planta RC de segundo orden con Arduino UNO

**Universidad Autónoma de Nuevo León (UANL)**  
**Facultad de Ingeniería Mecánica y Eléctrica (FIME)**  
**Ingeniería en Electrónica y Automatización**  
**Unidad de aprendizaje:** Control Óptimo  
**Periodo:** Agosto–Diciembre 2026  
**Autor:** Marco Alexis Sánchez Hernández — Matrícula 1917797

## Descripción del proyecto

Este repositorio reúne el desarrollo, la implementación y las pruebas experimentales de un sistema de control aplicado a una planta eléctrica RC de segundo orden. La planta se construyó en protoboard y se conectó a un **Arduino UNO**, encargado de adquirir las señales, calcular la acción de control y generar una salida PWM.

Se implementaron y compararon cuatro estrategias: **regulador lineal cuadrático (LQR)**, **asignación de polos**, **control con acción integral** y **control lineal cuadrático integral (LQI)**. El análisis teórico y el procesamiento de las mediciones se realizaron en **Scilab**.

## Objetivos

- Modelar una planta RC de segundo orden mediante ecuaciones diferenciales y espacio de estados.
- Verificar la controlabilidad y observabilidad del modelo.
- Diseñar e implementar cuatro estrategias de control.
- Obtener mediciones reales de referencia, estados y señal de control mediante Arduino UNO.
- Comparar el seguimiento de referencia y el desempeño experimental de los controladores.

## Modelo matemático

Para el modelo utilizado en el diseño de los controladores:

$$
\dot{x}(t)=Ax(t)+Bu(t),\qquad y(t)=Cx(t)
$$

$$
A=\begin{bmatrix}-2&1\\1&-2\end{bmatrix},\qquad
B=\begin{bmatrix}1\\0\end{bmatrix},\qquad
C=\begin{bmatrix}0&1\end{bmatrix}
$$

Los estados representan los voltajes de los nodos del circuito: **x₁** (nodo intermedio) y **x₂** (salida de la planta). La salida controlada es **y = x₂**.

En el modelo nominal se consideran **R₁ = R₂ = R₃ = 1 MΩ** y **C₁ = C₂ = 1 µF**. La salida PWM emplea un filtro de **1 kΩ y 10 µF**. Estos valores deben corresponder con los componentes instalados en el montaje físico.

Para una referencia constante \(r\), el equilibrio empleado en el diseño es:

$$
x_{1,\mathrm{eq}}=2r,\qquad x_{2,\mathrm{eq}}=r,\qquad u_{\mathrm{eq}}=3r
$$

La ley de control implementada tiene la forma:

$$
u=3r-k_1(x_1-2r)-k_2(x_2-r)+k_i\int(r-x_2)\,dt
$$

Para LQR y asignación de polos se utiliza \(k_i=0\). En los controladores integrales se aplica una limitación de la señal de control y una protección antiwindup.

## Controladores implementados

| Modo | Controlador | k₁ | k₂ | kᵢ |
|---|---|---:|---:|---:|
| 1 | LQR | 0.41421356 | 0.41421356 | 0 |
| 2 | Asignación de polos | 1.00000000 | 1.00000000 | 0 |
| 3 | Integral | 0.80000000 | 2.35000000 | 3.00000000 |
| 4 | LQI | 0.71101988 | 1.17481439 | 1.41421356 |

Los valores corresponden a las ganancias programadas en el código de Arduino incluido en el proyecto.

## Implementación física

**Equipo principal:** Arduino UNO, planta RC montada en protoboard, pantalla LCD 16×2, potenciómetro de referencia, pulsadores y multímetro.

### Conexiones del Arduino

| Función | Pin |
|---|---|
| Salida PWM hacia el filtro | D5 |
| Medición de x₁ | A0 |
| Medición de x₂ | A1 |
| Referencia ajustable | A2 |
| Botón START | D7 |
| Botón STOP | D8 |
| Botón RESET | D9 |

**Pantalla LCD 16×2:** RS→D12, E→D11, D4→D6, D5→D4, D6→D3 y D7→D2. La tierra de la planta debe ser común con la del Arduino.

**Nota:** comprobar las conexiones físicas antes de cargar el programa; los pines indicados corresponden al código documentado.

## Adquisición de datos y funcionamiento

El programa trabaja con un período nominal de muestreo de **20 ms** y comunicación serial a **115200 baudios**. Permite visualizar señales en tiempo real (`PLOT`) o generar registros (`CSV`) con el encabezado:

```csv
t_ms,modo,r,x1,x2,u,pwm
```

- `t_ms`: tiempo transcurrido desde el inicio de la prueba, en milisegundos.
- `modo`: controlador seleccionado (1 a 4).
- `r`: referencia en voltios.
- `x1`, `x2`: voltajes medidos en los estados de la planta.
- `u`: acción de control equivalente en voltios.
- `pwm`: valor aplicado a la salida PWM (0–255).

### Comandos del monitor serie

| Comando | Función |
|---|---|
| `1`, `2`, `3`, `4` | Seleccionar controlador |
| `s` | Iniciar |
| `x` o `0` | Detener |
| `z` | Reiniciar |
| `p` | Formato de gráficas en tiempo real |
| `c` | Formato CSV |

Los pulsadores físicos también permiten iniciar, detener y reiniciar el sistema.

## Pruebas experimentales

Se registraron respuestas de los cuatro controladores ante referencias de aproximadamente **0.30 V, 0.50 V y 0.80 V**. Los datos se procesaron en Scilab para comparar:

- Respuesta de salida \(x_2(t)\).
- Acción de control \(u(t)\).
- Error de seguimiento \(e(t)=r(t)-x_2(t)\).
- Referencias experimentales alineadas.

Los indicadores calculados incluyen **MAE**, **RMSE**, **error estacionario estimado**, **tiempo de permanencia en banda** y **exceso respecto de la referencia**. La interpretación de estos indicadores depende de la ventana de análisis y del filtrado aplicado a las mediciones.

### Resultados destacados

En las pruebas procesadas, el controlador integral presentó el menor **MAE** para las tres referencias evaluadas. En la referencia de **0.50 V**, el LQI presentó el menor **RMSE**. Estos resultados describen las mediciones de este montaje y no implican superioridad universal de un controlador.

## Organización del repositorio

El material del proyecto se agrupa dentro de la carpeta [`PIA_Control_Optimo`](PIA_Control_Optimo/). Allí se conservan los programas, los registros experimentales, las gráficas, las fotografías y el reporte, según los archivos disponibles en el repositorio.

Para reproducir el trabajo, se necesitan el programa de **Arduino IDE**, los scripts de **Scilab** y los archivos **CSV** correspondientes a cada controlador.

## Herramientas utilizadas

- Arduino UNO y Arduino IDE.
- Scilab para simulación y análisis de datos.
- Protoboard y componentes resistivos/capacitivos.
- Pantalla LCD 16×2 y multímetro.
- LaTeX para la documentación técnica.
- GitHub para organizar el código y los resultados.

## Evidencia y documentación

Las fotografías del prototipo, las gráficas comparativas y el reporte del PIA forman parte de la documentación del proyecto. El video demostrativo se agregará cuando esté publicado.

**Video de demostración:** pendiente de publicación.

## Consideraciones técnicas

El desempeño experimental está condicionado por las tolerancias de los componentes, el ruido de adquisición, la impedancia de los nodos, la resolución del convertidor A/D y la saturación de la salida PWM. Las ganancias y las conexiones deben revisarse antes de reproducir el montaje en otro circuito.

---

**Proyecto académico — UANL / FIME — Control Óptimo — Agosto–Diciembre 2026.**
