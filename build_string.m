function textual_result = build_string(analysis)

if ~isempty(analysis) 
        
    %BUILD_STRING Formats the analysis results into readable grouped text.
    
    %n = numel(analysis);
    textual_result = {};  % cell array of strings for TextArea
    
    for i = 1:numel(analysis)
            a = analysis(i);
            %lines = {};  % temp storage for this period
            lines = {'-------------------------------------------------------------------------------------------------'};
            
            % === Header for the period ===
            periodHeader = sprintf('Interval %d, %.0f dni, %d vzorku, %s  →  %s ', a.period, ...
            a.days, a.samples, ...
            datestr(a.time_start, 'dd-mmm-yyyy'), ...
            datestr(a.time_end,     'dd-mmm-yyyy'));
            lines{end+1} = periodHeader;
    
            lines{end+1} = '';
            lines{end+1} = sprintf('Pocet vypadku signalu delsich nez 1 den: %d (%.0f%% doby)', a.counts(4), 100*a.lostsig_ratio);
  

            lines{end+1} = '';
            
            if ~isempty(a.schedule)
                % --- Waste Collections ---
                % Convert schedule week ratios to day/time strings
                lines{end+1} = 'Detekovany rozvrh svozu:     ';
                switch a.collection_mode
                    case 'periodical'
                        names = {'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'};
                        if isnan(a.schedule(2)),
                            lines{end+1} = sprintf('Kazde %d tydny',round(a.schedule(1)));
                        else
                            lines{end+1} = sprintf('Kazde %d tydny, den: %s',round(a.schedule(1)),names{a.schedule(2)});
                        end
                    case 'weekly'
                        scheduleTimes = datestr(weekratio2weektime(a.schedule), 'ddd HH:MM');
                        line=[];
                        for k = 1:size(scheduleTimes, 1)
                            line =[line sprintf('%s   ', strtrim(scheduleTimes(k, :)))];
                        end
                        lines{end+1} = line;
                end
    
                lines{end+1} = sprintf('Pocet detekovanych svozu: %d,       Neprobehle nebo podezrele svozy: %d (%.1f %%)', a.num_collections,a.misscoll_num,a.misscoll_ratio);
                lines{end+1} = sprintf('Prumerne zaplneni pred svozem: %.0f %%,       Prumerne zaplneni po svozu: %.0f %%', a.meanlevel_before,a.meanlevel_after);
            else
                lines{end+1} = 'Pravidelny rozvrh svozu nebyl detekovan!';
                
            end



            lines{end+1} = '';
            lines{end+1} = 'Pocty detekovanych udalosti:';
            lines{end+1} = sprintf('Ucpany vhoz: %d, Vypadek: %d, Peak nahoru: %d, Sesuv: %d, Propad: %d', a.counts(2),a.counts(4),a.counts(6), a.counts(7), a.counts(9));
    
            lines{end+1} = 'Pocty za tyden:';
            lines{end+1} = sprintf('Ucpany vhoz: %.1f, Vypadek: %.1f, Peak nahoru: %.1f, Sesuv: %.1f, Propad: %.1f', a.countsw(2),a.countsw(4),a.countsw(6), a.countsw(7), a.countsw(9));
            
            lines{end+1} = '';
            if ~isempty(a.alesscurr)
                lines{end+1} = 'Optimalizace:';
                lines{end+1} = 'Rozvrh svozu:     ';
                                switch a.collection_mode
                                    case 'periodical'
                                        lines{end+1} = sprintf('Kazde %d tydny, den: %s',round(a.schedule(1)),names{a.schedule(2)});
                                    case 'weekly'
                                        scheduleTimes = datestr(weekratio2weektime(a.schedule), 'ddd HH:MM');
                                        line=[];
                                        for k = 1:size(scheduleTimes, 1)
                                            line =[line sprintf('%s   ', strtrim(scheduleTimes(k, :)))];
                                        end
                                        lines{end+1} = line;
                                end

                lines{end} = [lines{end} ' --> '];
                                switch a.collection_mode
                                    case 'periodical'
                                        lines{end} = [lines{end} sprintf('Kazde %d tydny, den: %s',round(a.scheduleopt(1)),names{a.scheduleopt(2)})];
                                    case 'weekly'
                                        scheduleTimes = datestr(weekratio2weektime(a.scheduleopt), 'ddd HH:MM');
                                        line=[];
                                        for k = 1:size(scheduleTimes, 1)
                                            line =[line sprintf('%s   ', strtrim(scheduleTimes(k, :)))];
                                        end
                                        lines{end} = [lines{end} line];
                                end
                lines{end+1} = sprintf('Prumerne zaplneni pred svozem:  %.0f %% -->  %.0f %%',a.meanlevel_before_curr,a.meanlevel_before_optimized);
                lines{end+1} = sprintf('Prumerna rocni nevyuzita kapacita:  %.0f kont. -->  %.0f kont.',round(365*a.alesscurr/a.days/100),round(365*a.alessopt/a.days/100));
                lines{end+1} = sprintf('Prumerne rocni preplnovani:  %.0f kont. -->  %.0f kont.',round(365*a.amorecurr/a.days/100),round(365*a.amoreopt/a.days/100));
                lines{end+1} = sprintf('Zlepseni poduzivani: %.1f kont., Zlepseni preplnovani: %.1f kont.',365*a.underutil/a.days/100,365*a.overfil/a.days/100);
            end
        
        % Add a blank line after each period
        lines{end+1} = ' ';

        % Append to global output
        textual_result = [textual_result, lines];
    end

else
        textual_result = {'No stable collection schedules found.'};
end

end

% Helper ternary function
function out = ternary(condition, valTrue, valFalse)
    if condition
        out = valTrue;
    else
        out = valFalse;
    end
end
