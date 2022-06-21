clear; close all;
%Ripuliamo l'area di lavoro;

%{ 
PROGETTO FONDAMENTI DI AUTOMATICA
Michele Purrone mat. 201181
%}

%{
Quesito D
Si chiede di determinare un regolatore C(s) di struttura semplice che garantisca il soddisfacimento delle seguenti specifiche:
1. errore di inseguimento al gradino non superiore al 5%;
2. Picco di Risonanza Mr,dB <= 3 dB, banda passante 1 <= w_bw <= 4 rad/s;
%}

%{
Dopo aver svolto il punto 1. su Maple, abbiamo trovato una F. D. T. 
del controllore C(s) compatibile con la prima specifica
ovvero C(s) = K, con K > 19: abbiamo posto C(s) = 19.5.
%}

%{
Generiamo la funzione di trasferimento G(s) dell'impianto usando il comando di 
MATLAB "zpk":
%}

s = zpk('s');
G = 9/(((s + 1)^2)*((s + 9)))

%Il controllore sarà:

C = 19.5;

%{
Tramite il comando di MATLAB "series" possiamo generare la cascata fra
impianto e controllore andando così a generare la funzione di anello L(s):
%}

L = series(C, G)

%{
Come richiesto dalla traccia, dobbiamo modellare il sistema mediante una rete correttrice posta in
cascata alla funzione di anello che ci faccia ottenere un picco di
risonanza in dB inferiore a 3 dB ed una pulsazione di banda passante
compresa fra 1 e 4 rad/sec.
Questo tipo di problema è legato alla precisione dinamica e per risolverlo
ragiono, almeno per il momento, in una logica EX-ANTE, ovvero prima di chiudere l'anello
in retroazione.
%}

%Come primo step andiamo ad analizzare il margine di fase della funzione di anello:

figure(1);
margin(L); 
grid; 
legend;

%{
La funzione di anello ha margine di fase positivo (3.01°) e quindi è BIBO
stabile; otteniamo, inoltre, una pulsazione di attraversamento wc pari a 4.36 rad/sec.

Per quanto riguarda il requisito sul picco di risonanza, va innanzitutto
individuato lo smorzamento critico delta_cr che risponde ad un picco di
risonanza pari a 3 dB. Utilizziamo la funzione fornitaci "smorz_Mr":
%}

delta_cr = smorz_Mr(3)

%{
Otteniamo un delta_cr = 0.38. Sappiamo inoltre dalla teoria che il picco di risonanza 
e lo smorzamento sono inversamente proporzionali: 
se il primo aumenta allora il secondo diminuisce.

Per rispettare questa specifica dovremo scegliere uno smorzamento di
progetto maggiore di delta_cr.
Trovandoci, come detto precedentemente, in una logica EX-ANTE traduciamo questo nuovo vincolo in un
requisito sul margine di fase utilizzando la relazione:

phi_m >= 100*delta_cr => 100*0.38 = 38° >= phi_m >= 38°

Per lo stesso motivo possiamo tradurre il vincolo sulla pulsazione di banda
passante in un requisito sulla pulsazione di attraversamento: siamo in grado di farlo
poiché la pulsazione di attraversamento è un minorante della pulsazione di
banda passante (w_bw > w_c).

Alla fine, quindi, otteniamo due nuove specifiche (di progetto)
da verificare successivamente a sistema retroazionato:

1. phi_m >= 38°
2. 1 <= w_c <= 4 rad/sec

Scegliamo un margine di fase di progetto pari a 42° e la pulsazione di
attraversamento di progetto:
%}

wc_new = 2;

%{
Valutiamo adesso la funzione di anello non compensata in corrispondenza di questa
nuova pulsazione di attraversamento.
Salviamo poi in due variabili il modulo e la fase della funzione di
anello.
Rappresentiamo il diagramma di Bode usando il comando "bode" di
MATLAB:
%}

[modulo, fase] = bode(L,wc_new)

phi_m_iniz = 180 - abs(fase)

%{
Calcoliamo, a partire dalla fase ottenuta, il margine di fase iniziale (distanza goniometrica):
%}

theta = 42 - (phi_m_iniz)

%{
Otteniamo un modulo maggiore dell'unità e theta minore del margine di fase di
progetto richiesto che è 42°.

Abbiamo perciò bisogno di una rete che ATTENUI sui moduli e che ANTICIPI sulle fasi:
questa particolare rete è nota come rete a SELLA (o rete ANTICIPO-ATTENUAZIONE).
Essa è formata da una componente di attenuazione ed una di anticipo:


           1 + s*alpha*T1         1 + s*T2
C_d(s) = ------------------ * ------------------  , T1, T2 > 0 e  
             1 + s*T1           1 + s*alpha*T2      0 < alpha < 1

            ATTENUAZIONE          ANTICIPO

.T1 e T2 positivi poiché la rete deve essere comunque BIBO-STABILE.
%}

%{
Iniziamo a progettare la rete partendo dal calcolo del reciproco del modulo
della funzione di anello non compensata valutata in corrispondenza della
pulsazione di attraversamento wc_new: ci servirà per valutare
l'attenuazione necessaria. Procediamo:
%}

m = 1/modulo;

%{
Tramite la funzione fornitaci "sella" andiamo a generare i parametri della rete: 
alpha, T1 e T2
%}

K = 30;
[alpha, T1, T2] = sella(wc_new, m, theta, K)

%{
Come prova, prima di verificare graficamente che la rete proposta sia
efficace, assicuriamoci che la pulsazione di attraversamento di progetto
scelta vada a ricadere tra 1/T2 ed 1/(alpha*T2) in modo da ottenere un
effetto di anticipo ed attenuazione:
%}

if (1/T2 < wc_new < 1/(alpha*T2))
    disp ('La pulsazione wc_new ricade nell''intervallo proposto');
end;


%Costruiamo quindi la rete:

C_d = ((1 + s*alpha*T1)/(1 + s*T1))*((1 + s*T2)/(1 + s*alpha*T2))

%{
A questo punto possiamo generare la funzione di anello compensata inserendo
la rete a sella in cascata alla funzione di anello. Fatto ciò potremo
effettuare un'analisi in una logica EX-POST e verificare i requisiti richiesti
dal quesito:
%}

L_comp = series(series(C, G), C_d)

%{
Rappresentiamo graficamente la funzione di anello non compensata e quella
compensata per vedere le differenze:
%}

figure(2);
margin(L); 
hold on; 
margin(L_comp); 
grid; 
legend;

%{
A questo punto generiamo la funzione di trasferimento del sistema
retroazionato per verificarne i parametri:
%}

T = feedback(L_comp, 1)

%Disegnamo il diagramma di Bode (moduli):

figure(3);
bodemag(T); 
grid; 
legend;

%{
Otteniamo così un picco di risonanza pari a 2.9083 dB ed una pulsazione di
banda passante pari a 3.2633 rad/sec.
Ciò è verificabile anche tramite delle funzioni di MATLAB ("mag2db", "getPeakGain" ecc.):
%}

M_r = mag2db(getPeakGain(T))

w_bw = bandwidth(T)
