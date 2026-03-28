function [schedules, ind_start, ind_end, centers, OPERATES, c] = detect_changepoints(Time, p, c, varargin)
%DETECT_CHANGEPOINTS Detekuje body změn v časové řadě dat na základě detekovaných svozů.
%
%   [schedules, ind_start, ind_end, centers, OPERATES, c] = detect_changepoints(Time, p, c)
%   spustí detekci s výchozími volitelnými parametry.
%
%   [schedules, ind_start, ind_end, centers, OPERATES, c] = detect_changepoints(Time, p, c, 'ParamName', ParamValue, ...)
%   umožňuje přepsat volitelné parametry.
%
%   Vstupní parametry:
%       Time    - datetime, časová informace signálu (vektor Nx1)
%       p       - double, vzorky stavu zaplnění odpadové nádoby v procentech (vektor Nx1)
%       c       - indikátory detekovaných svozů (vektor nebo matice)
%
%   Volitelné parametry (výchozí hodnoty):
%       'toler'         - tolerance v čase, výchozí 9 hodin
%       'timetol'       - časová tolerance, výchozí 16 hodin
%       'countappear'   - minimální počet výskytů, výchozí 4
%       'timeappear'    - čas pro potvrzení výskytu, výchozí 35 hodin
%       'timedisappear' - čas pro potvrzení zmizení, výchozí 30 dní
%       'nantoler'      - minimální mezery v časovém signálu, aby byla považována za výpadek, výchozí 10 hodin
%
%   Výstupní parametry:
%       schedules   - struktura/plán změn v datech
%       ind_start   - indexy začátků stabilních intervalů
%       ind_end     - indexy konců stabilních intervalů
%       centers     - střední body detekovaných změn
%       OPERATES    - informace o provozu (např. aktivita)
%       c           - aktualizované indikátory kolekcí
%
%Detekované svozy lze získat například prahováním pomocí
%detect_collections_thresholding.m nebo jiným detektorem svozů.
%Funkce si v paměti udržuje seznam potencionálních kandidátů na časy plánovaných svozů (ve
%formě seznamu weekratio čísel (viz. weekratio.m).
%Funkce sekvenčně prohledává detekované svozy a počítá vzdálenost daného 
%potenciálního svozu od nejbližšího plánovaného svozu.  
%
%- Pokud je vzdálenost od nejbližšího kandidáta větší než parametr "toler", vytvoří
%nový kandidát na čas plánovaných svozů, jinak se danému kandidátu zvýší jeho počet výskytů o 1
%
%- Potvrzený a aktivní kandidát, který se neobjevil déle než
%"timedisappear" dní, je označen za neaktivního. Do této doby nejsou počítány časy velkých
%mezer (výpadků) delších než "nantoler" hodin.
%
%- Neaktivní kandidát, který se objeví více než "countappear" krát v méně
% než "timeappear" dnech, je nastaven jako potvrzený a aktivní
%
%- Zatím nepotvrzený kandidát, který se neobjeví po dobu "timetol" hodin je úplně odstraněn.
%
%Poté jsou nastaveny indexy začátků stabilních period jako indexy, kde 
%došlo ke změně některého kandidáta ze stavu neaktivní na aktivní.
%Indexy konů stabilních period jsou v tuhle chvíli vždy nastaveny jako
%index o jedna menší než je index následujícího začátku tak, aby každý vzorek signálu patřil
%do některého stabilního intervalu (i když je takový interval velmi
%krátký).


% Create input parser
    parser = inputParser;
    parser.FunctionName = 'detect_changepoint';

    % Define default values and validation
    addParameter(parser, 'toler', 9, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(parser, 'timetol', 16, @(x) isnumeric(x) && isscalar(x));
    addParameter(parser, 'countappear', 4, @(x) isnumeric(x) && isscalar(x));%5
    addParameter(parser, 'timeappear', 35, @(x) isnumeric(x) && isscalar(x));
    addParameter(parser, 'timedisappear', 30, @(x) isnumeric(x) && isscalar(x));%21
    addParameter(parser, 'nantoler', 10, @(x) isnumeric(x) && isscalar(x));

    % Parse optional parameters
    parse(parser, varargin{:});
    params = parser.Results;

    % Assign parsed values to local variables (optional but common)
    toler = params.toler/168;
    timetol = params.timetol;
    countappear = params.countappear;
    timeappear = params.timeappear;
    timedisappear = params.timedisappear;
    nantoler = params.nantoler;
    %Collection time that appears less than or equal to counttol within
    %timetol days is considered only temporary
    %Collection time that did not appear for timetol days is considered
    %as a change (disappeared)
    %New opperation: Collection time that appears at leas countappear times within timeappear days
    
    
    %Time difference
    dT = diff(Time);
    
    %Indexes of potential collections obtained by simple thresholding of
    %relative change
    %c = detect_collections_thresholding(Time,p,[]);
    c = find(c);

    %Their weekratios
    wr=weekratio(Time(c));
    
    %Algorithms scans the signal sequentially and updates following
    %variables 
    
    centers = wr(1);% current centers (collection times)
    count = 1;      % counter of coll. time appearance, zeros when time stops appearing
    last = c(1);    % last appearance of the collection times
    first = c(1);   % first appearance of each collection time after it starts to operate
    n=1;            % number of collections in the collection time since the collection time operates (for online mean update);
    confirmed = 0;  %boolean value that says that the collection time has already been confirmed
    operates = 0;
    %OPERATES = zeros(size(Time,1),1);% history of operation 
    OPERATES = [0];
    for i=2:length(wr)
        %distance from nearest collection time (center)
        dist = abs(centers-wr(i)); 
        [mindist,ind] = min(dist);
    
        %if a new collection time appears, create new one, otherwise,
        %update the information about the existing collection time
        if mindist > toler %create new center
            n=[n 1];
            centers = [centers wr(i)];
            count = [count 1];
            last = [last c(i)];
            first = [first c(i)];
            confirmed = [confirmed 0];
            operates = [operates 0];
            OPERATES(:,size(centers,2)) = zeros(size(OPERATES,1),1);
        else                %update an existing center
            n(ind)=n(ind)+1;
            centers(ind)=(n(ind)*centers(ind)+wr(i))/(n(ind)+1);
            count(ind) = count(ind)+1;
            last(ind) = c(i);
            if isnan(first(ind)),first(ind) = c(i);end 
        end
    
        %%Only for debugging
%         hold on;plot(Time(c(i)),centers,'r.');
%         %plot(Time(c(i)),centers(1),'m.');
%         drawnow
       % if centers(1)<0.52,keyboard;end;
        %disp([confirmed;centers;count;days(Time(c(i))-Time((last))');operates]);    
        
        %DISAPPEARANCE OF ALREADY CONFIRMED COLLECTION TIME
        timegap = duration([0 0 0])*ones(1,length(last));
        
        for j = 1:length(last)
            dTbetween = dT(last(j):c(i));%time gaps bewtween actual position and last appearance of each center
            timegap(1,j) = sum(dTbetween(dTbetween>hours(nantoler)));%sum of too big gaps longer than nantoler hours
        end

        %DETECTION OF DISAPPEARANCE OF A COLLECTION TIME WHEN IT OPERATES
        %If a confirmed and operating collection time did not appear longer than timedisappear days,
        %set its "operates" flag to false
        disapears=and(days(Time(c(i))-Time(last)'-timegap)>timedisappear,confirmed);
        disapears=and(disapears,operates);
        if any(disapears)
                %OPERATES(sub2ind(size(OPERATES),last(disapears),find(disapears)))=-1;
                OPERATES(repmat(Time(c(1:i)),1,sum(disapears))>Time(last(disapears))')=0;
                count(disapears)=0;
                first(disapears)=NaN;
                operates(disapears)=0;
        end
            
        %CONFIRMATION OF A NEW COLLECTION TIME
        %If a nonoperating collection time appeart more than "countappear"
        %times, 
        if and(operates(ind)==0, count(ind)>=countappear)
            indoper = find(abs(centers(ind)-wr(1:i))<toler);% find indices of collections in that time
            %and if last "countappear" appearances occured in less than
            %timeappear days, set its set its "confirmed" flag to true
            %(even if its true) and set the "operates" flag and proper field of "OPERATES" to +1 
            if Time(c(indoper(end-countappear+1)))>=Time(c(i))-days(timeappear)
                confirmed(ind) = 1;
                
               % if i == 17, keyboard;end
                OPERATES(indoper(end-countappear+1):end,ind)=1;
               % OPERATES(indoper(end-countappear+1):i,ind)=1;
                
                operates(ind)=1;
            end
        end
        
        %For debugging purposes
        %if Time(c(i))>datetime([2024 7 15],'TimeZone','UTC'),keyboard;end
        % if i>40,keyboard;end
    
        %DELETE OF TEMPORARY CENTERS
        %If a collection time is not yet confirmed and did not appear for "timetol" hours, remove it  
        toremove = and(~confirmed,days(Time(c(i))-Time(last)')>timetol);
        OPERATES(:,toremove)=[];
        n(toremove)=[];
        centers(toremove)=[];
        confirmed(toremove)=[];
        count(toremove)=[];
        last(toremove)=[];
        first(toremove)=[];
        operates(toremove)=[];
      
        OPERATES = [OPERATES;operates];
                  
    end
    
    %Sort all the information according to collection time for output
    [centers,b]=sort(centers);
    OPERATES=OPERATES(:,b);
    confirmed = find(confirmed(b));
    
    %Output only confirmed collection times
    centers=centers(confirmed);
    OPERATES = OPERATES(:,confirmed);
    %
    indlast = find(any(OPERATES~=0,2),1,'last');
    


    %Find stable periods without schedule change
    
    min_days = 0;%minimum days the stable period must have to be considered
    ind_start = [1;find(~all(diff(OPERATES)==0,2))+1];%Index from of row of OPERATIONS, at which the change happens
    ind_end = [ind_start(2:end)-1;length(c)];
    
%     is_long_enough=Time(c(ind_end))-Time(c(ind_start))>hours(min_days*24);
% 
%     ind_start = ind_start(is_long_enough);
%     ind_end = ind_end(is_long_enough);
%     
    OPERATES = logical(OPERATES);
    schedules = mat2cell(OPERATES(ind_start,:),ones(length(ind_start),1));
    schedules = cellfun(@(x) centers(x),schedules,'UniformOutput',false);
    
    ind_start = c(ind_start);
    ind_end = c(ind_end);


    ind_end(end) = length(Time);
    

end
