
// ============================================================
// UNIVERSIDAD AUTONOMA DE NUEVO LEON
// FACULTAD DE INGENIERIA MECANICA Y ELECTRICA
//
// PIA - CONTROL OPTIMO
// CALCULO EXPERIMENTAL DEL INDICE DE DESEMPENO J
//
// Controladores:
// 1 - LQR
// 2 - Asignacion de polos
// 3 - Control integral
// 4 - LQI
//
// Referencias: 0.30, 0.50 y 0.80 V
// Ventanas de analisis: 15 segundos
// ============================================================

clear;
clc;

// ============================================================
// 1. RUTAS CORRECTAS
// ============================================================

base = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/";

carpeta = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/Datos_Experimentales/";
mprintf("ESTOY EJECUTANDO EL CODIGO CORREGIDO\n");
mprintf("RUTA CSV: %s\n", carpeta);
// ============================================================
// 2. ARCHIVOS EXPERIMENTALES
// ============================================================

archivos = [
    "PIA_LQR_Experimental_Limpio.csv";
    "PIA_Polos_Experimental_Limpio.csv";
    "PIA_Integral_Experimental_Limpio.csv";
    "PIA_LQI_Experimental_Limpio.csv"
];

nombres = [
    "LQR";
    "Polos";
    "Integral";
    "LQI"
];

referencias = [0.30 0.50 0.80];

duracion = 15;

// ============================================================
// 3. COMPROBAR ARCHIVOS
// ============================================================

mprintf("\n========================================\n");
mprintf(" VERIFICACION DE ARCHIVOS CSV\n");
mprintf("========================================\n");

mprintf("\nCarpeta: %s\n\n", carpeta);

for i = 1:4

    ruta = carpeta + archivos(i);

    if isfile(ruta) then

        mprintf("ENCONTRADO: %s\n", archivos(i));

    else

        error("NO SE ENCONTRO: " + ruta);

    end

end

// ============================================================
// 4. FILTRO DE MEDIANA MOVIL
// ============================================================

function y = filtroMediana(x, ventana)

    x = matrix(x, -1, 1);

    n = length(x);

    y = zeros(n, 1);

    mitad = floor(ventana / 2);

    for i = 1:n

        a = max(1, i-mitad);
        b = min(n, i+mitad);

        y(i) = median(x(a:b));

    end

endfunction

// ============================================================
// 5. INTERPOLACION LINEAL
// ============================================================

function valor = interpolar(t, x, tiempo)

    n = length(t);

    if tiempo <= t(1) then
        valor = x(1);
        return;
    end

    if tiempo >= t(n) then
        valor = x(n);
        return;
    end

    indice = find(t <= tiempo);

    k = indice($);

    dt = t(k+1) - t(k);

    if dt <= 0 then
        valor = x(k);
        return;
    end

    fraccion = (tiempo-t(k))/dt;

    valor = x(k) + fraccion*(x(k+1)-x(k));

endfunction

// ============================================================
// 6. COSTO CUADRATICO EXPERIMENTAL
// ============================================================
//
// J = integral [
//      (x1 - 2*r)^2
//    + 5*(x2 - r)^2
//    + (u - 3*r)^2
// ] dt
//
// Se utiliza integracion trapezoidal.
// ============================================================

function J = calcularCosto(t, x1, x2, u, ref, inicio, T)

    fin = inicio + T;

    indices = find(t > inicio & t < fin);

    // Construir ventana de tiempo

    tt = [
        inicio;
        t(indices);
        fin
    ];

    // Interpolar los extremos

    xx1 = [
        interpolar(t, x1, inicio);
        x1(indices);
        interpolar(t, x1, fin)
    ];

    xx2 = [
        interpolar(t, x2, inicio);
        x2(indices);
        interpolar(t, x2, fin)
    ];

    uu = [
        interpolar(t, u, inicio);
        u(indices);
        interpolar(t, u, fin)
    ];

    // Desviaciones respecto al equilibrio

    e1 = xx1 - 2*ref;
    e2 = xx2 - ref;
    eu = uu - 3*ref;

    // Integrando del indice J

    L = e1.^2 + 5*e2.^2 + eu.^2;

    // Integracion trapezoidal

    J = 0;

    for k = 1:(length(tt)-1)

        dt = tt(k+1)-tt(k);

        J = J + 0.5*(L(k)+L(k+1))*dt;

    end

endfunction

// ============================================================
// 7. PROCESAMIENTO EXPERIMENTAL
// ============================================================

resultados = %nan * ones(4, 3);

mprintf("\n========================================\n");
mprintf(" PIA CONTROL OPTIMO - INDICE J\n");
mprintf("========================================\n");

for m = 1:4

    mprintf("\n----------------------------------------\n");
    mprintf("CONTROLADOR: %s\n", nombres(m));
    mprintf("----------------------------------------\n");

    // Leer CSV
    // La primera fila contiene encabezados

    datos = csvRead( ...
        carpeta + archivos(m), ...
        ",", ".", "double", [], [], [], 1 ...
    );

    // Columnas:
    // 1 = t_ms
    // 2 = modo
    // 3 = r
    // 4 = x1
    // 5 = x2
    // 6 = u
    // 7 = pwm

    // Ordenar registros por tiempo

    [tiempos, orden] = gsort( ...
        datos(:,1)/1000, "g", "i" ...
    );

    r  = datos(orden,3);
    x1 = datos(orden,4);
    x2 = datos(orden,5);
    u  = datos(orden,6);

    // Eliminar tiempos repetidos

    conservar = [
        %t;
        diff(tiempos) > 0
    ];

    t  = tiempos(conservar);
    r  = r(conservar);
    x1 = x1(conservar);
    x2 = x2(conservar);
    u  = u(conservar);

    // Filtrar las mediciones

    r11 = filtroMediana(r, 11);

    x1 = filtroMediana(x1, 11);
    x2 = filtroMediana(x2, 11);
    u  = filtroMediana(u, 11);

    // Referencia suavizada para localizar escalones

    r101 = filtroMediana(r11, 101);

    // Inicio de la primera etapa

    inicios = [t(1) %nan %nan];

    // Umbrales entre referencias

    umbrales = [0.40 0.65];

    // Detectar cambios hacia 0.50 y 0.80 V

    for k = 1:2

        candidatos = find( ...
            r101(1:$-1) < umbrales(k) & ...
            r101(2:$) >= umbrales(k) ...
        );

        if k == 1 then
            minimo = 10;
        else
            minimo = inicios(2) + 12;
        end

        for z = 1:length(candidatos)

            posicion = candidatos(z)+1;

            if t(posicion) > minimo then

                inicios(k+1) = t(posicion);

                break;

            end

        end

    end

    // Calcular costo para cada referencia

    for k = 1:3

        ref = referencias(k);

        inicio = inicios(k);

        if isnan(inicio) then

            mprintf( ...
                "REF %.2f V: cambio no detectado\n", ref ...
            );

        elseif inicio + duracion > t($) then

            mprintf( ...
                "REF %.2f V: datos insuficientes\n", ref ...
            );

        else

            J = calcularCosto( ...
                t, x1, x2, u, ...
                ref, inicio, duracion ...
            );

            resultados(m,k) = J;

            mprintf( ...
                "REF %.2f V | Inicio %.3f s | J = %.5f\n", ...
                ref, inicio, J ...
            );

        end

    end

end

// ============================================================
// 8. TABLA FINAL
// ============================================================

mprintf("\n========================================\n");
mprintf(" TABLA COMPARATIVA DEL COSTO J\n");
mprintf("========================================\n\n");

mprintf("Controlador       J_030       J_050       J_080\n");

for m = 1:4

    mprintf( ...
        "%-14s %10.5f %10.5f %10.5f\n", ...
        nombres(m), ...
        resultados(m,1), ...
        resultados(m,2), ...
        resultados(m,3) ...
    );

end

// ============================================================
// 9. EXPORTAR RESULTADOS A CSV
// ============================================================

salida = carpeta + "PIA_Costos_J_Recalculados.csv";

tabla = [
    "Controlador", "J_030", "J_050", "J_080";
    nombres(1), string(resultados(1,1)), ...
                string(resultados(1,2)), ...
                string(resultados(1,3));
    nombres(2), string(resultados(2,1)), ...
                string(resultados(2,2)), ...
                string(resultados(2,3));
    nombres(3), string(resultados(3,1)), ...
                string(resultados(3,2)), ...
                string(resultados(3,3));
    nombres(4), string(resultados(4,1)), ...
                string(resultados(4,2)), ...
                string(resultados(4,3))
];

csvWrite(tabla, salida);

mprintf("\n========================================\n");
mprintf(" CALCULO FINALIZADO\n");
mprintf("========================================\n");

mprintf("\nResultados guardados en:\n%s\n", salida);
