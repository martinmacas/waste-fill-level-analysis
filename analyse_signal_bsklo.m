function [ypred, cpred,analysis,schedules,alarms] = analyse_signal_bsklo(Time_all,p_all)
% ANALYSE_SIGNAL_BSKLO Analyzuje signál zaplnění odpadových nádob na sklo a pomalu se plnících nádob.
%
%   [ypred, cpred, analysis, schedules, alarms] = analyse_signal_bsklo(Time_all, p_all)
%
%   Funkce provádí detekci anomálií v signálu zaplnění, detekci svozů pomocí
%   speciálního klasifikátoru pro pomalu plnící se nádoby na sklo a
%   rozděluje signál do intervalů s periodickými, stabilními svozovými rozvrhy.
%   Pro každý takový interval provádí detailní analýzu včetně detekce chybějících svozů a generování alarmů.
%
% Vstupní parametry:
%   Time_all   - datetime (Nx1), časové značky vzorků signálu zaplnění
%   p_all      - double (Nx1), hodnoty zaplnění nádob v procentech
%
% Výstupní parametry:
%   ypred      - double (Nx1), predikce kategorií anomálií pro každý časový vzorek
%   cpred      - logical (Nx1), detekované svozy odpadu (1 = svoz detekován)
%   analysis   - struct (1 x počet intervalů), podrobná analýza pro každý stabilní interval svozového rozvrhu,
%                obsahuje informace o svozech, chybějících svozech, statistiky signálu a alarmy
%   schedules  - cell array, periodické svozové rozvrhy přiřazené ke každému analyzovanému intervalu
%   alarms     - struktura, souhrn detekovaných alarmů ze všech intervalů
%
% Popis:
%   1) Provede detekci anomálií pomocí heuristiky přizpůsobené pomalu plnícím nádobám na sklo (<a href="anomaly_detection_heuristic_bsklo.html">anomaly_detection_heuristic_bsklo</a>).
%   2) Detekuje svozy pomocí klasifikátoru bez využití vzdálenosti od
%      očekávaného času svozu (<a
%      href="detect_collections_supervised_bsklo.html">detect_collections_supervised_bsklo</a>),
%      což je vhodné pro detekci změn ve svozovém rozvrhu. 
%   3) Rozdělí časovou řadu do intervalů s periodickým stabilním svozovým rozvrhem (<a href="detect_changepoints_periodical.html">detect_changepoints_periodical</a>).
%   4) V každém intervalu aktualizuje svozy pomocí klasifikátoru s využitím očekávaných časů svozů (<a href="detect_collections_supervised_bsklo.html">detect_collections_supervised_bsklo</a>).
%   5) Pro každý interval vyhodnotí svozy a chybějící svozy (<a href="detect_missing_collection_periodical.html">detect_missing_collection_periodical</a>), a vytvoří sadu alarmů pro zvýšené události (<a href="detectIncreasedEvents.html">detectIncreasedEvents</a>).
%   6) Výstupní struktury slouží pro další analýzu a nebo pro optimalizaci svozových plánů.
%
% Poznámka:
%   Funkce využívá podpůrné funkce: anomaly_detection_heuristic_bsklo, detect_collections_supervised_bsklo,
%   detect_changepoints_periodical, detect_missing_collection_periodical, detectIncreasedEvents, expected_collection_times.
%
% Příklad použití:
%   [ypred, cpred, analysis, schedules, alarms] = analyse_signal_bsklo(Time_data, fill_levels);
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
%   schedule         - (double array) periodický svozový rozvrh [perioda (týdny), den v týdnu, hodina]
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
ypred = anomaly_detection_heuristic_bsklo(Time_all, p_all);

%Detect collections for whole signal using classifier without "distance from expected
%collection" feature, this is used by changepoint detection  
[cpred, ~, ~, ~,~]  = detect_collections_supervised_bsklo(Time_all,p_all, [],[]);

%Divide the signal to intervals with stable collection schedule
[schedules, ind_start, ind_end] = detect_changepoints_periodical(Time_all, p_all, cpred, 'tol_period',48,'tol_missing',3); 

%longparts must have time span more than 100 and more
%than 100 samples   
%schedules can be empty and I must examine this later (TODO)
ind_longparts = find(and(days(Time_all(ind_end)-Time_all(ind_start))>100,(ind_end-ind_start)>100))';

%cpred will be updated for long parts because I have the stable collection
%schedule
%cpred2=cpred;
alarms=[];
for i = 1:length(ind_longparts) %For each part with stable collection
    i_s=max(ind_start(i)-30,1);
    i_e=ind_end(i)-4;
    ind_part = i_s:ind_end(i);%add previous 30 samples, because detector needs some first samples for extraction
    Time = Time_all(ind_part);
    p =  p_all(ind_part);
    Time_expected = expected_collection_times(Time(cpred(ind_part)), schedules{i}); 
    [cpred_part, ~, ~, ~,~]  = detect_collections_supervised_bsklo(Time,p, [],Time_expected);
    
    %Replace cpred only up to i_e, because detector needs some last samples
    %for feature extraction
    cpred(ind_start(i):i_e) = cpred_part(31:end-4);

end

picklevel=p_all(cpred);
afterpicklevel=p_all([false;cpred(1:end-1)]);
    



if ~isempty(ind_longparts)

    %This ensures that periods before, between, and after longparts will be
    %merged.
    ind_start2=sort([1;ind_start(ind_longparts);ind_end(ind_longparts)+1]);
    ind_end2=sort([ind_end(ind_longparts);ind_start(ind_longparts)-1;ind_end(end)]);
    %ind_end2(end)=ind_end2(end)-7;%Do not consider last seven samples
    schedules2 = schedules([ind_longparts(1) repelem(ind_longparts,2)],:);
    if (ind_start2(end)>ind_end2(end)),ind_start2(end)=[];ind_end2(end)=[];schedules2(end,:)=[];end
    %Beginning will assume the schedule of the first longpart, periods between
    %long parts will assume the schedule of the previous long parts and 
    %last period assumes schedule of the last long part.
    isshort=([ind_end2-ind_start2]<200);
    ind_start2(isshort)=[];
    ind_end2(isshort)=[];
    schedules2(isshort,:)=[];
    ind_longparts2 = 1:length(ind_start2);%This means that all ind_starts will be analysed
    
    %Replacement of the original intervals by the new ones
    ind_start=ind_start2;
    ind_end=ind_end2;
    schedules = schedules2;
    ind_longparts=ind_longparts2;
else
    ind_start = 1;
    ind_end = length(Time_all);
    ind_longparts = 1;
 
end



%Analyse each interval
%cpred = zeros(size(Time_all));
period = 0;

for i = ind_longparts
    period = period+1;
    
    ind_part = ind_start(i):ind_end(i);
    Time = Time_all(ind_part);
    p =  p_all(ind_part);
    
    %Basic information
    a.period = period;
    a.ind_start = ind_start(i);
    a.ind_end = ind_end(i);
    a.time_start = Time(i);
    a.time_end = Time(end);
    a.days = days(Time(end)-Time(i));
    a.samples = length(Time);
    
    %Detect collections
    %There is no collection detection in periodical mode at this moment,
    %but one could make it more precise here using expected collection
    %aware model, it can be added in future
    %[c, scores, threshold, level_after,level_before] = detect_collections_supervised_bsklo(Time,p,[],schedules{i});
    %cpred(ind_part) = c;
    %cpred = c(ind_part);%This could be done before the loop, but for clearness it is inefficiently applied here
    c_part = cpred(ind_part);

    if ~isempty(schedules)
    %Detect missing collections
        [ind_missing, Time_missing, Time_scheduled] = detect_missing_collection_periodical(Time,p, c_part, schedules{i}, 48);
        ypred(ind_part(ind_missing))=3;
    end

    indc=find(cpred);
    isinsidei = and(indc>=ind_start(i),indc<=ind_end(i));
    level_before = picklevel(isinsidei);
    level_after = afterpicklevel(isinsidei);
    

    %Collections analysis
    a.collection_mode = 'periodical';
    a.meanlevel_before = mean(level_before);
    a.meanlevel_after = mean(level_after);
    a.level_after = level_after;
    ind_lost=find(ypred(ind_part)==4);
    %a.lostsig_ratio = days(sum(Time(ind_lost+1)-Time(ind_lost)))/a.days;
    %This gave error if ind_lost was end of Time so the following solves
    %this:
    a.lostsig_ratio = days(sum(Time_all(ind_part(ind_lost)+1)-Time_all(ind_part(ind_lost))))/a.days;
    if isempty(a.lostsig_ratio), a.lostsig_ratio = 0;end
    a.longenough = true;
    
    a.num_collections = sum(c_part);

    if ~isempty(schedules)
        a.schedule = schedules{i,1};
        a.Time_scheduled = Time_scheduled;
        a.misscoll_num=length(ind_missing);
        a.misscoll_ratio=100*a.misscoll_num/length(Time_scheduled');
        a.num_scheduled=length(Time_scheduled);
    else
        a.schedule = [];
        a.Time_scheduled = [];
        a.misscoll_num = NaN;
        a.misscoll_ratio = NaN;
        a.num_scheduled = NaN;
    end


    %Events analysis
    y = ypred(ind_part);
    a.counts = histcounts(y,[1:10]);
    a.countsw = a.counts/a.days*7;
    
    %Optimization analysis is empty 
    a.alesscurr = [];
    a.alessopt = [];
    a.amorecurr = [];
    a.amoreopt = [];
    

    if isempty(a.schedule)
        periodweeks=4;
    else
        periodweeks=a.schedule(1);
    end
    
    cpred = logical(cpred);
    wlenDays =       [7 7 3*periodweeks 14 14 7 7 14 7];
    wlenPrevDays = 3*[7 7 3*periodweeks 14 14 7 7 14 7];
    stepDays = 3;
    threshold=4;
    minCount =       [2 3 3                2  1 3 10 2 4];
    a.alarms =  detectIncreasedEvents(Time, y, wlenDays, wlenPrevDays, stepDays, threshold, minCount);
    alarms=[alarms;a.alarms];
    
    analysis(period)=a;


end


end
