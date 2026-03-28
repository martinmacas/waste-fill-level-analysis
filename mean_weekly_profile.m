function [Mmean,Mstd,Mn] = mean_weekly_profile(Time,p)
%MEAN_WEEKLY_PROFILE Vypočítá průměrný, směrodatný rozptyl a počet vzorků pro
% každý den v týdnu a každou hodinu dne z časové řady zaplnění.
%
%   [Mmean, Mstd, Mn] = MEAN_WEEKLY_PROFILE(Time, p)
%
%   Funkce analyzuje časovou řadu zaplnění nádoby p s časovými značkami Time
%   a vypočítá statistiky rozdělené podle dne v týdnu (1 = neděle, 7 = sobota)
%   a hodiny dne (0-23).
%
%   Vstupní parametry:
%       Time - datetime (Nx1), časové značky jednotlivých vzorků signálu
%       p    - double (Nx1), hodnoty signálu zaplnění nádoby
%
%   Výstupní parametry:
%       Mmean - double (7x24), průměrné hodnoty signálu pro každý den v týdnu a
%               každou hodinu
%       Mstd  - double (7x24), směrodatná odchylka signálu pro každý den v týdnu
%               a každou hodinu
%       Mn    - double (7x24), počet vzorků použité pro výpočet průměru a směrodatné
%               odchylky v daném dni a hodině
%
%   Popis:
%       - Funkce rozdělí data do 7 dnů v týdnu a 24 hodin dne.
%       - Pro každou kombinaci dne a hodiny spočítá počet vzorků, průměr a
%         směrodatnou odchylku hodnot p.
%
%   Příklad použití:
%       Time = datetime(2023,1,1,0,0,0) + hours(0:1000);
%       p = rand(1001,1)*100; % simulovaný signál zaplnění
%       [Mmean, Mstd, Mn] = mean_weekly_profile(Time, p);
%


unique_dates=unique(Time);
unique_days=weekday(unique_dates);

Time_hour=hour(Time);
Time_weekday=weekday(Time);
Mn=zeros(7,24);
Mmean=zeros(7,24);
Mstd=zeros(7,24);
Mp={};
wd=1:7;h=0:23;
for i = 1 : 7
    for j = 1:24
        isfit=and(Time_hour==h(j),Time_weekday==wd(i));
        Mn(i,j) = sum(isfit);
        Mmean(i,j) = mean(p(isfit));
        Mstd(i,j) = std(p(isfit));
    end
end


%ind=sub2ind([7 24], Time_weekday,Time_hour+1);
%ypred=int8(abs(p-Mmean(ind))>numstd*Mstd(ind));

end