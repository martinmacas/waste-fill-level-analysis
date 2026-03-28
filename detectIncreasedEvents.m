function detectedIntervals = detectIncreasedEvents(Time, ypred, wlenDays, wlenPrevDays, stepDays, threshold, minCount)
% DETECTINCREASEDEVENTS Detekuje zvýšený výskyt označených událostí
%   pomocí časově klouzavých oken (per-label window sizes) a vrátí
%   tabulku detekovaných intervalů.
%
% Popis (co funkce dělá):
%   Funkce pro každý nenulový štítek (label) prohledává časovou osu pomocí
%   „předchozích“ (previous) a „aktuálních“ (current) oken definovaných v
%   dnech. Pro každé možné umístění předchozího okna spočítá průměrný
%   počet výskytů v předchozích datech (avgPrev) a počet výskytů v následujícím
%   aktuálním okně (currCount). V kódu je aktivní jednoduché pravidlo
%   spuštění detekce: jestliže currCount splňuje podmínku minimálního počtu
%   (`currCount >= minCount(lbl)`), vytvoří se interval. Funkce dále
%   slučuje překrývající se intervaly se stejným štítkem (rozšíří jejich
%   `finishIdx`/`finishTime`) a výsledkem je tabulka s informacemi o
%   detekovaných intervalech.
%
%   Dále režim krokování (prevStarts) je prováděn od konce dat směrem k začátku
%   (descendentní krokování), což zajišťuje detekci novějších událostí
%   dříve.
%
% Požadavky na vstupy:
%   - Time a ypred musí mít stejný počet prvků; budou převedeny na sloupcové vektory.
%
% Vstupní parametry:
%   Time         - datetime vektor (N x 1 nebo 1 x N), časové značky vzorků.
%   ypred        - celočíselný vektor štítků (stejná délka jako Time):
%                  0 = žádná událost, >0 = ID události/štítku.
%   wlenDays     - vektor nebo skalár: délka **aktuálního** okna v dnech pro
%                  každý štítek (pokud je skalár, musí být délka >= počet štítků).
%   wlenPrevDays - vektor nebo skalár: délka **předchozího** okna v dnech pro
%                  každý štítek.
%   stepDays     - skalár: krok klouzavého okna ve dnech (jak moc se posouváme).
%   threshold    - (není v aktuální verzi kódu použit pro spuštění) prahový poměr
%                  currCount > threshold * avgPrev (zůstal v signatuře pro
%                  kompatibilitu, ale aktuální implementace testuje minCount).
%   minCount     - vektor minimálních absolutních hodnot currCount pro každý
%                  štítek; lze dodat scalár (v tom případě se rozšíří na všechny štítky).
%
% Poznámky k logice:
%   - Pokud je `maxPrevStart < 0` (data příliš krátká pro zvolené okna), pro
%     daný štítek se nic nedetekuje.
%   - `prevStarts` jsou generovány s krokem `stepDays` včetně posledního kroku,
%     ale v kódu jsou iterovány od konce k začátku (sort(maxPrevStart:-stepDays:0)).
%   - `avgPrev` je odhad průměrného počtu událostí v předchozích oknech:
%         avgPrev = prevCount * wlen_i / (timeDays(prevIdx(end)) - timeDays(prevIdx(1)))
%     (pozn.: jde o normalizaci podle délky skutečných dat v předchozím okně).
%   - Detekce vytvoří `interval` pouze když `currEnd` leží v rámci dostupných dat
%     a zároveň `currCount >= minCount(lbl)`. (Test s `threshold` je v kódu
%     zakomentovaný.)
%   - Překrývající se intervaly se stejným štítkem se slučují (aktualizuje se finish).
%
% Výstup (tabulka):
%   detectedIntervals - table s následujícími sloupci:
%       'label'      - číselné ID štítku (double)
%       'labelname'  - textový název štítku (char / cellstr)
%       'startIdx'   - index prvního výskytu štítku v rámci detekovaného intervalu
%       'startTime'  - datetime prvního výskytu intervalu
%       'finishIdx'  - index posledního výskytu štítku v rámci intervalu
%       'finishTime' - datetime posledního výskytu intervalu
%       'avgPrev'    - odhad průměrného počtu v předchozích oknech (double)
%       'currCount'  - aktuální počet výskytů v okně (double)  % tento sloupec je 8.
%
%





%
% Detect increased occurrence of labeled events with per-label window sizes.
%
% Inputs:
%   Time         - datetime vector (N x 1 or 1 x N)
%   ypred        - integer vector of labels (same numel as Time)
%                  0 = no event, >0 label ids
%   wlenDays     - scalar or vector (#labels) current-window length(s) in days
%   wlenPrevDays - scalar or vector (#labels) previous-window length(s) in days
%   stepDays     - sliding step in days (scalar)
%   threshold    - trigger if currCount > threshold * avgPrev
%   minCount     - optional minimal absolute count in current window (default 0)
%
% Output:
%   detectedIntervals - struct array with fields:
%                       label, start, finish, currCount, avgPrev, subCounts
%


% if nargin < 7
%     minCount = 0;
% end

% make column vectors
Time = Time(:);
ypred = ypred(:);
if numel(Time) ~= numel(ypred)
    error('Time and ypred must have the same number of elements.');
end

labelnames = {'Odvozy','Ucpany','Svozy','Ztrac.sig.','Spin. senz.', 'Peaky', 'Sesuvy', 'Jine','Propady'};

% numeric time in days relative to first sample
timeDays = days(Time - Time(1));

% unique positive labels
labels = unique(ypred(ypred > 0));
%detectedIntervals = struct('label', {}, 'startIdx', {}, 'startTime', {}, 'finishIdx', {},...
%                            'finishTime', {},'avgPrev',{},'currCount',{});
detectedIntervals = struct('label', nan, 'labelname', nan, 'startIdx', 1, 'startTime', Time(1), 'finishIdx', 1,...
                            'finishTime', Time(1),'avgPrev',0,'currCount',0);

for li = 1:numel(labels)
    lbl = labels(li);
    % current window length for this label
    wlen_i = wlenDays(li);
    % previous window length for this label
    wlenPrev_i = wlenPrevDays(li);
    % valid start times for previous-window such that the current window fits
    maxPrevStart = timeDays(end) - (wlenPrev_i + wlen_i);
    if maxPrevStart < 0
        continue; % data too short for these settings
    end
    %prevStarts = 0:stepDays:maxPrevStart;
    prevStarts = sort(maxPrevStart:-stepDays:0);%starts stepping from the end
    for k = 1:numel(prevStarts)
        detectedIntervals(end).currCount = mean(detectedIntervals(end).currCount); 
        prevStart = prevStarts(k);
        prevEnd = prevStart + wlenPrev_i;
        prevIdx = find(timeDays >= prevStart & timeDays < prevEnd);
%         
%         if isempty(prevIdx)
%             prevCount = 0;
%         else
%             prevCount = sum(ypred(prevIdx) == lbl);
%          end
        if ~isempty(prevIdx)
            prevCount = sum(ypred(prevIdx) == lbl);
            avgPrev = prevCount * wlen_i / (timeDays(prevIdx(end))-timeDays(prevIdx(1)));
            
            % current window (after previous window)
            currStart = prevEnd;
            currEnd = currStart + wlen_i;
          %  if k==numel(prevStarts),keyboard;end
            if currEnd > timeDays(end) + eps
                 
                continue;
            end
            % current window count
            currIdx = find(timeDays >= currStart & timeDays < currEnd);
            if isempty(currIdx)
                currCount = 0;
            else
                currCount = sum(ypred(currIdx) == lbl);
            end
    
            % trigger condition
            %if (avgPrev > 0 && currCount > threshold * avgPrev) || (currCount >= minCount)
            if (currCount >= minCount(lbl))
                interval.label = lbl;
                interval.labelname = labelnames{lbl};
                interval.startIdx = currIdx(1);%beginning of the window
                interval.startTime = Time(interval.startIdx);%time of first appearance of the label within the window
                interval.finishIdx = currIdx(end);
                interval.finishTime = Time(interval.finishIdx);%Time of the last appearance of the label within the window
                interval.currCount = currCount;
                
                interval.avgPrev = avgPrev;
%                 plot([interval.startTime interval.finishTime],[interval.label interval.label],'x-','Color',rand(1,3),'LineWidth',2);
%                 plot([detectedIntervals(end).startTime detectedIntervals(end).finishTime],[interval.label interval.label]-0.2,'x-','Color','c','LineWidth',2);
%                
                if and(interval.label==detectedIntervals(end).label,interval.startIdx<=detectedIntervals(end).finishIdx)
                    detectedIntervals(end).finishIdx = interval.finishIdx;
                    detectedIntervals(end).finishTime = interval.finishTime;
                    %Tady byl bug a ted si nejsem jisty spravnosti opravy.
                    %Nebylo tam mean
                    detectedIntervals(end).currCount = mean([detectedIntervals(end).currCount interval.currCount]);
                else    
                    detectedIntervals(end).currCount = mean(detectedIntervals(end).currCount); 
                    %hold on; patch([detectedIntervals(end).startTime detectedIntervals(end).finishTime  detectedIntervals(end).finishTime detectedIntervals(end).startTime],[lbl+0.1 lbl+0.1 lbl+0.3 lbl+0.3],'green');drawnow
                    detectedIntervals(end+1) = interval; %#ok<AGROW>
                    
                end
            end
        end
    end
    
end
% figure;hold on;
% for i=1:length(detectedIntervals),
%                    plot([detectedIntervals(i).startTime detectedIntervals(i).finishTime],[detectedIntervals(i).label detectedIntervals(i).label],'x-','Color','c','LineWidth',2);
% end
% 
% plot(Time,ypred,'rs','MarkerFaceColor','r');hold on; 


detectedIntervals=struct2table(detectedIntervals);
detectedIntervals=detectedIntervals(2:end,:);
end
