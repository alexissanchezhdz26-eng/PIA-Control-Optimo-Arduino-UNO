
 // ==========================================================
 // PIA CONTROL OPTIMO - FIME UANL
 // Planta RC de segundo orden
 //
 // R1 = R2 = R3 = 1 MOhm
 // C1 = C2 = 1 uF
 //
 // Controladores:
 // 1. LQR
 // 2. Asignacion de polos
 // 3. Control integral
 // 4. LQI
 //
 // NOTA: Resultados de simulacion, no mediciones reales.
 // ==========================================================

clc;
clear;
clf();

// ==========================================================
// 1. SOLUCION DE RICCATI MEDIANTE HAMILTONIANA
// ==========================================================

function [K,P] = care_hamilton(A,B,Q,R)

    n = size(A,1);

    H = [A, -B*(R\B');
        -Q, -A'];

    [V,D] = spec(H);

    lambda = diag(D);

    idx = find(real(lambda) < -1.0d-9);

    if size(idx,"*") <> n then
        error("No se encontraron n polos estables");
    end

    V1 = V(1:n,idx);
    V2 = V(n+1:2*n,idx);

    P = real(V2/V1);

    P = (P+P')/2;

    K = real((R\B')*P);

endfunction

// ==========================================================
// 2. MODELO MATEMATICO DE LA PLANTA RC
// ==========================================================

A = [-2, 1;
      1,-2];

B = [1;
     0];

C = [0,1];

D = 0;

// ==========================================================
// 3. PARAMETROS DEL CONTROL OPTIMO
// ==========================================================

Q = diag([1,5]);

R = 1;

Ts = 0.02;

Tf = 20;

N = round(Tf/Ts);

r = 0.5;

umax = 5;

// ==========================================================
// 4. CONTROLADOR LQR
// ==========================================================

[K,P] = care_hamilton(A,B,Q,R);

// ==========================================================
// 5. CONTROLADOR POR ASIGNACION DE POLOS
// ==========================================================

Kp = [1,1];

// ==========================================================
// 6. CONTROLADOR INTEGRAL
// ==========================================================

// Polos deseados:
// -0.8, -1.5, -2.5

Kint = [0.8,2.35];

Kiint = 3;

// ==========================================================
// 7. CONTROLADOR LQI
// ==========================================================

Aa = [A,zeros(2,1);
     -C,0];

Ba = [B;
      0];

[Kai,Pai] = care_hamilton( ...
    Aa,Ba,diag([1,5,2]),1);

Kli = Kai(1,1:2);

Kii = -Kai(3);

// ==========================================================
// 8. MOSTRAR RESULTADOS EN CONSOLA
// ==========================================================

mprintf("====================================\n");
mprintf("MODELO DE LA PLANTA\n");
mprintf("====================================\n");

mprintf("MATRIZ A:\n");
disp(A);

mprintf("MATRIZ B:\n");
disp(B);

mprintf("MATRIZ C:\n");
disp(C);

mprintf("====================================\n");
mprintf("CONTROLADOR LQR\n");
mprintf("====================================\n");

mprintf("MATRIZ Q:\n");
disp(Q);

mprintf("MATRIZ R:\n");
disp(R);

mprintf("MATRIZ P DE RICCATI:\n");
disp(P);

mprintf("GANANCIA K DEL LQR:\n");
disp(K);

mprintf("POLOS DEL LQR:\n");
disp(spec(A-B*K));

mprintf("====================================\n");
mprintf("OTROS CONTROLADORES\n");
mprintf("====================================\n");

mprintf("GANANCIA POR POLOS:\n");
disp(Kp);

mprintf("GANANCIA INTEGRAL:\n");
disp(Kint);

mprintf("Ki INTEGRAL:\n");
disp(Kiint);

mprintf("GANANCIA LQI:\n");
disp(Kli);

mprintf("Ki LQI:\n");
disp(Kii);

// ==========================================================
// 9. DISCRETIZACION EXACTA
// ==========================================================

Ad = expm(A*Ts);

Bd = A\((Ad-eye(2,2))*B);

// ==========================================================
// 10. VARIABLES DE SIMULACION
// ==========================================================

t = (0:N)'*Ts;

X1 = zeros(N+1,4);

X2 = zeros(N+1,4);

U = zeros(N+1,4);

J = zeros(N+1,4);

// ==========================================================
// 11. SIMULACION DE LOS CUATRO CONTROLADORES
// ==========================================================

for j = 1:4

    x = [0;0];

    z = 0;

    costo_anterior = 0;

    if j == 1 then
        kx = K;
        ki = 0;
    end

    if j == 2 then
        kx = Kp;
        ki = 0;
    end

    if j == 3 then
        kx = Kint;
        ki = Kiint;
    end

    if j == 4 then
        kx = Kli;
        ki = Kii;
    end

    for i = 1:N+1

        // Variables de desviacion
        e = x-[2*r;r];

        // Ley de control
        ufree = 3*r-kx*e+ki*z;

        // Saturacion
        uclip = max(0,min(umax,ufree));

        // Conversion PWM
        pwm = round(255*uclip/umax);

        u = umax*pwm/255;

        // Guardar resultados
        X1(i,j) = x(1);

        X2(i,j) = x(2);

        U(i,j) = u;

        // Indice de desempeno
        if i > 1 then
            J(i,j) = J(i-1,j)+Ts*costo_anterior;
        end

        costo_anterior = e'*Q*e+(u-3*r)^2;

        // Error de seguimiento
        err = r-x(2);

        // Control integral con antiwindup
        if (ki > 0) & ...
           ~((ufree > umax & err > 0) | ...
             (ufree < 0 & err < 0)) then

            z = max(-3,min(3,z+Ts*err));

        end

        // Actualizar estados
        x = Ad*x+Bd*u;

    end

end

// ==========================================================
// 12. INDICES DE DESEMPENO
// ==========================================================

mprintf("====================================\n");
mprintf("INDICES DE DESEMPENO SIMULADOS\n");
mprintf("====================================\n");

mprintf("Orden: LQR / Polos / Integral / LQI\n");

disp(J($,:));

// ==========================================================
// 13. GRAFICA DE RESPUESTAS
// ==========================================================

nombres = ["LQR","Polos","Integral","LQI"];

scf(1);
clf();

plot(t,X2);
plot(t,r*ones(t));

xtitle( ...
    "Comparacion de respuestas de controladores (SIMULACION)", ...
    "Tiempo (s)", ...
    "x2 (V)" ...
);

legend("LQR","Polos","Integral","LQI","Referencia");

xgrid();

// ==========================================================
// 14. GRAFICA DE ACCIONES DE CONTROL
// ==========================================================

scf(2);
clf();

plot(t,U);

xtitle( ...
    "Comparacion de acciones de control (SIMULACION)", ...
    "Tiempo (s)", ...
    "u (V)" ...
);

legend(nombres(1),nombres(2),nombres(3),nombres(4));

xgrid();

// ==========================================================
// 15. GRAFICA DEL ESTADO X1
// ==========================================================

scf(3);
clf();

plot(t,X1);

xtitle( ...
    "Trayectoria de x1 (SIMULACION)", ...
    "Tiempo (s)", ...
    "x1 (V)" ...
);

legend(nombres(1),nombres(2),nombres(3),nombres(4));

xgrid();

// ==========================================================
// 16. GRAFICA DEL INDICE DE DESEMPENO
// ==========================================================

scf(4);
clf();

plot(t,J);

xtitle( ...
    "Indice J acumulado (SIMULACION)", ...
    "Tiempo (s)", ...
    "J(0,t)" ...
);

legend(nombres(1),nombres(2),nombres(3),nombres(4));

xgrid();

// ==========================================================
// 17. EXPORTACION DE RESULTADOS
// ==========================================================

S = [t,X1,X2,U,J];

csvWrite(S,"PIA_simulacion_scilab.csv");

mprintf("====================================\n");
mprintf("SIMULACION FINALIZADA\n");
mprintf("====================================\n");
