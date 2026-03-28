function t2 = weekratio(t)
%WEEKRATIO Vypočítá poměr uplynulého času v týdnu (weekfraction) jako číslo v rozsahu 0-1
%
%   t2 = weekratio(t) vrátí poměr hodin od začátku týdne (pondělí 0:00)
%   k celkovému počtu hodin v týdnu (168).
%
%   Vstup:
%     t - datetime nebo pole datetime hodnot
%
%   Výstup:
%     t2 - číslo (nebo pole) s hodnotami od 0 do 1, které udává
%          poměr uplynulého času v týdnu (0 = začátek týdne,
%          1 = konec týdne)
%
%   Poznámka:
%     Funkce <a href="weekratio2weektime.html">weekratio2weektime</a> je
%     inverzní funkcí k weekratio, tedy převádí zpět poměr týdne (0–1)
%     na datetime během aktuálního týdne.     
%
%   Příklad:
%     t2 = weekratio(datetime('now','TimeZone','UTC'));
%

    wd = weekday(t);wd=wd-1;wd(wd==0)=7;
    weekstarts = t-days(wd-1);
    weekstarts = datevec(weekstarts);
    weekstarts(:,4:end)=0;
    weekstarts = datetime(weekstarts,'TimeZone','UTC');
    t2 = hours(t-weekstarts)/168;

end
