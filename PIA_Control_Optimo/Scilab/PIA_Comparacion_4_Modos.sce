
clc;
clear;
close(winsid());

// ============================================================
// PIA CONTROL OPTIMO - FIME UANL
// COMPARACION EXPERIMENTAL CORREGIDA
//
// Planta RC de segundo orden con Arduino UNO
//
// Modo 1: LQR
// Modo 2: Asignacion de polos
// Modo 3: Control integral
// Modo 4: LQI
// ============================================================

// ------------------------------------------------------------
// 1. CARPETA Y ARCHIVOS
// ------------------------------------------------------------

carpeta = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/";

archivos = [
    "PIA_LQR_Experimental_Limpio.csv";
    "PIA_Polos_Experimental_Limpio.csv";
    "PIA_Integral_Experimental_Limpio.csv";
    "PIA_LQI_Experimental_Limpio.csv"
];

nombres = ["LQR"; "Polos"; "Integral"; "LQI"];

// ------------------------------------------------------------
// 2. FUNCION DE FILTRADO DE MEDIANA
// ------------------------------------------------------------

// Reduce picos aislados sin alterar los datos originales.
// La ventana debe ser impar.

function yf = filtro_mediana(y, ventana)

    n = length(y);
    yf = y;

    mitad = floor(ventana/2);

    for i = 1:n

        a = max(1,i-mitad);
        b = min(n,i+mitad);

        yf(i) = median(y(a:b));

    end

endfunction

// ------------------------------------------------------------
// 3. DETECCION DE CAMBIOS SOSTENIDOS DE REFERENCIA
// ------------------------------------------------------------

// Detecta los cruces de los umbrales 0.40 y 0.65 V.
// La mediana evita que un pico aislado se interprete
// como un cambio real de referencia.

function tc = detectar_umbral(t,r,umbral)

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
// 4. ALINEACION DE LOS DOS CAMBIOS
// ------------------------------------------------------------

// El primer cambio se coloca en 20 segundos.
// El segundo cambio se coloca en 45 segundos.
//
// Cada etapa conserva su forma temporal, pero se
// traslada y escala para comparar los experimentos.

function tn = alinear_tiempo(t,c1,c2)

    tn = zeros(t);

    for i = 1:length(t)

        if t(i) < c1 then

            tn(i) = 20*t(i)/c1;

        elseif t(i) < c2 then

            tn(i) = 20+25*(t(i)-c1)/(c2-c1);

        else

            tn(i) = 45+(t(i)-c2);

        end

    end

endfunction

// ------------------------------------------------------------
// 5. LECTURA Y PREPARACION DE DATOS
// ------------------------------------------------------------

T = list();
R = list();
X = list();
U = list();
E = list();

for k = 1:4

    ruta = carpeta + archivos(k);

    if ~isfile(ruta) then
        error("Archivo no encontrado: " + ruta);
    end

    D = csvRead(ruta,",",".","double",[],[],[],1);

    if size(D,2) <> 7 then
        error("Formato CSV incorrecto: " + archivos(k));
    end

    if or(D(:,2) <> k) then
        error("Numero de modo incorrecto: " + archivos(k));
    end

    t = (D(:,1)-D(1,1))/1000;

    r = D(:,3);
    x2 = D(:,5);
    u = D(:,6);

    // Filtrado de mediana: 11 muestras
    rf = filtro_mediana(r,11);
    xf = filtro_mediana(x2,11);
    uf = filtro_mediana(u,11);

    // Detectar los dos cambios de referencia
    c1 = detectar_umbral(t,rf,0.40);
    c2 = detectar_umbral(t,rf,0.65);

    if isnan(c1) | isnan(c2) then
        error("No se detectaron dos cambios en " + nombres(k));
    end

    if c1 <= 0 | c2 <= c1 then
        error("Transiciones invalidas en " + nombres(k));
    end

    // Alinear los experimentos
    tn = alinear_tiempo(t,c1,c2);

    // Guardar datos procesados
    T(k) = tn;
    R(k) = rf;
    X(k) = xf;
    U(k) = uf;
    E(k) = rf-xf;

    mprintf("%s: cambio 1 = %.2f s, cambio 2 = %.2f s\n", ...
            nombres(k),c1,c2);

end

// ------------------------------------------------------------
// 6. COLORES PERSONALIZADOS
// ------------------------------------------------------------

colores = [
     37  99 235;
     22 163  74;
    220  38  38;
    147  51 234
]/255;

// ------------------------------------------------------------
// 7. FUNCION PARA GRAFICAS COMPARATIVAS
// ------------------------------------------------------------

function dibujar(numero,T,Y,titulo,ejeY,colores)

    scf(numero);
    clf();

    f = gcf();
    f.color_map = [f.color_map; colores];

    nc = size(f.color_map,1);

    a = gca();
    a.auto_clear = "off";

    for k = 1:4

        plot(T(k),Y(k));

        p = gce();
        p.children.foreground = nc-4+k;
        p.children.thickness = 2;

    end

    a.auto_clear = "on";

    xtitle(titulo,"Tiempo alineado (s)",ejeY);

    legend("LQR","Polos","Integral","LQI");

    xgrid();

endfunction

// ============================================================
// FIGURA 20 - RESPUESTAS EXPERIMENTALES
// ============================================================

dibujar(20,T,X, ...
    "Comparacion de respuestas X2", ...
    "Salida X2 (V)",colores);

// ============================================================
// FIGURA 21 - ACCIONES DE CONTROL
// ============================================================

dibujar(21,T,U, ...
    "Comparacion de acciones de control", ...
    "Accion de control U (V)",colores);

// ============================================================
// FIGURA 22 - ERRORES DE SEGUIMIENTO
// ============================================================

dibujar(22,T,E, ...
    "Comparacion de errores", ...
    "Error de seguimiento (V)",colores);

// ============================================================
// FIGURA 23 - REFERENCIAS EXPERIMENTALES
// ============================================================

dibujar(23,T,R, ...
    "Referencias experimentales alineadas", ...
    "Referencia (V)",colores);

// ============================================================
// 8. INDICADORES EXPERIMENTALES
// ============================================================

// Se calcula el error absoluto medio y el RMSE
// de las señales filtradas.
//
// Estos indicadores son descriptivos.
// No equivalen a una comparacion de igual duracion.

disp("============================================");
disp("INDICADORES EXPERIMENTALES FILTRADOS");
disp("============================================");

for k = 1:4

    ek = E(k);

    mae = mean(abs(ek));
    rmse = sqrt(mean(ek.^2));

    mprintf("%s: MAE = %.5f V | RMSE = %.5f V\n", ...
            nombres(k),mae,rmse);

end

// ============================================================
// 9. EXPORTAR GRAFICAS
// ============================================================

xs2png(20,carpeta+"FINAL_Comparacion_X2.png");

xs2png(21,carpeta+"FINAL_Comparacion_Control.png");

xs2png(22,carpeta+"FINAL_Comparacion_Error.png");

xs2png(23,carpeta+"FINAL_Comparacion_Referencias.png");

// ============================================================
// 10. FINAL
// ============================================================

disp("============================================");
disp("COMPARACION FINALIZADA");
disp("LAS CUATRO GRAFICAS FUERON GUARDADAS");
disp("============================================");
