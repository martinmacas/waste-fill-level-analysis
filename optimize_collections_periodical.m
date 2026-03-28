function [popt, pcurr, topt, tcurr, costopt, costcurr, alessopt,alesscurr, amoreopt, amorecurr,TT,xopt,xcurr,copt,ccurr]= optimize_collections_periodical(Time, p,schedule,cdetected,level_after)
% OPTIMIZE_COLLECTIONS_PERIODICAL  Optimalizace periodického svozového plánu 
%                                  pro nádoby na sklo a pomalu se plnící nádoby.
% 
%    [popt, pcurr, topt, tcurr, costopt, costcurr, ...
%     alessopt, alesscurr, amoreopt, amorecurr, ...
%     TT, xopt, xcurr, copt, ccurr] = ...
%         OPTIMIZE_COLLECTIONS_PERIODICAL(Time, p, schedule, cdetected, level_after)
% 
%    provádí optimalizaci periodického svozového plánu odpadové nádoby, 
%    která se plní pomalým tempem (typicky nádoby na sklo). Svozový plán 
%    je reprezentován trojicí [P D H], kde P je perioda svozu v týdnech, 
%    D je den v týdnu a H je hodina ve dni. Funkce nejprve vyhodnotí 
%    současný plán, následně zkouší periodu prodloužit i zkrátit při 
%    zachování stejného dne a hodiny, a vybere periodu, která minimalizuje 
%    výslednou ztrátovou funkci (<a href="costFcn_periodical.html">costFcn_periodical</a>).  
% 
%    Plnění nádoby je simulováno na základě časové řady úrovně zaplnění p 
%    a odhadnutých přírůstků dp. V okamžicích simulovaných svozů se úroveň 
%    nastaví podle historických hodnot poklesu (level_after). Metriky 
%    UNUSED CAPACITY (aless) a MISSED CAPACITY (amore) jsou vyhodnoceny 
%    pomocí funkce <a href="costFcn_periodical.html">costFcn_periodical</a>.
% 
%    Vstupní parametry:
%        Time          - datetime (Nx1)
%                        Časová osa měření úrovně zaplnění nádoby.
% 
%        p             - double (Nx1)
%                        Naměřený průběh zaplnění nádoby v procentech.
% 
%        schedule      - double (1x3)
%                        Současný periodický svozový plán ve tvaru:
%                            [P D H], kde
%                            P – perioda v týdnech,
%                            D – den v týdnu (1 = Po, …, 7 = Ne),
%                            H – hodina ve dni (0–23).
% 
%        cdetected     - logical/double (Nx1)
%                        Indikátory detekovaných historických svozů.
% 
%        level_after   - double (Kx1)
%                        Úroveň zaplnění po každém historickém svozu
%                        (např. medián nebo typická hodnota po vyprázdnění).
% 
%    Výstupní parametry:
%        popt          - double (Nx1)
%                        Simulovaná úroveň zaplnění pro optimalizovaný plán.
% 
%        pcurr         - double (Nx1)
%                        Simulovaná úroveň zaplnění pro současný plán.
% 
%        topt          - char/string
%                        Řetězcová reprezentace optimalizovaného času svozu
%                        (volitelný výstup; v této implementaci ponechán prázdný).
% 
%        tcurr         - char/string
%                        Řetězcová reprezentace současného času svozu
%                        (volitelný výstup; v této implementaci ponechán prázdný).
% 
%        costopt       - double
%                        Ztrátová funkce pro optimalizovaný svozový plán.
% 
%        costcurr      - double
%                        Ztrátová funkce pro současný svozový plán.
% 
%        alessopt      - double
%                        UNUSED CAPACITY (nevyužitá kapacita) pro optimalizovaný plán.
% 
%        alesscurr     - double
%                        UNUSED CAPACITY pro současný plán.
% 
%        amoreopt      - double
%                        MISSED CAPACITY (překročená kapacita) pro optimalizovaný plán.
% 
%        amorecurr     - double
%                        MISSED CAPACITY pro současný plán.
% 
%        TT            - timetable
%                        Časová řada se signálem p a odhadnutými přírůstky dp
%                        po předzpracování (estimate_disposal).
% 
%        xopt          - double (1x3)
%                        Optimalizovaný svozový plán ve formě [P D H].
% 
%        xcurr         - double (1x3)
%                        Současný svozový plán po doplnění chybějících hodnot
%                        (pokud nebyl detekován den/čas, nastaví se výchozí hodnoty).
% 
%        copt          - logical (Nx1)
%                        Indikátory simulovaných svozů podle xopt.
% 
%        ccurr         - logical (Nx1)
%                        Indikátory simulovaných svozů podle xcurr.
% 
%    Popis algoritmu:
%        • Z dat jsou identifikovány historické svozy a z jejich časů a úrovní
%          vyprázdnění se vytváří struktura params obsahující typický pokles
%          zaplnění po svozu.
% 
%        • Je vyhodnocen současný periodický plán [P D H] pomocí 
%          <a href="costFcn_periodical.html">costFcn_periodical</a> a zjištěna jeho současná výkonost.
% 
%        • Následně je zkoušeno:
%             – zvětšování periody (P → P+1) dokud nedojde k nedovolenému
%               nárůstu MISSED CAPACITY nebo poklesu počtu svozů,
%             – zmenšování periody (P → P−1) dokud nedojde k nedovolenému
%               nárůstu UNUSED CAPACITY nebo příliš nízkému počtu svozů.
% 
%        • Porovnáním obou hraničních variant (P−1 a P+1) je vybrána varianta 
%          s nižší ztrátovou funkcí.
% 
%    Poznámky:
%        • Funkce je určena pro nádoby, které se plní pomalu a stabilně,
%          typicky kontejnery na sklo nebo kovy.
%        • Vyhodnocené metriky přirozeně závisí na délce období pokrytém daty.
%        • Toleranční parametry pro růst MISSED/UNUSED CAPACITY jsou nastaveny
%          konzervativně a lze je upravit podle potřeby.
% 

%Detect waste collections and after pick level
numcollections = length(schedule);
timec=Time(cdetected);

%Resample to hourly data using linear interp to make disposal smoother
TT=timetable(Time, p);

TT = estimate_disposal(TT,cdetected);

%Resample to hourly data using nearest interp to prevent stepwise decline
%during collection period
%TT=retime(timetable(Time, p),'hourly','nearest');
%TT.dp=dp;
%Evaluating current state
params.timec = timec;
params.level_after = level_after;
xcurr = schedule;%[schedule{1} schedule{2} schedule{3}];
if isnan(xcurr(2)), xcurr(2)=4;end %If weekday was not detected, set Wednesday (4)
if isnan(xcurr(3)), xcurr(3)=9;end %If hour of the day was not detected, set 9
params.alesscurr = 0;
params.amorecurr = 0;
wdc=weekday(timec); %weekdays of collections
time_first = timec(find(wdc==mode(wdc),1));%first collection in the most frequent collection weekday


[cost, p, coll, ratiofull, pcoll, UC,MC] = costFcn_periodical(xcurr,TT,params);
costcurr = cost;
pcurr = p;
ccurr = coll;
ratiofullcurr = ratiofull;
pcollcurr = pcoll;
alesscurr = UC;
amorecurr = MC;
xperiod = xcurr(1);xweekday = xcurr(2); xdayhour = xcurr(3);
%[costcurr, pcurr, ccurr, ratiofullcurr, pcollcurr,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
tolerance_MC = 40;
while 1
    [cost2, ~, coll, ~, ~, ~,MC2] = costFcn_periodical([xperiod+1 xweekday xdayhour],TT,params);
    %if or(MC2>MC,sum(coll)<2) 
    if or(MC2/(years(Time(end)-Time(1)))>(MC/(years(Time(end)-Time(1)))+tolerance_MC),sum(coll)<3)
        break
    else
        xperiod = xperiod+1;
        cost = cost2;
    end
    
end
xperiod_plus=xperiod;
cost_plus=cost;

xperiod = xcurr(1);
[cost, p, coll, ratiofull, pcoll, UC,MC] = costFcn_periodical([xperiod xweekday xdayhour],TT,params);
tolerance_UC = 5;%unit is container capacity in percents per year
while 1
    if xperiod == 1, break;end
    [cost2, ~, ~, ~, ~, UC2,~] = costFcn_periodical([xperiod-1 xweekday xdayhour],TT,params);
    %if UC2>UC %This is too strict so the next line give tolerance on the
    %container capacity per year (50 means half container per year)
    if or(UC2/(years(Time(end)-Time(1)))>(UC/(years(Time(end)-Time(1)))+tolerance_UC),sum(coll)<2)
    
        break
    else
        xperiod = xperiod-1;
        cost = cost2;
    end
    
end
xperiod_minus=xperiod;
cost_minus = cost;

%Evaluate current and optimized schedule
if cost_minus<cost_plus, 
    xopt = [xperiod_minus xweekday xdayhour];
else
    xopt = [xperiod_plus xweekday xdayhour];
end
[costopt, popt, copt, ratiofullopt, pcollopt, alessopt,amoreopt] = costFcn_periodical(xopt,TT,params);

tcurr = '';topt = '';
% tcurr= weekratio2weektime(xcurr)';
% tcurr = (datestr(tcurr,'ddd HH:MM'));
% topt=weekratio2weektime(xopt)';
% topt = datestr(topt,'ddd HH:MM');
