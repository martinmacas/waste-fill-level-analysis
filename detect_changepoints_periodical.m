function [schedules, ind_start, ind_end] = detect_changepoints_periodical(Time, p, c, varargin)
%DETECT_CHANGEPOINTS_PERIODICAL Detekuje periodické intervaly svozů na základě časové řady.
%
%   [schedules, ind_start, ind_end] = detect_changepoints_periodical(Time, p, c)
%   spustí detekci periodických intervalů svozů s výchozími volitelnými parametry.
%
%   [schedules, ind_start, ind_end] = detect_changepoints_periodical(Time, p, c, 'ParamName', ParamValue, ...)
%   umožňuje upravit volitelné parametry pro zpřesnění detekce.
%
%   Popis funkce:
%       Funkce analyzuje časové rozdíly mezi detekovanými svozy (určenými pomocí
%       indikátorů vektoru c). Na základě podobnosti časových rozestupů hledá
%       periodické intervaly svozů i v případě, že se občas vyskytnou odchylky
%       nebo chybějící detekce. Pro každý nalezený interval odhaduje typickou
%       dobu mezi svozy, typický den v týdnu a typickou hodinu svozu.
%
%   Vstupní parametry:
%       Time        - datetime, časová informace signálu (vektor Nx1)
%       p           - double, vzorky stavu zaplnění nádoby (vektor Nx1)
%                     (není zde přímo využit, slouží pro kompatibilitu)
%       c           - logické nebo číselné indikátory detekovaných svozů (vektor Nx1)
%
%   Volitelné parametry (výchozí hodnoty):
%       'tol_period'   - tolerance v hodinách pro posouzení, kdy jsou dva
%                        intervaly svozu považovány za podobné (default = 24 h)
%
%       'tol_missing'  - kolik po sobě jdoucích intervalů může nesplnit podmínku
%                        podobnosti, aniž by byl periodický segment ukončen
%                        (default = 2)
%
%   Výstupní parametry:
%       schedules       - buňky, kde každý řádek popisuje jeden nalezený
%                         periodický segment:
%                           schedules{n,1}(1) = perioda (v násobcích týdne)
%                           schedules{n,1}(2) = detekovaný den v týdnu (1–7)
%                           schedules{n,1}(3) = detekovaná hodina svozu (0–23)
%
%       ind_start       - indexy prvních prvků jednotlivých segmentů v Time
%
%       ind_end         - indexy posledních prvků segmentů v Time
%

    % Create input parser
    parser = inputParser;
    parser.FunctionName = 'detect_changepoints_general';

    % Define defaults + validation
    addParameter(parser, 'tol_period', 24, @(x) isnumeric(x) && isscalar(x) && x >= 0); % hours
    addParameter(parser, 'tol_missing', 2, @(x) isnumeric(x) && isscalar(x) && x >= 0);

    % Parse optional parameters
    parse(parser, varargin{:});
    params = parser.Results;

    % Convert to numeric differences (in hours)
    ind_c=find(c);
    dT = hours(diff(Time(ind_c)));
    %If the difference is less than week, there must be false positive
    %collection detection and we will ignore them by removing ind_c and dT
    ind_c([false;dT<24*6])=[];
    dT = hours(diff(Time(ind_c)));
%     subplot(3,1,1);hold on; plot(Time(ind_c),p(ind_c),'gs','MarkerFaceColor','g')
%     subplot(3,1,3);plot(Time(ind_c(2:end)),dT/24,'rx');


    N = numel(dT);

    ind_start=[];ind_end=[];schedules=cell(0,1);
    k = 1;idx_miss=0;
    while k <= N
       
        idx_start = k;%max(k-idx_miss+1,1);
        idx_miss = 0;
        valid_diffs = [];

        while k <= N
            if isempty(valid_diffs)
                % First difference initializes reference
                valid_diffs = dT(k);
                k = k + 1;
            else
                ref = median(valid_diffs);
                if abs(dT(k) - ref) <= params.tol_period
                    valid_diffs(end+1) = dT(k);
                    idx_miss = 0;
                    k = k + 1;
                else
                    idx_miss = idx_miss + 1;
                    if idx_miss <= params.tol_missing
                        k = k + 1; % tolerate mismatch
                    else
                        break; % too many mismatches
                    end
                end
            end
        end

        % finalize segment
        idx_end = k-idx_miss;%min(k-idx_miss,N+1);
        dt_typical = mean(valid_diffs); % hours


        wdstrings = {'Sun','Mon','Tue','Wed','Thu','Fri','Sat'};
        daynum = weekday(Time(ind_c(idx_start:idx_end)));
        [M,F] = mode(daynum,1);
        if F(1)/(idx_end-idx_start)>0.5 
            wd = M;%wdstrings{M}; 
        else 
            wd = NaN;%'not detected';
        end

        hournum = mode(hour(Time(ind_c(idx_start:idx_end))),1);
        [M,F] = mode(hournum,1);
        if F(1)/(idx_end-idx_start)>0.5 
            hod = M; 
        else 
            hod = NaN;%'not detected';
        end
        
        
         %disp(k);
        %disp(valid_diffs/24)
        if length(valid_diffs) >=3
            %k = k + 1; % move to next
            ind_start(end+1,1) = ind_c(idx_start+1);
            ind_end(end+1,1) = ind_c(min(idx_end+1,N+1));
           % schedules(end+1,1:3) = {days(hours(dt_typical)),wd, hod} ;
            
           schedules(end+1,1) = {[round(dt_typical/168),wd, hod]} ;
            
        else 
            %k = idx_end+1;
        end
        k = idx_end+1;
%         disp(k);
%          disp('-----------');
%        
    end
if ~isempty(ind_end),ind_end(end) = length(Time);end
end

