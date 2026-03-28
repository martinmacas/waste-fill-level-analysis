function p = fill_nans(Time, p)
function p = fill_nans(Time, p)
%FILL_NANS Interpoluje a vyplňuje chybějící (NaN) hodnoty přírůstku signálu zaplnění.
%
%   p = FILL_NANS(Time, p)
%
%   Funkce zpracuje signál zaplnění nádoby p měřený v časech Time a nahradí
%   chybějící nebo nevalidní přírůstky mezi vzorky odhadem založeným na
%   mediánu přírůstků v blízkém časovém okolí (v rámci stejného týdne a hodiny).
%   Výsledkem je vyhlazený signál zaplnění s doplněnými hodnotami, který je
%   získán kumulativním součtem odhadovaných přírůstků.
%
%   Vstupní parametry:
%       Time - datetime (Nx1) časové značky vzorků signálu
%       p    - double (Nx1) hodnoty signálu zaplnění nádoby (v procentech)
%
%   Výstupní parametry:
%       p    - double (Nx1) upravený signál zaplnění, kde jsou chybějící nebo
%              nevalidní přírůstky nahrazeny mediánem okolních přírůstků a
%              zaplnění je zrekonstruováno kumulativním součtem.
%
%   Popis algoritmu:
%       - Spočítá se přírůstek zaplnění dp mezi jednotlivými časovými vzorky,
%         přičemž záporné přírůstky jsou ignorovány.
%       - Pro každý NaN v dp se vypočítá medián přírůstků ve stejném týdnu a
%         hodině (v rámci malého časového okna).
%       - Tyto mediány nahradí chybějící přírůstky v dp.
%       - Upravený signál p je získán kumulativním součtem těchto přírůstků.
%
%   Poznámka:
%       Funkce předpokládá, že signál p je v procentech a časové značky Time
%       jsou seřazeny vzestupně.
%


wr = weekratio(Time);
dp = diff([NaN;p])./hours(diff([Time(1);Time]));
%dp(dp<0)=0;
for i = find(isnan(dp))'
    
    isnear = abs(wr-wr(i))<1/24/7;
    dpnear = dp(isnear);
    dpnear(dpnear<0)=[];
    dp(i) = nanmean(dpnear);
    
end
p = cumsum([p(1);dp(2:end).*hours(diff(Time))]);


%Estimate waste disposal where it cannot be computed by diff (slides and
%collections)
dp=[nan;diff(TT.p)];
dp(dp<-2)=NaN;%Where p is decreasing, mark as undefined
%dp(TT.p==100)=NaN;%Where container is full, mark as undefined
dp([0;TT.p(1:end-1)]==100)=NaN;%Mark Nan if there is 100% on the left side from current time

%Replace NaNs by medians of known values in the same hour of the same
%weekday
newdp = dp;
for i = find(isnan(dp))'
    newdp(i) = nanmedian((dp((and(weekday(TT.Time)==weekday(TT.Time(i)),hour(TT.Time)==hour(TT.Time(i)))))));
end
dp = newdp;
TT=addvars(TT,dp);
