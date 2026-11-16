
clc;
clear;
clf();

// =====================================================
// PIA CONTROL OPTIMO - FIME UANL
// MODO 4 - CONTROLADOR LQI
// RESULTADOS EXPERIMENTALES DE ARDUINO
// =====================================================

// RUTA DEL ARCHIVO CSV
archivo = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/PIA_LQI_Experimental_Limpio.csv";

// VERIFICAR QUE EXISTA
if ~isfile(archivo) then
    error("ERROR: No se encontro el archivo CSV.");
end

// LEER LOS DATOS
// Columnas: t_ms,modo,r,x1,x2,u,pwm
datos = csvRead(archivo, ",", ".", "double", [], [], [], 1);

// EXTRAER VARIABLES
t = (datos(:,1) - datos(1,1))/1000;
modo = datos(:,2);
r = datos(:,3);
x1 = datos(:,4);
x2 = datos(:,5);
u = datos(:,6);
pwm = datos(:,7);

// VERIFICAR MODO 4
if or(modo <> 4) then
    error("El archivo contiene datos de otro modo.");
end

// =====================================================
// FIGURA 1 - RESPUESTA EXPERIMENTAL
// =====================================================
scf(1);
clf();

plot(t,[r x2]);

xtitle("LQI - Respuesta experimental", ...
       "Tiempo (s)", "Voltaje (V)");

legend("Referencia","X2 experimental");
xgrid();

// =====================================================
// FIGURA 2 - ESTADOS EXPERIMENTALES
// =====================================================
scf(2);
clf();

plot(t,[x1 x2]);

xtitle("LQI - Estados experimentales", ...
       "Tiempo (s)", "Voltaje (V)");

legend("X1","X2");
xgrid();

// =====================================================
// FIGURA 3 - ACCION DE CONTROL
// =====================================================
scf(3);
clf();

plot(t,u);

xtitle("LQI - Accion de control", ...
       "Tiempo (s)", "U (V)");

xgrid();

// =====================================================
// FIGURA 4 - ERROR DE SEGUIMIENTO
// =====================================================
scf(4);
clf();

error_seguimiento = r-x2;

plot(t,error_seguimiento);

xtitle("LQI - Error de seguimiento", ...
       "Tiempo (s)", "Error (V)");

xgrid();

// =====================================================
// RESULTADOS EN CONSOLA
// =====================================================
disp("======================================");
disp("PIA CONTROL OPTIMO - MODO 4 LQI");
disp("======================================");

disp("Numero de muestras:");
disp(size(datos,1));

disp("Duracion del experimento (s):");
disp(t($));

disp("Error absoluto medio (V):");
disp(mean(abs(error_seguimiento)));

disp("======================================");
disp("CUATRO GRAFICAS GENERADAS");
disp("======================================");
