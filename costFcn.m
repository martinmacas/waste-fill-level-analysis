function [cost, p, coll, ratiofull, pcoll, amountless,amountmore] = costFcn(t_collect,TT,params)
% COSTFCN  Ztrátová funkce pro optimalizaci týdenních časů svozu bez
%          intervalových omezení.
%
%   [cost, p, coll, ratiofull, pcoll, amountless, amountmore] = ...
%       COSTFCN(t_collect, TT, params)
%
%   vypočítá hodnotu ztrátové funkce pro zadaný ohodnocovaný týdenní rozvrh
%   svozů t_collect, kde každý prvek představuje čas svozu ve formátu
%   weekfraction (0–1). Funkce simuluje průběh zaplnění nádoby na základě
%   vstupní časové řady a vyhodnocuje dvě hlavní kritéria:
%       • nevyužitou kapacitu (unused capacity, UC),
%       • přetečení nádoby (missed capacity / overflow, MC).
%
%   Funkce na rozdíl od COSTFCN_CONSTRAINTS neprovádí žádná intervalová
%   omezení ani reparametrizace časů svozu – optimalizátor tedy může zvolit
%   libovolnou hodnotu weekfraction v intervalu [0, 1] a ta je interpretována
%   jako platný čas svozu.
%
%   Simulace probíhá nad časovou řadou TT, kde je úroveň zaplnění aktualizována
%   podle přírůstků TT.dp. Jakmile některý z časů v t_collect spadá mezi
%   okamžiky t(i−1) a t(i), je zaznamenán svoz a úroveň zaplnění je skokově
%   nastavena podle PARAMS.LEVEL_AFTER. Tak jsou určeny úrovně zaplnění těsně
%   před svozem i celý průběh zaplnění nádoby.
%
%   UC (AMOUNTLESS) je množství volné kapacity, které zůstalo nevyužito při
%   předčasném svozu. MC (AMOUNTMORE) je množství odpadu, které se do nádoby
%   nevešlo při opožděném svozu.
%
%   Funkce porovnává vypočtené UC a MC s referenčními hodnotami
%   PARAMS.ALESSCURR a PARAMS.AMORECURR, což odpovídá UC a MC aktuálního
%   (výchozího) rozvrhu. Pokud nové hodnoty nejsou menší než referenční,
%   přidává se penalizace. Optimalizace je tak směrována ke zlepšení obou
%   kritérií současně.
%
%   Výsledná cena je dána kombinací:
%       • w * UC + (1 - w) * MC
%       • penalizačních členů, které zajišťují UC < ALESSCURR a MC < AMORECURR
%
%   Funkce je určena pro použití při optimalizaci rozvrhů pomocí metod jako
%   PATTERNSEARCH, PARTICLESWARM a dalších algoritmů bez derivací.
%
%   Vstupní parametry:
%       t_collect  - double, vektor časů svozu ve formátu weekfraction (S×1).
%                    Nejsou uplatněna žádná intervalová omezení.
%
%       TT         - timetable typu Nx2 s časovou řadou zaplnění:
%                        • TT.Time : datetime, časové značky
%                        • TT.p    : double, vzorky stavu zaplnění (%)
%                        • TT.dp   : double, odhad množství uloženého odpadu
%                                     mezi vzorky (výstup estimate_disposal.m)
%
%       params     - struktura obsahující pomocná a referenční data:
%                        • timec       : datetime, detekované časy svozu
%                        • level_after : double, úroveň zaplnění po svozu
%                                         pro simulační model
%                        • alesscurr   : double, referenční UC aktuálního rozvrhu
%                        • amorecurr   : double, referenční MC aktuálního rozvrhu
%
%   Výstupní parametry:
%       cost       - double, výsledná hodnota ztrátové funkce
%
%       p          - double(N×1), simulovaná úroveň zaplnění nádoby
%
%       coll       - logical(N×1), příznaky detekovaných okamžiků svozu
%
%       ratiofull  - double, podíl času, kdy byla nádoba naplněna na 100 %
%
%       pcoll      - double, úrovně zaplnění těsně před svozy
%
%       amountless - double, celková nevyužitá kapacita (UC)
%
%       amountmore - double, celkové přetečení nádoby (MC)
%
%   Viz také:
%       COSTFCN_CONSTRAINTS, PATTERNSEARCH, PARTICLESWARM, ESTIMATE_DISPOSAL

t=weekratio(TT.Time);
n=length(t);

p=TT.p(1);pall=[p;zeros(n-1,1)];coll=logical(zeros(n,1));

for i=2:n
    p=p+TT.dp(i);
    
    if any(and(t(i-1)<=t_collect,t_collect<t(i))) 
        [~, j] = min(abs(params.timec - TT.Time(i)));
        p = params.level_after(j);
        coll(i-1)=true;
    end
    
    pall(i)=p;
    
end
p=pall;

%Levels right before collection
%pcoll = sort(p(circshift(coll,-1)));
%pcoll = (p(circshift(coll,-1)));
%pcoll = (p(circshift(coll,-1)));
pcoll = p(coll);


amountless = sum(100-pcoll(pcoll<100));
amountmore = sum(pcoll(pcoll>100)-100); 
ratiofull = mean(p>=100);

w=0.5;
%cost = w*amountless+(1-w)*amountmore;
cost = (w*amountless+(1-w)*amountmore)+100*(max(amountless-params.alesscurr,0)+max(amountmore-params.amorecurr,0));
%cost = w*(amountless-params.alesscurr)+(1-w)*(amountmore-params.amorecurr);

end
