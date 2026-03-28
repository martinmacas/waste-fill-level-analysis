function texp = expected_collection_times(tcoll, schedule)
%EXPECTED_COLLECTION_TIMES Vypočítá předpokládané časy svozů na základě periodického rozvrhu.
%
%   texp = EXPECTED_COLLECTION_TIMES(tcoll, schedule)
%
%   Funkce vezme časy detekovaných svozů a periodický rozvrh svozů a vrátí
%   vektor časů očekávaných svozů, které pokrývají celé časové rozpětí
%   detekovaných svozů a navíc jej rozšiřují o jeden svoz před prvním a jeden svoz za posledním
%   detekovaným svozem.
%
%   Vstupní parametry:
%       tcoll    - datetime (Nx1) vektor časů detekovaných svozů
%       schedule - double (1x3) periodický rozvrh svozů ve formátu [p d h]
%                  p - perioda svozů v týdnech (např. 1 znamená každý týden)
%                  d - den v týdnu (1=neděle, 2=pondělí, ..., 7=sobota)
%                  h - hodina dne (0-23)
%
%   Výstupní parametry:
%       texp     - datetime (Mx1) vektor časů očekávaných svozů,
%                  které zahrnují časový rozsah tcoll s jedním svozem navíc před a za ním
%
%   Poznámky:
%       - Pokud je hodnota dne nebo hodiny v rozvrhu NaN, nastaví se výchozí
%         hodnota středy (den=4) a 9:00 hodin.
%       - Výpočet vychází z první očekávané doby svozu předcházející
%         prvnímu detekovanému svozu a pokračuje periodicky až za poslední detekovaný svoz.
%
%   Příklad použití:
%       schedule = [1 4 9]; % Svoz každý týden ve středu v 9 hodin
%       tcoll = [datetime(2023,1,10,9,0,0); datetime(2023,1,17,9,0,0)];
%       texp = expected_collection_times(tcoll, schedule);
%
%


    xperiod = schedule(1);
    xweekday = schedule(2);
    xhour = schedule(3);
    if isnan(xweekday), xweekday=4;end %If weekday was not detected, set Wednesday (4)
    if isnan(xhour), xhour=9;end %If hour of the day was not detected, set 9
    
    %t0 is the first expected collection time which preceeds the tcoll(1)
    t0 = dateshift(dateshift(tcoll(1),'dayofweek',xweekday,'previous'),'start','day')+hours(xhour);
    %periodical expected collection times
    texp=(t0:7*xperiod:(tcoll(end)+7*xperiod))';
    %there is xperiod possible starting points of the periodical schedule
    %so add 0 - xperiod-1 week shifts
    texp=repmat(texp,xperiod)+7*(0:xperiod-1);
    %for each element of texp, I need to find the distance from the closest element from tcoll.
    dist = reshape(min(abs(texp(:) - tcoll'),[],2),size(texp));
    [~,b] = min(sum(dist));
    texp = texp(:,b);
end