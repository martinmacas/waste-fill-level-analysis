function [c, scores, threshold, afterpicklevel] = detect_collections_thresholding(Time,p, threshold, schedule)
% DETECT_COLLECTIONS_THRESHOLDING detekuje svozy odpadu pomocí prahování relativní diference zaplněnosti. 
%
%   [c, scores, threshold, afterpicklevel] = DETECT_COLLECTIONS_THRESHOLDING(Time, p, threshold, schedule)
%   
%   Jedná se o prosté prahování. Score je zde záporná hodnota relativní změny zaplněnosti
%   score(k) = -(p(k)-p(k-1))/p(k). Čím větší score, tím větší pravděpodobnost svozu.
%   Svoz je detekovaný pokud je score nadprahové, tedy c(k)=1 pokud score(k)>threshold.
%   
%   Práh lze dodat externě pomocí parametru nebo načíst předem optimalizovaný práh ze souboru.
%   Prahování není pro detekci svozů tak dobré, ale lze ho využí jako
%   iniciální odhad polohy svozů před detekcí svozových rozvrhů a 
%   detekcí intervalů se stabilním svozovým rozvrhem. 
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
%   Podobná funkce: detect_collections_supervised.m 
%
if ~issorted(Time,'ascend')
    error('The time must be sorted in order to use detect_collections.m!');
end

if isempty(threshold)
    load('Models\model_collection_thresholding.mat');
end

% %Set score so that score>threshold means collection
% scores = -[diff(p)./p(1:end-1);0];
% positive = scores(scores>0);
% 
% %If no threshold was provided, compute it using minimum of histogram of score
% if isempty(threshold)
%     
%     [hy,hx]=histcounts(positive,0:0.05:1);
%     hx=(hx(1:end-1)+hx(2:end))/2;
%     hy = smoothdata(hy,2,'movmean',3);
% %     figure;
% %     plot(hx,hy);
% %     
%     indpart = round(0.2*length(hy)):round(0.9*length(hy));
%     hymin=min(hy(indpart));
%     indxmin = find(hy(indpart)==hymin); % if there will be more hy with minimum values, use mean
%     threshold = mean(hx((indxmin)));
%     
%     
% end
% %Thresholding of the -relative change -(p(t+1)-p(t))/p(t))
% c = scores > threshold;
% 
% %Fill level after each collection
% afterpicklevel =(p(circshift(c,1)));


%Uvažuj pouze body s poklesem úrovně odpadu
indnegdiff = find(diff(p)<0);
%Neuvažuj prvních a posledních 10 vzorků
indnegdiff(indnegdiff<=10)=[];indnegdiff(indnegdiff>length(Time)-10)=[];

scores_candidate = -(p(indnegdiff+1)-p(indnegdiff))./p(indnegdiff);
scores = zeros(length(Time),1);
scores(indnegdiff) = scores_candidate;%set candidate scores to predicted value and the others keep 0

%ALETERNATIVE
%Alternative for adaptive threshold tailored for the particular signal
%If no threshold was provided, compute it using minimum of histogram of score
% if isempty(threshold)
%     
%     [hy,hx]=histcounts(scores(indnegdiff),0:0.05:1);
%     hx=(hx(1:end-1)+hx(2:end))/2;
%     hy = smoothdata(hy,2,'movmean',3);
% %     figure;
% %     plot(hx,hy);
% % %     
%     indpart = round(0.2*length(hy)):round(0.9*length(hy));
%     hymin=min(hy(indpart));
%     indxmin = find(hy(indpart)==hymin); % if there will be more hy with minimum values, use mean
%     threshold = mean(hx(indpart(indxmin)));
% 
% end


c = scores>threshold;
%Fill level after each collection
afterpicklevel =(p(circshift(c,1)));

end