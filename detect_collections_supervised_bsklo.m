function [c, scores, threshold, afterpicklevel,picklevel] = detect_collections_supervised_bsklo(Time,p, threshold,schedule)
% DETECT_COLLECTIONS_SUPERVISED_BSKLO detekuje svozy odpadu pro barevné sklo a pomalu se plnící nádoby pomocí klasifikačního modelu. 
%
%   [c, scores, threshold, afterpicklevel] = DETECT_COLLECTIONS_SUPERVISED_BSKLO(Time, p, threshold, schedule)
%   
%   Jedná se o detekci svozů pomocí klasifikačního modelu. Naučený a optimalizovaný model spolu s prahem pro score je uložen 
%   v souboru model_collection_supervised.mat. Model musí být naučen pomocí
%   Statistical and Machine Learning toolboxu. Příkladem vhodného modelu je model naučený pomocí 
%   Mdl = fitcensemble(X,y,'OptimizeHyperparameters','auto'); Kód pro učení
%   modelu je v demo_train_collection_supervised.m a
%   demo_train_collection_supervised_2.m.
%   
%   Vstupní parametr schedule může být získán z externího zdroje
%   (předepsaný rozvrh svozů) anebo detekován pomocí detect_changepoints.m.
%   Předpokládaný rozvrh svozů může podstatně zvýšit přesnost detekce
%   svozů, protože model může jako příznak využít vzdálenost od předpokládaného
%   svozu.
%
%   Práh lze dodat externě pomocí parametru threshold nebo načíst předem optimalizovaný práh ze souboru
%   (Nastavením threshold na []). Model uložený  v model_collection_supervised.mat je naučený na datech
%   pro papír, ale může být přepoužit pro jiné rychle se plnící kontejnery. 
%   
%   Pozn. Pokud bude vytvořen model pro danou komoditu zvlášť je
%   nutné vytvořit kopii této funkce (např. detect_collections_plastics) a
%   unvitř změnit název souboru s příslušným modelem dedikovaným dané komoditě.
%   
%   Vstupní parametry:
%       Time            - datetime, časová informace signálu (vektor Nx1)
%       p               - double, vzorky stavu zaplnění odpadové nádoby v procentech (vektor Nx1)
%       threshold       - práh (pokud se nastaví na [], je jeho hodnota přečtena ze souboru model_collection_thresholding.mat) 
%       schedule        - rozvrh svozů, v tuhle chvíli není u prahování použit, lze nastavit jakkoliv 
%
%   Výstupní parametry:
%       c               - indikátory detekovaných svozů (vektor Nx1)
%       scores          - predikční skóre (vektor Nx1)                - 
%       threshold       - skutečně použitý práh (double)
%       afterpicklevel  - hodnoty zaplněnosti těsně po každém detekovaném svozu (vektor mx1),
%                         kde m je počet detekovaných svozů  
%
%   Příklad použití:
%       [c, scores, th, apl] = detect_collections_thresholding(Time, p, 0.2, schedule);
%       [c, scores, th, apl] = detect_collections_thresholding(Time_all,p_all,[]);
%
%
%   Podobná funkce: detect_collections_thresholding.m, detect_collections_sueprvised.m 
%

if ~issorted(Time,'ascend')
    error('The time must be sorted in order to use detect_collections.m!');
end


if isempty(schedule) %If collection schedule is not provided
    %If no threshold was provided, use 0.5
    if ~isempty(threshold)
        load("model_collection_supervised_bsklo_nosched.mat",'Mdl');
    else
        threshold = 0.5;
        load("model_collection_supervised_bsklo_nosched.mat");
    end
else %If collection schedule is provided
    %If no threshold was provided, use 0.5
    if ~isempty(threshold)
        load("model_collection_supervised_bsklo.mat",'Mdl');
    else
        threshold = 0.5;
        load("model_collection_supervised_bsklo.mat");
    end
end

%only negative differences are potential collections
indnegdiff = find(diff(p)<0);
indnegdiff(indnegdiff<=10)=[];indnegdiff(indnegdiff>length(Time)-3)=[];


%Feature extraction
if isempty(schedule)
    Xts = extract_features_collection_bsklo_nosched(p,Time,schedule,indnegdiff);
else
    Xts = extract_features_collection_bsklo(p,Time,schedule,indnegdiff);
end

%Predict score for each potential collection
[~,scores_candidate] = predict(Mdl,Xts);

%Take only score for class 1 (collection)
scores_candidate = scores_candidate(:,2);
scores = zeros(length(Time),1);
scores(indnegdiff) = scores_candidate;%set candidate scores to predicted value and the others keep 0

%Classification itself
c = scores>=threshold;

%Fill level before and after each collection
picklevel =p(c);
afterpicklevel =p(circshift(c,1));
end