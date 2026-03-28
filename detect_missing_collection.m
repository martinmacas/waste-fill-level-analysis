function [ind_missing, Time_missing, Time_scheduled] = detect_missing_collection(Time,p, c, schedule, tolerance)
%DETECT_MISSING_COLLECTION Detekuje chybějící svozy na základě časové řady
%zaplnění nádoby a předpokládaného rozvrhu svozů pro nádoby s týdenním
%rozvrhem svozů (papír a rychle se plnící nádoby)
%
%   [ind_missing, Time_missing, Time_scheduled] = DETECT_MISSING_COLLECTION(Time, p, c, schedule, tolerance)
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
%       schedule        - double 1xS z <0,1>, podíl týdne (weekfraction), 0
%                         je začátek týdne a 1 je konec týdne (viz. weekratio)
%                       - Očekávané (naplánované) časy v týdnu pro jednotlivé svozy
%                         
%
%       tolerance       - double (např. 8)
%                         Povolená časová tolerance v hodinách mezi plánovaným a
%                         detekovaným svozem. Pokud v okolí plánovaného
%                         času není nalezen detekovaný svoz, považuje se plánovaný svoz za chybějící.
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
%           detect_missing_collection(Time, p, c, schedule, 8);
%



if ~issorted(Time,'ascend')
    error('The time must be sorted in order to use detect_collections.m!');
end


ind = find(c);

Time_scheduled = (dateshift(Time(1),'start','week')+days(1)+hours(schedule*168)+7*days(0:round(hours(Time(end)-Time(1))/168))')';
Time_scheduled = Time_scheduled(:);
%Remove beginning and end of time scheduled to avoid false positive
%detection of missed collection
Time_scheduled(Time_scheduled<Time(2))=[];
Time_scheduled(Time_scheduled>Time(end-1))=[];

%Time_detected = Time(c);
Time_detected = Time(c)+(Time([false;c(1:end-1)])-Time(c))/2;

%Remove time scheduled in big time gaps to avoid false detection of missed
%collections. If there are no samples around scheduled time, one cannot
%decide
ind_gap=find(diff(Time)>hours(12))';
for i = ind_gap
    %Time_scheduled(and(Time_scheduled>(Time(i)-hours(tolerance)),Time_scheduled<(Time(i+1)+hours(tolerance))))=[];
    Time_scheduled(and(Time_scheduled>(Time(i)-hours(0)),Time_scheduled<(Time(i+1)+hours(0))))=[];
end

deviation=hours(abs(Time_detected(interp1(datenum(Time_detected), 1:numel(Time_detected), datenum(Time_scheduled), 'nearest', 'extrap'))-Time_scheduled));

is_missing = deviation>tolerance;

Time_missing = Time_scheduled(is_missing);

ind_missing = interp1(datenum(Time), 1:numel(Time), datenum(Time_missing), 'nearest', 'extrap');

