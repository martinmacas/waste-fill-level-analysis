function update_alarm_excel(Time,p,ypred,T)

for i=1:size(T,1)

    idx = T(i,:).startIdx:T(i,:).finishIdx;
    ypred_part = ypred(idx(1):idx(end));
    Time_part = Time(idx);
    p_part = p(idx);
   
    f = figure;
    plot(Time_part,p_part,'.-');hold on;
    islabel = ypred_part==T(i,:).label;
    scatter(Time_part(islabel),p_part(islabel),40,'r','filled');
    ylim([0 100]);
    grid on;
    title([T(1,:).Odpad{1} ':' T(1,:).Adresa{1} ' / ' T(1,:).Ctvrt{1}]);    
       
    % 2. Určení cesty a názvu souboru pro obrázek
    imageDir = 'waste_alarms_local';
    %imageFilename = sprintf('alarm_%d_%d_%s.png',T(i,:).ID,T(i,:).label,datestr(T(i,:).startTime,'dd_mm_yyyy'));
    

    s = ['alrm' num2str(T(i,:).label) '_' T(i,:).Adresa{1} '_' T(i,:).Odpad{1} '_' datestr(T(i,:).startTime,'dd_mm_yyyy')];
    s = char(s);
    % 2) Nahrazení nepřípustných znaků podtržítkem
    s = regexprep(s, '[^\w.-]', '_');
    % 3) Odstranění vícenásobných podtržítek
    s = regexprep(s, '_+', '_');
    % 4) Odstranění podtržítek na začátku a konci
    s = regexprep(s, '^_|_$', '');
    imageFilename = [s '.png'];






    imageFullPath = fullfile(pwd,imageDir, imageFilename);
    shareDir = 'H:\My Drive\waste_alarms';
    
    % 3. Uložení figure
    % '-dpng' určuje formát PNG, '-r300' nastavuje vysoké rozlišení (300 DPI)
    print(f, imageFullPath, '-dpng', '-r300');
    
    % Zavřete figure, pokud ho již nepotřebujete
    close(f); 
    
    % 1. Určení souboru Excel a buňky
    excelFilename = 'alarmy_odpady.xlsx';
    excelFullPath = fullfile(pwd,imageDir, excelFilename);
    excelSheet = 'alarmy';
    linkText = imageFilename; % Text, který se zobrazí v buňce
    
    % 2. Spuštění Excelu jako COM Serveru
    excel = actxserver('Excel.Application');
    excel.Visible = true; % Zviditelnění Excelu (pro kontrolu)
    
    % 3. Otevření existujícího nebo vytvoření nového sešitu
    if exist(excelFullPath, 'file')
        workbook = excel.Workbooks.Open(excelFullPath);
    else
        workbook = excel.Workbooks.Add();
        workbook.SaveAs(excelFullPath);
    end
    
    % 4. Získání nebo vytvoření listu v rámci workbooku
    try
        sheet = workbook.Worksheets.Item(excelSheet);
    catch
        % Pokud list neexistuje, vytvoříme nový
        sheet = workbook.Worksheets.Add([], workbook.Worksheets.Item(workbook.Worksheets.Count));
        sheet.Name = excelSheet;
    end
    
    % 5. Aktivace listu
    sheet.Activate;
    
    % 6. Najdi poslední použitý řádek ve sloupci B (pokud soubor existoval)
    if exist(excelFullPath, 'file')
        rowsCount = sheet.Rows.Count;
        lastCell = sheet.Range(sprintf('B%d', rowsCount));
        lastRow  = lastCell.End(-4162).Row;   % -4162 = xlUp
        targetCell = ['A' num2str(lastRow + 1)];
    else
        targetCell = 'A2'; % počáteční buňka, pokud soubor nově vytvořen
    end

    
    % 3. Vytvoření hypertextového odkazu
    % Použijeme metodu Add s následujícími parametry:
    % Anchor: Buňka (rozsah), kde má být odkaz
    % Address: Úplná cesta k cílovému souboru
    % TextToDisplay: Text, který bude zobrazen v buňce
    
    sheet.Hyperlinks.Add( ...
        sheet.Range(targetCell), ... % Cílová buňka (Anchor)
        imageFilename, ...          % relativni cesta k souboru (Address)
        '', ...                     % SubAddress (necháme prázdné)
        'Kliknutím zobrazíte celý graf.', ... % ScreenTip (bublina s nápovědou)
        linkText ...                % Text zobrazený v buňce (TextToDisplay)
    );
%         imageFullPath, ...          % Úplná cesta k souboru (Address)
    

    
    % ===== převod cílového řádku z "B12" → 12
    rowNum = str2double(regexprep(targetCell,'[A-Z]',''));
    
    % ===== data z tabulky T (1 řádek, bez hlaviček)
    rowData = table2cell(T(i,:));
    
    % ===== převod dat pro Excel
    for k = 1:numel(rowData)
        if isdatetime(rowData{k})
            matlabDate = datenum(rowData{k});
            excelDate = matlabDate - datenum('30-Dec-1899');
            rowData{k} = excelDate;
            %rowData{k} = datenum(rowData{k});   % Excel-friendly datetime
        elseif iscell(rowData{k})
            rowData{k} = rowData{k}{1};          % {'text'} → 'text'
        end
    end
    endColLetter = char('B' + width(rowData) - 1);   % B + počet sloupců
    writeRange = sheet.Range( ...
    sprintf('B%d:%s%d', rowNum, endColLetter, rowNum) );

    % zápis
    writeRange.Value = rowData;








    % 4. Uložení a ukončení
    workbook.Save();
    workbook.Save();
    workbook.Close(false);
    excel.Quit();
    delete(excel);

    try
      copyfile(excelFullPath, fullfile(shareDir,excelFilename), 'f');
    catch
    end


    try
      copyfile(imageFullPath, fullfile(shareDir,imageFilename), 'f');
    catch
    end













end



end