function wt = weekratio2weektime(wr)
%WEEKRATIO2WEEKTIME Inverzní funkce k weekratio - převádí poměr týdne na datetime
%
%   wt = weekratio2weektime(wr) převede číslo (nebo pole čísel) v rozsahu 0-1,
%   které reprezentuje poměr uplynulého času v týdnu (weekfraction),
%   zpět na datetime během aktuálního týdne (od pondělí 0:00 UTC).
%
%   Vstup:
%     wr - číslo nebo pole čísel v rozsahu 0 až 1
%
%   Výstup:
%     wt - datetime (nebo pole datetime) odpovídající danému poměru týdne,
%          počítáno od předchozího pondělí (00:00 UTC).
%
%   Poznámka:
%     Tato funkce je inverzní k funkci <a href="weekratio.html">weekratio</a>, která převádí datetime na
%     poměr týdne v rozsahu 0-1.
%
%   Příklad:
%     wt = weekratio2weektime(0.5); % datetime odpovídající středu uprostřed týdne
%

tmonday=dateshift(datetime('today','TimeZone','UTC'),'dayofweek','Monday','previous');
wt=(tmonday+days(wr*7));