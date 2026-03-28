function [X,xnames]=extract_features_collection_bsklo(p,Time,schedule,indc)
% EXTRACT_FEATURES_COLLECTION_BSKLO Extrahuje příznaky pro detekci svozu nádoby
% na barevné sklo nebo pomalu se plnících nádob.
%
%   [X, xnames] = EXTRACT_FEATURES_COLLECTION_BSKLO(p, Time, schedule, indc)
%   provede extrakci příznaků na základě signálu zaplnění, časových údajů
%   a indexů indc míst, v kterých chceme extrahovat příznaky. Pro detekci svozů 
%   bude indc patrně obsahovat všechny indexy svozů (pozitivní příklady) a 
%   indexy míst, která chci odlišit od svozů (negativní příklady, třeba
%   všechna místa, kde dochází k poklesu a nejsou to svozy.
%
%   Vstupní parametry:
%       Time            - časová informace signálu (datetime, vektor Nx1)
%       p               - vzorky stavu zaplnění odpadové nádoby v procentech (double, vektor Nx1)
%       schedule        - rozvrh svozů
%       indc            - indexy událostí,pro které chci extrahovat
%                         příznaky (např. svozy a nesvozy) (double, vektor 1xn)
%
%   Výstupní parametry:
%       X               - matice s hodnotami příznaků v každém řádku (n × m double)
%       xnames          - názvy příznaků (1 × m cell array of char/string)
%
%


window_hours = 3*24;
Time_c = Time(indc);
wd=mode(weekday(schedule));
wd_Time=weekday(Time(indc));
X = [diff(p(repmat(indc,1,3)+(-1:1)),[],2)./hours(diff(Time(repmat(indc,1,3)+(-1:1)),[],2)), ...%derivace
     diff(p(repmat(indc,1,3)+(-1:1)),[],2), ...%abs diference
     arrayfun(@(k) median(p(Time >= Time(k)-hours(window_hours) & Time < Time(k))), indc), ...%mean of p over past window window_hours
     arrayfun(@(k) median(p(Time > Time(k) & Time <= Time(k)+hours(window_hours))), indc), ...%mean of p over future window window_hour
     abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
     diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
     hours(min(abs(Time(indc) - schedule'), [], 2)) ... %Vzdalenost od planovaneho svozu
     hours(diff(Time(repmat(indc,1,2)+(0:1)),[],2))...
     days(min(abs(Time_c - (dateshift(Time_c, 'start', 'day') + hours(9) + days(mod(wd - wd_Time + 7, 7)))), abs(Time_c - (dateshift(Time_c, 'start', 'day') + hours(9) - days(mod(wd_Time - wd + 7, 7))))))...%Number of hours distance from the planned weekday 9:00 
     %min(mod(wd - wd_Time + 7, 7), mod(wd_Time - wd + 7, 7)) ...%Number of
     %days distance from the planned weekday , similar to previous but more
     %rough
];
xnames = {'deriv-1','deriv0','diff-1','diff0','medianp0','medianp+1','noon_dist','diff0/p0','plan_dist','diffTime','plan_distwd'};




% 
% Time_c = Time(indc);
% wd=mode(weekday(schedule));
% wd_Time=weekday(Time(indc));
% X = [diff(p(repmat(indc,1,3)+(-1:1)),[],2)./hours(diff(Time(repmat(indc,1,3)+(-1:1)),[],2)), ...%derivace
%      diff(p(repmat(indc,1,3)+(-1:1)),[],2), ...%abs diference
%      p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
%      abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
%      diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
%      hours(min(abs(Time(indc) - schedule'), [], 2)) ... %Vzdalenost od planovaneho svozu
%      hours(diff(Time(repmat(indc,1,2)+(0:1)),[],2))...
%      days(min(abs(Time_c - (dateshift(Time_c, 'start', 'day') + hours(9) + days(mod(wd - wd_Time + 7, 7)))), abs(Time_c - (dateshift(Time_c, 'start', 'day') + hours(9) - days(mod(wd_Time - wd + 7, 7))))))...%Number of hours distance from the planned weekday 9:00 
%      %min(mod(wd - wd_Time + 7, 7), mod(wd_Time - wd + 7, 7)) ...%Number of
%      %days distance from the planned weekday , similar to previous but more
%      %rough
% ];
%xnames = {'deriv-1','deriv0','diff-1','diff0','p0','p+1','noon_dist','diff0/p0','plan_dist','diffTime','plan_distwd'};

end
