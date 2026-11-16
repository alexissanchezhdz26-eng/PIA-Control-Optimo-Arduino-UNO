
clc;
clear;

// ============================================================
// PIA CONTROL OPTIMO - FIME UANL
// TABLA FINAL DE INDICADORES EXPERIMENTALES
//
// PLANTA RC DE SEGUNDO ORDEN
// ARDUINO UNO
//
// 1 - LQR
// 2 - ASIGNACION DE POLOS
// 3 - CONTROL INTEGRAL
// 4 - LQI
//
// ANALISIS CON TIEMPOS EXPERIMENTALES ORIGINALES
// ============================================================

// ------------------------------------------------------------
// 1. CONFIGURACION
// ------------------------------------------------------------

carpeta = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/";

archivos = [
    "PIA_LQR_Experimental_Limpio.csv";
    "PIA_Polos_Experimental_Limpio.csv";
    "PIA_Integral_Experimental_Limpio.csv";
    "PIA_LQI_Experimental_Limpio.csv"
];

nombres = ["LQR"; "Polos"; "Integral"; "LQI"];

refs = [0.30; 0.50; 0.80];

// Ventana comun de comparacion
ventana = 15;

// Banda de establecimiento
tolerancia = 0.05;

// Tiempo minimo continuo dentro de la banda
permanencia = 3;

// ------------------------------------------------------------
// 2. FILTRO DE MEDIANA
// ------------------------------------------------------------

function yf = filtrar(y,nvent)

    n = length(y);
    yf = y;

    mitad = floor(nvent/2);

    for i = 1:n

        a = max(1,i-mitad);
        b = min(n,i+mitad);

        yf(i) = median(y(a:b));

    end

endfunction

// ------------------------------------------------------------
// 3. DETECTAR TRANSICIONES
// ------------------------------------------------------------

function tc = detectar(t,r,umbral)

    tc = %nan;

    n = length(r);

    for i = 1:(n-14)

        if median(r(i:i+14)) >= umbral then

            tc = t(i);
            break;

        end

    end

endfunction

// ------------------------------------------------------------
// 4. CALCULO DE INDICADORES
// ------------------------------------------------------------

function [mae,rmse,ess,ts,exceso] = analizar( ...
    t,r,y,inicio,fin,ref,tolerancia,permanencia)

    mae = %nan;
    rmse = %nan;
    ess = %nan;
    ts = %nan;
    exceso = %nan;

    idx = find(t >= inicio & t < fin);

    if length(idx) < 10 then
        return;
    end

    tt = t(idx);
    rr = r(idx);
    yy = y(idx);

    // Error experimental
    ee = rr-yy;

    // MAE
    mae = mean(abs(ee));

    // RMSE
    rmse = sqrt(mean(ee.^2));

    // Error promedio del ultimo 20% de la ventana
    n = length(ee);
    a = max(1,ceil(0.8*n));

    ess = mean(ee(a:n));

    // Exceso maximo respecto a la referencia nominal
    exceso = max(0,(max(yy)-ref)/ref*100);

    // Banda de establecimiento
    banda = tolerancia*abs(ref);

    // Se requiere permanencia continua durante
    // un intervalo minimo de 3 segundos.
    // Es un criterio de permanencia, no de
    // establecimiento definitivo hasta el final.

    for i = 1:length(tt)

        if abs(yy(i)-ref) <= banda then

            tfinal = tt(i)+permanencia;

            j = find(tt >= tt(i) & tt <= tfinal);

            if length(j) >= 2 then

                if tt(j($)) >= tfinal-0.05 then

                    if and(abs(yy(j)-ref) <= banda) then

                        ts = tt(i)-inicio;
                        break;

                    end

                end

            end

        end

    end

endfunction

// ------------------------------------------------------------
// 5. MATRIZ DE RESULTADOS
// ------------------------------------------------------------

// Columnas:
// Modo, Referencia, MAE, RMSE, Ess, Ts, Exceso

resultados = zeros(12,7);

// ------------------------------------------------------------
// 6. PROCESAMIENTO DE CONTROLADORES
// ------------------------------------------------------------

fila = 1;

disp("==============================================");
disp("TABLA FINAL DE INDICADORES EXPERIMENTALES");
disp("==============================================");

for k = 1:4

    ruta = carpeta + archivos(k);

    if ~isfile(ruta) then
        error("Archivo no encontrado: " + ruta);
    end

    D = csvRead(ruta,",",".","double",[],[],[],1);

    if size(D,2) <> 7 then
        error("Formato incorrecto: " + archivos(k));
    end

    if or(D(:,2) <> k) then
        error("Modo incorrecto: " + archivos(k));
    end

    t = (D(:,1)-D(1,1))/1000;

    r = filtrar(D(:,3),11);
    y = filtrar(D(:,5),11);

    // Detectar cambios
    c1 = detectar(t,r,0.40);
    c2 = detectar(t,r,0.65);

    if isnan(c1) | isnan(c2) then
        error("No se detectaron los cambios: " + nombres(k));
    end

    if c1 <= 0 | c2 <= c1 then
        error("Transiciones invalidas: " + nombres(k));
    end

    inicios = [0; c1; c2];
    finales = [c1; c2; t($)];

    mprintf("\nCONTROLADOR: %s\n",nombres(k));

    for etapa = 1:3

        inicio = inicios(etapa);

        // Comparar una ventana de 15 segundos
        fin = min(inicio+ventana,finales(etapa));

        if fin-inicio < ventana-0.1 then
            mprintf("ADVERTENCIA: %s, REF %.2f V: ", ...
                nombres(k),refs(etapa));
            mprintf("ventana incompleta (%.2f s)\n",fin-inicio);
        end

        [mae,rmse,ess,ts,exceso] = analizar( ...
            t,r,y,inicio,fin,refs(etapa), ...
            tolerancia,permanencia);

        resultados(fila,:) = [ ...
            k,refs(etapa),mae,rmse,ess,ts,exceso];

        mprintf("REF %.2f V | ",refs(etapa));
        mprintf("MAE %.4f | RMSE %.4f | ",mae,rmse);
        mprintf("Ess %.4f | Ts %.3f s | ",ess,ts);
        mprintf("Exceso %.2f %%\n",exceso);

        fila = fila+1;

    end

end

// ------------------------------------------------------------
// 7. EXPORTAR TABLA CSV
// ------------------------------------------------------------

encabezado = "Modo,Referencia_V,MAE_V,RMSE_V,Ess_V,Ts_s,Exceso_pct";

ruta_salida = carpeta + "PIA_Tabla_Indicadores_Final.csv";

fd = mopen(ruta_salida,"wt");

mfprintf(fd,"%s\n",encabezado);

for i = 1:size(resultados,1)

    mfprintf(fd,"%d,%.2f,%.6f,%.6f,%.6f,%.6f,%.4f\n", ...
        resultados(i,1), ...
        resultados(i,2), ...
        resultados(i,3), ...
        resultados(i,4), ...
        resultados(i,5), ...
        resultados(i,6), ...
        resultados(i,7));

end

mclose(fd);

// ------------------------------------------------------------
// 8. FINAL
// ------------------------------------------------------------

disp("==============================================");
disp("ANALISIS FINALIZADO");
disp("TABLA CSV GUARDADA CORRECTAMENTE");
disp("==============================================");

disp(ruta_salida);
