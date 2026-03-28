function TT = estimate_disposal(TT,cdetected)
% ESTIMATE_DISPOSAL  Výpočet odhadu množství uloženého odpadu mezi časovými značkami.
% 
%    TT = ESTIMATE_DISPOSAL(TT, cdetected)
%    
%    doplní do tabulky TT nový sloupec dp, který představuje odhad množství 
%    odpadu uloženého (nebo potenciálně uloženého) mezi dvěma po sobě jdoucími 
%    časovými okamžiky TT.Time. Hodnota dp se využívá při simulaci průběhu 
%    zaplnění nádoby a výpočtu ztrátových funkcí pro optimalizaci svozových rozvrhů.
% 
%    Výpočet dp vychází z diferenci signálu zaplnění TT.p, přičemž jsou 
%    odstraněny nežádoucí artefakty jako náhlé výkyvy způsobené anomáliemi 
%    nebo svozy, které by zkreslovaly odhad. Pro tyto části jsou hodnoty dp 
%    nastaveny na NaN a následně doplněny pomocí interpolace mediánem hodnot 
%    odpovídajících stejné hodině a dni v týdnu.
% 
%    Vstupní parametry:
%        TT          - timetable (NxM)
%                      Tabulka obsahující alespoň sloupec:
%                          • p : double (Nx1), úroveň zaplnění nádoby v procentech
%                          • Time : datetime (Nx1), časové značky datových vzorků
%                      
%        cdetected   - logical/double (Nx1)
%                      Indikátory detekovaných svozů (např. binární vektor),
%                      kde 1 značí přítomnost svozu.
% 
%    Výstupní parametry:
%        TT          - timetable (NxM+1)
%                      Rozšířená tabulka TT se sloupcem dp, kde
%                      dp(i) je odhad přírůstku odpadu mezi TT.Time(i-1) a TT.Time(i).
%                      První hodnota dp je NaN, protože pro první záznam není
%                      rozdíl definován.
% 
%    Popis algoritmu:
%        • Vypočte se diferenciální přírůstek dp = diff(TT.p).
%        • Detekují se „peaky" signálu zaplnění pomocí heuristické detekce
%          anomálií (funkce anomaly_detection_heuristic.m nebo anomaly_detection_heuristic_bsklo.m). Okolí vrcholů 
%          je označeno jako neznámé (NaN) v dp, aby se eliminovaly falešné skoky.
%        • Hodnoty dp v okamžicích svozů jsou nastaveny na NaN, aby se svoz 
%          nepočítal jako negativní přírůstek odpadu.
%        • Dále jsou NaN nastaveny tam, kde je nádoba plná (p = 100 %) nebo tam,
%          kde klesá příliš rychle, což značí nevalidní změny.
%        • Chybějící hodnoty dp (NaNy) jsou následně interpolovány mediánem 
%          hodnot dp ze stejné hodiny a dne v týdnu, což zajistí konzistentní 
%          odhad odpadu i v nepřesných úsecích signálu.
%        • Upravený vektor dp je přidán do tabulky TT jako nový sloupec.
% 
%    Poznámky:
%        • Funkce je klíčová pro simulace zaplnění kontejnerů v rámci optimalizace 
%          svozových rozvrhů, kdy je třeba věrně modelovat ukládání odpadu mezi svozy.
%        • Kvalita odhadu závisí na kvalitě a frekvenci původních dat TT.p a přesnosti
%          detekce svozů cdetected.
%        • Funkce využívá pomocnou heuristickou funkci anomaly_detection_heuristic_bsklo 
%          pro identifikaci nevalidních skoků v datech.
% 


dp=[nan;diff(TT.p)];

%This prevents sudden and false increases and decreases of the waste level
%(sudden positive and negative values of estimated waste disposal) due to
%peaks of fill level signal p. Peaks in p are replaced by NaN and later
%replaced by an interpolation.
%Find peaks and set diff unknown before and after peak
ypred = anomaly_detection_heuristic_bsklo(TT.Time, TT.p);
ispeak = ypred==6;
dp(ispeak)=NaN;%remove difference before peak
dp(logical([0; ispeak(1:end-1)]))=NaN;%remove difference after peak

%Set diff unknown during collection, because we do not want collection in
%the waste disposal signal dp
dp(logical([0; cdetected(1:end-1)]))=NaN;%remove difference during collection
dp([0;TT.p(1:end-1)]==100)=NaN;%Mark Nan if there is 100% on the left side from current time

%dp(dp<-50)=NaN;%Where p is decreasing, mark as undefined

%dp(dp./[NaN;TT.p(1:end-1)]<-0.7)=NaN;%Where p is decreasing, mark as undefined

%dp(TT.p==100)=NaN;%Where container is full, mark as undefined

%Replace NaNs by medians of known values in the same hour of the same
%weekday (this is that interpolation)
newdp = dp;
for i = find(isnan(dp))'
    newdp(i) = nanmedian((dp((and(weekday(TT.Time)==weekday(TT.Time(i)),hour(TT.Time)==hour(TT.Time(i)))))));
end
dp = newdp;
TT=addvars(TT,dp);
