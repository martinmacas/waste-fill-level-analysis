function [cost, p, coll, ratiofull, pcoll, amountless,amountmore] = costFcn_constraints(t_collect,TT,params)
% COSTFCN_CONSTRAINTS  Ztrátová funkce pro optimalizaci týdenních časů svozu.
%
%   [cost, p, coll, ratiofull, pcoll, amountless, amountmore] = ...
%       COSTFCN_CONSTRAINTS(t_collect, TT, params)
%
%   vypočítá hodnotu ztrátové funkce pro zadaný ohodnocovaný týdenní rozvrh
%   svozů t_collect, kde každý prvek představuje čas svozu ve formátu
%   weekfraction (0–1). Funkce simuluje průběh zaplnění nádoby na základě
%   vstupní časové řady a vyhodnocuje dvě hlavní kritéria:
%       • nevyužitou kapacitu (unused capacity, UC)
%       • přetečení nádoby (missed capacity / overflow, MC)
%
%   Funkce nejprve provede reparametrizaci pomocí CONSTRAINT_DECODING, která
%   zajistí, že výsledné časy svozu leží pouze v povolených intervalech
%   (např. mimo noční hodiny). Na základě vstupní časové řady TT je poté
%   simulována úroveň zaplnění nádoby, detekovány okamžiky svozu a určena
%   úroveň zaplnění těsně před každým svozem.
%
%   UC je spočítána jako celkové množství kapacity, které mohlo být využito,
%   kdyby nedošlo k předčasnému svozu. MC je naopak množství odpadu, které
%   nemohlo být uloženo kvůli opožděnému svozu (přetečení).
%
%   Funkce zároveň porovnává vypočtené hodnoty UC a MC s referenčními
%   hodnotami v parametrech PARAMS.ALESSCURR a PARAMS.AMORECURR, které
%   představují UC a MC pro aktuální rozvrh svozu. Pokud nové hodnoty nejsou
%   zlepšením oproti aktuálnímu stavu, je do nákladové funkce přidána
%   penalizace.
%
%   Výsledná cena je dána kombinací:
%       • w * UC + (1 - w) * MC
%       • penalizačními členy, které vynucují UC < ALESSCURR a MC < AMORECURR
%
%   Funkce je určena pro použití s optimalizačními metodami typu
%   PATTERNSEARCH, PARTICLESWARM a dalšími algoritmy bez derivací.
%
%   Vstupní parametry:
%       t_collect  - double, vektor časů svozu ve formátu weekfraction (S×1).
%                    Jedná se o optimalizovanou reprezentaci rozvrhu svozu.
%
%       TT         - timetable typu Nx2 obsahující časovou řadu zaplnění:
%                        • TT.Time : datetime, časová informace vzorků
%                        • TT.p    : double, vzorky úrovně zaplnění nádoby (%)
%                        • TT.dp   : double, odhad množství uloženého odpadu
%                                     mezi vzorky (výstup estimate_disposal.m)
%
%       params     - struktura obsahující pomocná a referenční data:
%                        • timec       : datetime, detekované časy svozu
%                        • level_after : double, úroveň zaplnění po svozu
%                                         (umožňuje realisticky simulovat pokles)
%                        • alesscurr   : double, UC aktuálního rozvrhu
%                        • amorecurr   : double, MC aktuálního rozvrhu
%
%   Výstupní parametry:
%       cost       - double, výsledná hodnota ztrátové funkce
%
%       p          - double(N×1), simulovaná úroveň zaplnění nádoby v čase
%
%       coll       - logical(N×1), příznaky detekovaných okamžiků svozu
%
%       ratiofull  - double, podíl času, kdy byla nádoba zaplněna na 100 %
%
%       pcoll      - double, úrovně zaplnění těsně před jednotlivými svozy
%
%       amountless - double, celková nevyužitá kapacita (UC)
%
%       amountmore - double, celkové přetečení nádoby (MC)
%
%   Viz také:
%       COSTFCN, COSTFCN_PERIODICAL, CONSTRAINT_DECODING,
%       ESTIMATE_DISPOSAL, OPTIMIZE_COLLECTIONS_CONSTRAINTS
%

t_collect = constraint_decoding(t_collect,3,20);

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
%pcoll = sort(p(circshift(coll,-1)));
pcoll = p(coll);

amountless = sum(100-pcoll(pcoll<100));
amountmore = sum(pcoll(pcoll>100)-100); 
ratiofull = mean(p>=100);

w=0.5;
%cost = w*amountless+(1-w)*amountmore;
cost = (w*amountless+(1-w)*amountmore)+100*(max(amountless-params.alesscurr,0)+max(amountmore-params.amorecurr,0));


end

