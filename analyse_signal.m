function [ypred, cpred,analysis,schedules,alarms] = analyse_signal(Time_all,p_all)
% ANALYSE_SIGNAL Analyzuje signál zaplnění rychle se plnících odpadových nádob a vrací strukturu
% analýzy pro stabilní intervaly svozového rozvrhu.
%
%   [ypred, cpred, analysis, schedules, alarms] = analyse_signal(Time_all, p_all)
%
%   Provede detekci událostí v časové řadě zaplnění (<a href="anomaly_detection_heuristic.html">anomaly_detection_heuristic</a>),
%   rozdělí signál do intervalů se stabilními svozovými rozvrhy (<a href="detect_changepoints.html">detect_changepoints</a>),
%   a pro každý takový interval provede podrobnou analýzu včetně detekce svozů (<a href="detect_collections_supervised.html">detect_collections_supervised</a>),
%   chybějících svozů (<a href="detect_missing_collection.html">detect_missing_collection</a>)  a zvýšených alarmů (<a href="detectIncreasedEvents.html">detectIncreasedEvents</a>).
%   Pro každý interval jsou vyhodnoceny svozy, chybějící svozy, a alarmy zvýšených událostí.
%   Výsledkem je soubor informací o jednotlivých intervalech signálu uložený v proměnné analysis.
%
% Vstupní parametry:
%   Time_all   - datetime (Nx1), časové značky vzorků signálu zaplnění
%   p_all      - double (Nx1), hodnoty zaplnění nádob v procentech
%
% Výstupní parametry:
%   ypred      - double (Nx1), predikce událostí (kategorie anomálií) pro každý časový vzorek
%   cpred      - logical (Nx1), detekované svozy (1 = svoz detekován)
%   analysis   - struct (1 x počet intervalů), struktura s podrobnou analýzou pro každý stabilní interval svozového rozvrhu,
%                obsahuje např. počty svozů, chybějící svozy, statistiky signálu, alarmy apod.
%   schedules  - cell array, svozové rozvrhy přiřazené ke každému stabilnímu intervalu
%   alarms     - struktura, souhrn všech detekovaných alarmů z jednotlivých intervalů
%
%
% Poznámka:
%   Funkce využívá podpůrné funkce: anomaly_detection_heuristic, detect_collections_thresholding,
%   detect_changepoints, detect_collections_supervised, detect_missing_collection, detectIncreasedEvents.
%
% Příklad použití:
%   [ypred, cpred, analysis, schedules, alarms] = analyse_signal(Time_data, fill_levels);
%
% Význam položek analysis(i):
%
%   period           - (integer) pořadové číslo analyzovaného intervalu v rámci celé časové řady
%
%   ind_start        - (integer) index začátku intervalu ve vstupních datech
%
%   ind_end          - (integer) index konce intervalu ve vstupních datech
%
%   time_start       - (datetime) časový údaj začátku intervalu
%
%   time_end         - (datetime) časový údaj konce intervalu
%
%   days             - (double) délka intervalu v dnech
%
%   samples          - (integer) počet vzorků (datových bodů) v intervalu
%
%   collection_mode  - (char) režim svozu, v této funkci je hodnota 'periodical'
%
%   meanlevel_before - (double) průměrná úroveň zaplnění nádoby těsně před svozy v daném intervalu (v %)
%
%   meanlevel_after  - (double) průměrná úroveň zaplnění nádoby těsně po svozech v daném intervalu (v %)
%
%   level_after      - (double array) hodnoty zaplnění ihned po jednotlivých svozech v intervalu
%
%   lostsig_ratio    - (double) podíl „ztracených“ datových vzorků (dlouhých mezer v měření) vůči délce intervalu (v %)
%
%   longenough       - (logical) příznak, zda je interval dostatečně dlouhý pro analýzu (true/false)
%
%   num_collections  - (integer) počet detekovaných svozů odpadu v intervalu
%
%   schedule         - (double array) týdenní svozový rozvrh double 1xS, weekfraction formát
%
%   Time_scheduled   - (datetime array) plánované časy svozů podle aktuálního rozvrhu v intervalu
%
%   misscoll_num     - (integer) počet chybějících svozů (svoz, který se měl uskutečnit, ale nebyl detekován)
%
%   misscoll_ratio   - (double) procentuální podíl chybějících svozů vzhledem k plánovaným svozům v intervalu (%)
%
%   num_scheduled    - (integer) počet naplánovaných svozů v intervalu podle rozvrhu
%
%   counts           - (integer array) histogram počtu různých typů detekovaných anomálií (kategorie 1 až 9)
%
%   countsw          - (double array) vážený histogram anomálií přepočítaný na počet událostí za týden
%
%   alesscurr        - (empty) rezervní pole pro neoptimalizované nevyužité kapacity (pro budoucí využití)
%
%   alessopt         - (empty) rezervní pole pro optimalizované nevyužité kapacity (pro budoucí využití)
%
%   amorecurr        - (empty) rezervní pole pro neoptimalizované přetečení (pro budoucí využití)
%
%   amoreopt         - (empty) rezervní pole pro optimalizované přetečení (pro budoucí využití)
%
%   alarms           - (table) tabulka detekovaných alarmů zvýšeného výskytu událostí v analyzovaném intervalu,
%                      obsahuje tyto sloupce:
%                      - label       : číselný kód typu alarmu
%                      - labelname   : textový popis typu alarmu (např. 'Peaky', 'Propady')
%                      - startIdx    : index začátku alarmovaného období v datech
%                      - startTime   : časový údaj začátku alarmovaného období (datetime)
%                      - finishIdx   : index konce alarmovaného období v datech
%                      - finishTime  : časový údaj konce alarmovaného období (datetime)
%                      - avgPrev     : průměrná hodnota (např. předchozího období) použitá k vyhodnocení alarmu
%                      - currCount   : aktuální počet nebo intenzita detekované zvýšené události
%

%Event detection
ypred = anomaly_detection_heuristic(Time_all, p_all);

%Divide the signal to intervals with "stable" collection schedules 
c_all = detect_collections_thresholding(Time_all,p_all,[]);
[schedules, ind_start, ind_end, centers, OPERATES, c] = detect_changepoints(Time_all, p_all,c_all);
    
%longparts must have time span more than 100days, nonempty schedule and more
%than 100 samples
ind_longparts = find(and(and(days(Time_all(ind_end)-Time_all(ind_start))>100,~cellfun(@isempty, schedules)),(ind_end-ind_start)>100))';

%This ensures that periods before, between, and after longparts will be
%merged.
ind_start2=sort([1;ind_start(ind_longparts);ind_end(ind_longparts)+1]);
ind_end2=sort([ind_end(ind_longparts);ind_start(ind_longparts)-1;ind_end(end)]);
%ind_end2(end)=ind_end2(end)-7;%Do not consider last seven samples
if isempty(ind_longparts)
   ind_longparts2=1;schedules2=[];
   len=ind_end-ind_start;%delky jednotlivych intervalu
   len(cellfun(@isempty,schedules))=0;%vynulovat tam, kde neni detekova schedule
   [~,b]=max(len);
   schedules2=schedules(b);
else
    schedules2 = schedules([ind_longparts(1) repelem(ind_longparts,2)]);
    if (ind_start2(end)>ind_end2(end)),ind_start2(end)=[];ind_end2(end)=[];schedules2(end)=[];end
    %Beginning will assume the schedule of the first longpart, periods between
    %long parts will assume the schedule of the previous long parts and 
    %last period assumes schedule of the last long part.
    isshort=([ind_end2-ind_start2]<200);
    ind_start2(isshort)=[];
    ind_end2(isshort)=[];
    schedules2(isshort)=[];
    ind_longparts2 = 1:length(ind_start2);
end
ind_start=ind_start2;
ind_end=ind_end2;
schedules = schedules2;
ind_longparts=ind_longparts2;


cpred = zeros(size(Time_all));
period = 0;
%for i = 1:length(ind_start)
alarms=[];
%For each interval, analyse the fill level signal
for i = ind_longparts
    period = period+1;
    
    ind_part = ind_start(i):ind_end(i);
    Time = Time_all(ind_part);
    p =  p_all(ind_part);

    a.period = period;
    a.ind_start = ind_start(i);
    a.ind_end = ind_end(i);
    a.time_start = Time(i);
    a.time_end = Time(end);
    a.days = days(Time(end)-Time(i));
    a.samples = length(Time);
    
    %Detect collections
    [c, scores, threshold, level_after,level_before] = detect_collections_supervised(Time,p,[],schedules{i});
    cpred(ind_part) = c;

    %Detect missing collections
    [ind_missing, Time_missing, Time_scheduled] = detect_missing_collection(Time,p, c, schedules{i}, 8);
    ypred(ind_part(ind_missing))=3;
    a.collection_mode = 'weekly';
    a.meanlevel_before = mean(level_before);
    a.meanlevel_after = mean(level_after);
    a.level_after = level_after;
    ind_lost=find(ypred(ind_part)==4);
    
    %Compute ratio of lost signal (too big gaps between samples)
    %a.lostsig_ratio = days(sum(Time(ind_lost+1)-Time(ind_lost)))/a.days;
    a.lostsig_ratio = days(sum(Time_all(ind_part(ind_lost)+1)-Time_all(ind_part(ind_lost))))/a.days;
    
    %Create the analysis structure a
    if isempty(a.lostsig_ratio), a.lostsig_ratio = 0;end
    a.longenough = true;
    a.schedule = schedules{i};
    a.Time_scheduled = Time_scheduled;
    a.num_collections = sum(c);
    a.misscoll_num=length(ind_missing);
    a.misscoll_ratio=100*a.misscoll_num/length(Time_scheduled');
    a.num_scheduled=length(Time_scheduled);
    
    y = ypred(ind_part);
    a.counts = histcounts(y,[1:10]);
    a.countsw = a.counts/a.days*7;
    
    %Optimization outputs are not created inside analysis. They can be
    %added externally later when optimization will be performed
    a.alesscurr = [];
    a.alessopt = [];
    a.amorecurr = [];
    a.amoreopt = [];
    
    
    %Increased events detection and creation of alarms
    cpred = logical(cpred);
    wlenDays =       [7 7 14                    14 14 7 7 14 7];
    wlenPrevDays = 3*[7 7 28                    14 14 7 7 14 7];
    stepDays = 3;
    threshold=4;
    minCount =       [2 10 2*length(a.schedule)     2  1 5 10 2 4];
    a.alarms =  detectIncreasedEvents(Time, y, wlenDays, wlenPrevDays, stepDays, threshold, minCount);
    alarms=[alarms;a.alarms];
    analysis(period)=a;
    


end

end
