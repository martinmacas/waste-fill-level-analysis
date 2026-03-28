function [ind_missing, Time_missing, Time_scheduled] = detect_missing_collection_periodical(Time,p, c, schedule, tolerance)
%DETECT_MISSING_COLLECTION Detekuje chybějící svozy na základě časové řady
%zaplnění nádoby a předpokládaného rozvrhu svozů pro nádoby s periodickým
%rozvrhem svozů (sklo a pomalu se plnící nádoby)
%
%   [ind_missing, Time_missing, Time_scheduled] = DETECT_MISSING_COLLECTION_PERIODICAL(Time, p, c, schedule, tolerance)
%
%   Funkce porovnává detekované svozy (indikátory c) s očekávaným
%   rozvrhem svozů (schedule) a identifikuje případy, kdy svoz podle
%   rozvrhu měl nastat, ale ve skutečnosti nebyl detekován.
%
%--------------------------------------------------------------------------
%   Vstupní parametry:
%
%       Time            - datetime (Nx1)
%                         Časová informace signálu.
%
%       p               - double (Nx1)
%                         Vzorky stavu zaplnění odpadové nádoby v procentech.
%
%       c               - double/logical (Nx1)
%                         Indikátory detekovaných svozů.
%                         Typicky binární vektor, kde 1 označuje detekovaný svoz.
%
%       schedule        - double (1x3) ve formě [p d h], kde p je perioda opakování svozů v týdnech,
%                         d je den v týdnu a h je hodina ve dne
%                       - Očekávané (naplánované) časy v týdnu pro jednotlivé svozy
%                         
%
%       tolerance       - double (např. 48)
%                         Povolená časová tolerance v hodinách mezi plánovaným a
%                         detekovaným svozem. Pokud v okolí plánovaného
%                         času není nalezen detekovaný svoz, považuje se plánovaný svoz za chybějící.
%                         U pomalu se plnících nádob by tolerance měla být
%                         vyšší (dny-týden)
%
%--------------------------------------------------------------------------
%   Výstupní parametry:
%
%       ind_missing     - double (Kx1)
%                         Indexy chybějících svozů (plánovaných svozů pro něž ve stanovené toleranci nebyl detekován svoz).
%                         K je počet chybějících svozů.
%
%       Time_missing    - datetime (Kx1)
%                         Časy chybějících svozů.
%
%       Time_scheduled  - datetime (Qx1)
%                         Seznam časů plánovaných svozů vypočtený z rozvrhu "schedule"
%                         
%--------------------------------------------------------------------------
%   Příklad:
%      
%       [ind_missing, Time_missing, Time_scheduled] = ...
%           detect_missing_collection(Time, p, c, schedule, 48);
%


if ~issorted(Time,'ascend')
    error('The time must be sorted in order to use detect_missing_collections!');
end

ind = find(c);

period = schedule(1);%Collection period in weeks
%round(schedule{1}/7)*7; % Collection period in days

%If the collection weekday was not detected, try all of them
if isnan(schedule(2))
    WDs = 1:7;%{'Mon','Tue','Wed','Thu','Fri','Sat','Sun'};
else
    WDs = schedule(2);
end

Time_detected = Time(c);


for k = 1:length(WDs)
    
    wd = WDs(k);
    
    Time_first = dateshift(dateshift(Time(1),'dayofweek',wd),'start','day')+hours(12);
    
    %offset = 0:period/7-1;
    offset = 0:period-1;
    for i = 1:length(offset)
    
        
            %Scheduled collection every period days at noon
            Time_scheduled = (Time_first+offset(i)*days(7):7*days(period):Time(end))';
            
            %Remove beginning and end of time scheduled to avoid false positive
            %detection of missed collection
            Time_scheduled(Time_scheduled<Time(2))=[];
            Time_scheduled(Time_scheduled>Time(end-1))=[];
            
            
            %Time_detected = Time(c)+(Time([false;c(1:end-1)])-Time(c))/2;%This can
            %give errror if the last c is 1 so I will not use the center between pre
            %and post collection times now.
            
            %Remove time scheduled in big time gaps to avoid false detection of missed
            %collections. If there are no samples around scheduled time, one cannot
            %decide
            ind_gap=find(diff(Time)>hours(12))';
            for j = ind_gap
                Time_scheduled(and(Time_scheduled>(Time(j)-hours(0)),Time_scheduled<(Time(j+1)+hours(0))))=[];
            end
            
            %Deviation of scheduled collection times from detected collection times
            if isempty(Time_detected)
                deviation = Inf(size(Time_scheduled));%If no collection was detected
            elseif length(Time_detected)==1
                deviation = hours(abs(Time_detected-Time_scheduled));
            else
                deviation=hours(abs(Time_detected(interp1(datenum(Time_detected), 1:numel(Time_detected), datenum(Time_scheduled), 'nearest', 'extrap'))-Time_scheduled));
            end

            %binary vector for indexing Time_scheduled
            is_missing = deviation>tolerance;
            
            IM{i,k} = is_missing;
            TS{i,k} = Time_scheduled;
            D(i,k) = sum(deviation);
    
    end
end

[a,b]=find(D==min(min(D)),1);
Time_scheduled = TS{a,b};
is_missing = IM{a,b};
Time_missing = Time_scheduled(is_missing);

%Index of Time and p vector
ind_missing = interp1(datenum(Time), 1:numel(Time), datenum(Time_missing), 'nearest', 'extrap');

