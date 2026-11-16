
clc;
clear;
clf();

// =====================================================
// PIA CONTROL OPTIMO - FIME UANL
// MODO 1 - CONTROLADOR LQR
// RESULTADOS EXPERIMENTALES
// =====================================================

archivo = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/PIA_LQR_Experimental_Limpio.csv";

if ~isfile(archivo) then
    error("No se encontro el archivo CSV.");
end

// Columnas: t_ms,modo,r,x1,x2,u,pwm
datos = csvRead(archivo, ",", ".", "double", [], [], [], 1);

t = (datos(:,1)-datos(1,1))/1000;
modo = datos(:,2);
r = datos(:,3);
x1 = datos(:,4);
x2 = datos(:,5);
u = datos(:,6);
pwm = datos(:,7);

if or(modo <> 1) then
    error("El CSV contiene registros de otro modo.");
end

// FIGURA 1 - RESPUESTA EXPERIMENTAL
scf(1);
clf();
plot(t,[r x2]);
xtitle("LQR - Respuesta experimental", ...
       "Tiempo (s)", "Voltaje (V)");
legend("Referencia","X2 experimental");
xgrid();

// FIGURA 2 - ESTADOS EXPERIMENTALES
scf(2);
clf();
plot(t,[x1 x2]);
xtitle("LQR - Estados experimentales", ...
       "Tiempo (s)", "Voltaje (V)");
legend("X1","X2");
xgrid();

// FIGURA 3 - ACCION DE CONTROL
scf(3);
clf();
plot(t,u);
xtitle("LQR - Accion de control", ...
       "Tiempo (s)", "U (V)");
xgrid();

// FIGURA 4 - ERROR DE SEGUIMIENTO
scf(4);
clf();
e = r-x2;
plot(t,e);
xtitle("LQR - Error de seguimiento", ...
       "Tiempo (s)", "Error (V)");
xgrid();

// RESULTADOS
disp("==================================");
disp("PIA CONTROL OPTIMO - LQR");
disp("==================================");

disp("Numero de muestras:");
disp(size(datos,1));

disp("Duracion experimental (s):");
disp(t($));

disp("Error absoluto medio (V):");
disp(mean(abs(e)));

disp("GRAFICAS GENERADAS CORRECTAMENTE");
