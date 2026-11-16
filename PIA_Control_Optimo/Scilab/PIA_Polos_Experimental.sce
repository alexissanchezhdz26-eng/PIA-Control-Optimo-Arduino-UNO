
clc;
clear;
clf();

// PIA CONTROL OPTIMO - FIME UANL
// MODO 2 - ASIGNACION DE POLOS
// PRUEBA EXPERIMENTAL REAL

archivo = "C:\Users\marco\Documents\PIA_Control_Optimo\PIA_Polos_Experimental_Limpio.csv";

datos = csvRead(archivo, ",", ".", "double", [], [], [], 1);

t = (datos(:,1)-datos(1,1))/1000;
r = datos(:,3);
x1 = datos(:,4);
x2 = datos(:,5);
u = datos(:,6);

// FIGURA 1: REFERENCIA Y RESPUESTA
scf(1);
clf();
plot(t,[r x2]);
xtitle("Polos - Respuesta experimental", ...
       "Tiempo (s)", "Voltaje (V)");
legend("Referencia","X2 experimental");
xgrid();

// FIGURA 2: ESTADOS
scf(2);
clf();
plot(t,[x1 x2]);
xtitle("Polos - Estados experimentales", ...
       "Tiempo (s)", "Voltaje (V)");
legend("X1","X2");
xgrid();

// FIGURA 3: ACCION DE CONTROL
scf(3);
clf();
plot(t,u);
xtitle("Polos - Accion de control", ...
       "Tiempo (s)", "U (V)");
xgrid();

// FIGURA 4: ERROR DE SEGUIMIENTO
scf(4);
clf();
plot(t,r-x2);
xtitle("Polos - Error de seguimiento", ...
       "Tiempo (s)", "Error (V)");
xgrid();

disp("Graficas del modo 2 generadas.");
