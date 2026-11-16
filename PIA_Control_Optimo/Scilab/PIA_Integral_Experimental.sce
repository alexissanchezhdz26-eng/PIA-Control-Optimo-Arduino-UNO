
clc;
clear;
clf();

// PIA CONTROL OPTIMO - FIME UANL
// MODO 3 - CONTROL INTEGRAL
// RESULTADOS EXPERIMENTALES

archivo = "C:/Users/marco/OneDrive/Documentos/PIA_Control_Optimo/PIA_Integral_Experimental_Limpio.csv";

if ~isfile(archivo) then
    error("No se encontro el archivo CSV.");
end

datos = csvRead(archivo, ",", ".", "double", [], [], [], 1);

t = (datos(:,1)-datos(1,1))/1000;
modo = datos(:,2);
r = datos(:,3);
x1 = datos(:,4);
x2 = datos(:,5);
u = datos(:,6);

if or(modo <> 3) then
    error("El CSV contiene registros de otro modo.");
end

// FIGURA 1: RESPUESTA EXPERIMENTAL
scf(1);
clf();
plot(t,[r x2]);
xtitle("Integral - Respuesta experimental", ...
       "Tiempo (s)", "Voltaje (V)");
legend("Referencia","X2 experimental");
xgrid();

// FIGURA 2: ESTADOS
scf(2);
clf();
plot(t,[x1 x2]);
xtitle("Integral - Estados experimentales", ...
       "Tiempo (s)", "Voltaje (V)");
legend("X1","X2");
xgrid();

// FIGURA 3: ACCION DE CONTROL
scf(3);
clf();
plot(t,u);
xtitle("Integral - Accion de control", ...
       "Tiempo (s)", "U (V)");
xgrid();

// FIGURA 4: ERROR
scf(4);
clf();
plot(t,r-x2);
xtitle("Integral - Error de seguimiento", ...
       "Tiempo (s)", "Error (V)");
xgrid();

disp("MODO 3: GRAFICAS GENERADAS CORRECTAMENTE");
