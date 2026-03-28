function [cost, p, coll, ratiofull, pcoll, amountless,amountmore] = costFcn_periodical(x,TT,params)
% COSTFCN_SLOW  Vyhodnocení ztrátové funkce pro nádoby s pomalým plněním.
% 
%    [cost, p, coll, ratiofull, pcoll, amountless, amountmore] = ...
%           COSTFCN_PERIODICAL(x, TT, params)
%    provádí simulaci úrovně zaplnění pomalu se plnící odpadové nádoby
%    při periodickém svozovém plánu definovaném vektorem x = [p d h]
%    a vyhodnocuje ztrátovou funkci založenou na metrikách nevyužité a
%    překročené kapacity.
% 
%    Funkce simuluje stav zaplnění nádoby po celou dobu trvání dat
%    (časová řada TT) tak, že se do signálu aplikují detekované
%    přírůstky dp a v okamžicích, kdy podle ohodnocovaného plánu x
%    nastane svoz, se úroveň zaplnění nastaví na hodnotu odpovídající
%    typickému poklesu získanému z historických dat (params.timec,
%    params.level_after). Na základě výsledného průběhu zaplnění jsou
%    spočteny metriky UNUSED CAPACITY (amountless) a MISSED CAPACITY
%    (amountmore), které společně tvoří výslednou cenu cost.
% 
%    Vstupní parametry:
%        x              - double (1x3)
%                         Periodický svozový plán ve formě [p d h], kde
%                            p je perioda svozů v týdnech,
%                            d je den v týdnu (1 = pondělí, …, 7 = neděle),
%                            h je hodina ve dni (0–23).
%                         Tento plán určuje, kdy bude nádoba vyvezena.
% 
%        TT             - timetable (Nx2)
%                         Časová řada s hlavičkou:
%                             Time : datetime
%                             p    : aktuální úroveň zaplnění (%)
%                             dp   : množství uloženého odpadu mezi vzorky (%)
%                         Slouží jako základ simulace plnění nádoby.
% 
%        params         - struct se strukturou:
%                            params.timec       – časové body historických svozů
%                            params.level_after – úroveň zaplnění po historických svozech
%                            params.alesscurr   – stávající hodnota UNUSED CAPACITY
%                            params.amorecurr   – stávající hodnota MISSED CAPACITY
%                         Hodnoty timec a level_after jsou využity k realistické
%                         simulaci poklesu úrovně zaplnění při svozu.
% 
%    Výstupní parametry:
%        cost           - double
%                         Výsledná hodnota ztrátové funkce. Kombinuje penalizaci
%                         nevyužité kapacity (předčasné svozy), překročené kapacity
%                         (pozdní svozy) a případnou penalizaci oproti
%                         současnému stavu (params.alesscurr, params.amorecurr).
% 
%        p              - double (Nx1)
%                         Simulovaná úroveň zaplnění nádoby po celé období.
% 
%        coll           - logical (Nx1)
%                         Indikátory simulovaných svozů podle plánu x.
% 
%        ratiofull      - double
%                         Poměr vzorků, ve kterých byla nádoba zaplněna
%                         alespoň na 100 %. Indikátor frekvence přeplnění.
% 
%        pcoll          - double (Kx1)
%                         Úrovně zaplnění bezprostředně před jednotlivými
%                         simulovanými svozy.
% 
%        amountless     - double
%                         Celkové množství nevyužité kapacity (UNUSED CAPACITY),
%                         tj. kolikrát a o kolik procentních bodů byla nádoba
%                         vyvezena předčasně.
% 
%        amountmore     - double
%                         Celkové množství překročené kapacity (MISSED CAPACITY),
%                         tj. kolikrát a o kolik procentních bodů došlo
%                         k přeplnění nádoby.
% 
%    Poznámky:
%        • Simulace předpokládá, že nádoba je vyvezena vždy v okamžiku,
%          kdy v daném týdnu a čase odpovídajícím plánu x nastane svoz.
%        • Pokles úrovně zaplnění po svozu je modelován pomocí
%          nejbližšího historického pozorování (params.level_after),
%          aby byla zachována realistická dynamika vyprázdnění.
%        • Funkce je určena pro pomalu se plnící nádoby, u nichž je
%          optimální hledat periodické plány typu „jednou za p týdnů“.
% 

xperiod = x(1);
xweekday = x(2);
xdayhour = x(3);

t=TT.Time;
n=size(TT,1);
pi=TT.p(1);pall=[pi;zeros(n-1,1)];coll=logical(zeros(n,1));
%weekcount=0;
%This computes the initial value of weekcount to make the simulation similar to reality 
wdc=weekday(params.timec);
time_first = params.timec(find(wdc==mode(wdc),1));%First collection in the most frequent collection weekday
weekcount=xperiod-round(mod(days(time_first-t(1))/7,xperiod));

%Simulation
for i=2:n
    %if i>3650,keyboard;end;
    pi=pi+TT.dp(i); %Increase the level by the amount of disposed waste
    if pi<=0,pi=0;end %Saturate level on zero
    if and(weekday(t(i))==xweekday,weekday(t(i-1))~=xweekday)
        weekcount = weekcount + 1;
    end
    %if weekcount == xperiod%If there is the xperiodth week, check the hour 
    if weekcount >= xperiod%If there is the xperiodth week, check the hour 
        if and(hour(t(i-1))<=xdayhour,xdayhour<=hour(t(i)))
        %if hour(t(i)) == xdayhour
            [~, j] = min(abs(params.timec - t(i)));
            pi = params.level_after(j);
            weekcount = 0;
            coll(i-1)=true;
        end

    end
    pall(i)=pi;
end
p = pall;


%Levels right before collection
pcoll = p(coll);


amountless = sum(100-pcoll(pcoll<100));
amountmore = sum(pcoll(pcoll>100)-100); 
if coll(end)==0,amountmore = amountmore + max(p(end)-100,0);end
ratiofull = mean(p>=100);



w=0.5;
cost = w*amountless+(1-w)*amountmore;

%cost = (w*amountless+(1-w)*amountmore)+100*(max(amountless-params.alesscurr,0)+max(amountmore-params.amorecurr,0));
%cost = w*(amountless-params.alesscurr)+(1-w)*(amountmore-params.amorecurr);
% disp('-----------------------------------------------------------')
% disp(xperiod);
% % disp(cost);
% % figure;plot(TT.Time,TT.p,'.-');hold on;plot(TT.Time,p,'m.-');ylim([0 150]);
% disp(x);
% disp([amountless amountmore]); 
% disp('------------------------------------------------------');

end
