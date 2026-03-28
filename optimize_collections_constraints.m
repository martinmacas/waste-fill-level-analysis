function [popt, pcurr, topt, tcurr, costopt, costcurr, alessopt,alesscurr, amoreopt, amorecurr,TT,xopt,xcurr,copt,ccurr]= optimize_collections_constraints(Time, p,schedule,cdetected,level_after)
%OPTIMIZE_COLLECTIONS_CONSTRAINTS Optimalizuje týdenní časový rozvrh svozů odpadu za daných omezení.
%
%   [popt, pcurr, topt, tcurr, costopt, costcurr, alessopt, alesscurr, amoreopt, amorecurr, TT, xopt, xcurr, copt, ccurr] = ...
%       OPTIMIZE_COLLECTIONS_CONSTRAINTS(Time, p, schedule, cdetected, level_after)
%   
%   - Funkce nejprve odhadne množství odpadu, který je do nádoby uložen mezi každými dvěma časovými značkami (Time).
%   To je realizováno pomocí <a href="estimate_disposal.html">estimate_disposal</a>. 
% 
%   - Poté je definována ztrátová funkce a nastaveny parametry optimalizace. 
% 
%   - Dále je spuštěna optimalizace. Byly testovány dva optimalizátory - patternsearch.m a
%   particleswarm.m a v aktuální verzi je použita patternsearch.m protože je méně náročná a protože 
%   díky značné nepřesnosti celé simulace alternativních svozových rozvrhů
%   není nutné (ani žádoucí) hledat co nejlepší řešení. Dimensionality prohledávaného prostoru je navíc
%   velmi nízká (rovna týdennímu počtu svozů), takže postačí jednodušší optimalizační nástroj. 
%
%   Optimalizace je volána celkem 3x pro různé týdenní počty svozů. Pro aktuální počet svozů S, pro snížený počet svozů S-1 a pro zvýšený počet
%   svozů S+1. Poté je vybráno nejlepší řešení. 
%
%   Aby mohla být v optimalizaci (např. patternsearch, particleswarm v Matlabu) zohledněna intervalová omezení – například,
%   že svoz nesmí probíhat v nočních hodinách – je použita reparametrizace (transformace) proměnných. 
%   Namísto přímého použití času jako lineární weekfraction (0–1), která zahrnuje i zakázané intervaly, 
%   je definována nová kódovací funkce mapující oblast 0–1 pouze na povolené časové úseky. Tato funkce je po částech lineární,
%   avšak přes zakázané (noční) intervaly obsahuje skoky, takže jim nejsou přiřazeny žádné hodnoty weekfraction. 
%   Optimalizace je tím vedena jen v takové doméně, kde jsou všechny body konstrukčně přípustné, a není nutné používat 
%   explicitní penalizace za zakázané časy.
%
%   Ztrátová funkce (<a href="costFcn_constraints.html">costFcn_constraints</a> nebo <a href="costFcn.html">costFcn</a> je založena na výpočtu 
%   nevyužité kapacity (unused capacity, UC) a přetečení (missed capacity/overflow, MC)
%   pro daný stav svozu. Nejprve jsou spočítány UC a MC aktuálního (výchozího) stavu a při optimalizaci je pomocí penalizace
%   zajištěno, aby optimalizované UC i MC byly menší než původní hodnoty (tedy aby došlo ke zlepšení obou kritérií).
%   Samotná cílová funkce pak minimalizuje váženou kombinaci w·UC + (1–w)·MC, kde váha w určuje relativní důležitost
%   nevyužité kapacity vůči přetečení (w je v tuto chvíli 0.5).
%
% Vstupní parametry:
%   Time        - datetime (Nx1), časové značky vzorků.
%   p           - double (Nx1), stav zaplnění odpadové nádoby v procentech.
%   schedule    - double 1xS z <0,1>, podíl týdne (weekfraction), 0
%                 je začátek týdne a 1 je konec týdne (viz. weekratio)
%               - Očekávané časy v týdnu pro jednotlivé svozy 
%   cdetected   - logical (Nx1), indikátory detekovaných svozů.
%   level_after - double (Mx1), hodnoty zaplnění po svozu.
%
% Výstupní parametry:
%   popt        - double (Nx1), optimalizované hodnoty p.
%   pcurr       - double (Nx1), aktuální hodnoty p.
%   topt        - char array obsahující optimalizované časy svozů ve formátu den čas
%   tcurr       - char array obsahující aktuální časy svozů ve formátu den čas na každém řádku
%   costopt     - double (1x1), optimalizovaná hodnota nákladové funkce
%   costcurr    - double (1x1), aktuální hodnota hodnota nákladové funkce
%   alessopt    - double (1x1), optimalizovaná hodnota nevyužité kapacity (unused capacity, UC)
%   alesscurr   - double (1x1), aktuální hodnota nevyužité kapacity  (unused capacity, UC)
%   amoreopt    - double (1x1), optimalizovaná hodnota ztracené kapacity  (missed capacity, MC)
%   amorecurr   - double (1x1), aktuální hodnota ztracené kapacity  (missed capacity, MC)
%   TT          - timetable (Nx2), tabulka s hodnotami p a dp (odhadnuté
%                 množství uloženého odpadu mezi dvěma časovými značkami)
%   xopt        - optimalizovaný týdenní rozvrh
%                 double 1xSopt z <0,1>, podíl týdne (weekfraction), 0 je začátek týdne 
%                 a 1 je konec týdne (viz. weekratio)
%               - Sopt je počet svozů v optimálním rozvrhu
%               - optimalizované časy v týdnu pro jednotlivé svozy 
%              
%


%Detect waste collections and after pick level
%[c,cpresc, numcollections, schedule, afterpicklevel] = detect_collections(Time,p);
%[c, scores, threshold, level_after,level_before] = detect_collections_supervised(Time,p,[],schedule);
%afterpicklevel=mean(level_after);      

%Waste disposal estimation
numcollections = length(schedule);
timec=Time(cdetected);
TT=timetable(Time, p);
TT = estimate_disposal(TT,cdetected);

%Evaluating current state
params.timec = timec;
params.level_after = level_after;
xcurr = schedule;
params.alesscurr = 0;
params.amorecurr = 0;
[~, ~, ~, ~, ~,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
params.alesscurr = alesscurr;
params.amorecurr = amorecurr;

%Optimize
%f = @(x)costFcn(x,TT,params)   ;
f = @(x)costFcn_constraints(x,TT,params)   ;
dim=numcollections;
% 
% options=optimoptions("particleswarm");
% options.SwarmSize=50;
% xinit=constraint_encoding(xcurr,3,20);
% options.InitialSwarmMatrix=[xinit;rand(options.SwarmSize-1,dim)];
% options.PlotFcn='pswplotbestf';
% tic
% [xopt,fval] = particleswarm(f,dim,0.01*ones(1,dim),0.99*ones(1,dim),options);
% toc

options=optimoptions("patternsearch");
%options.PlotFcn = 'psplotbestf';
options.PlotFcn = [];
xinit=constraint_encoding(xcurr,3,20);
% xinit=rand(1,dim);
[xopt,fval] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);

%Snížení počtu svozů
dim=dim-1;
if dim>0
    %xinit=rand(1,dim);
    xinit(randi(dim))=[];
    [xopt_m1,fval_m1] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);
else
    fval_m1 = Inf;xopt_m1=NaN;
end

%Zvýšení počtu svozů
dim=dim+2;
%xinit=rand(1,dim);
xinit=[constraint_encoding(xcurr,3,20) rand];
[xopt_p1,fval_p1] = patternsearch(f,xinit,[],[],[],[],0.01*ones(1,dim),0.99*ones(1,dim),options);

%Výběr nejlepšího řešení
Xopt={xopt,xopt_m1,xopt_p1};
[a,b]=min([fval fval_m1 fval_p1]);
xopt=Xopt{b};

%Dekódování
xopt = constraint_decoding(xopt,3,20);
xopt=sort(xopt);


%Evaluate current and optimized schedule
[costopt, popt, copt, ratiofullopt, pcollopt, alessopt,amoreopt] = costFcn(xopt,TT,params);
[costcurr, pcurr, ccurr, ratiofullcurr, pcollcurr,alesscurr, amorecurr] = costFcn(xcurr,TT,params);
%simulated level p can reach more than 100 to enable cost computation,
%thus we must saturate it
%pcurr(pcurr>100)=100;popt(popt>100)=100;
%xcurr=sort(xcurr);
% 
% 
% disp('-------------------------');
% disp('Current schedule:');
% tmonday=dateshift(datetime('today'),'dayofweek','Monday','previous');
tcurr= weekratio2weektime(xcurr)';
tcurr = (datestr(tcurr,'ddd HH:MM'));
% disp(['Cost value=' num2str(costcurr)]);
% disp('-----------------');
% disp('Optimal schedule:');
topt=weekratio2weektime(xopt)';
topt = datestr(topt,'ddd HH:MM');
% disp(['Cost value=' num2str(fval)]);
