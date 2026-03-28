function [c, scores, threshold, afterpicklevel] = detect_collections_ocsvm(Time,p, threshold)

if ~issorted(Time,'ascend')
    error('The time must be sorted in order to use detect_collections.m!');
end

%Prediction of anomality score where normality is collection!!!!! 
mdl = load("model_collection_ocsvm.mat",'mdl');
mdl = mdl.mdl;

indnegdiff = find(diff(p)<0);
indnegdiff(indnegdiff<=10)=[];indnegdiff(indnegdiff>length(Time)-10)=[];
Xts = extract_features_collection(p,Time,indnegdiff);
[~,scores] = predict(mdl,Xts); scores=-scores;
%scores = [NaN(10,1);scores;NaN(10,1)];

%If no threshold was provided, compute it
if isempty(threshold)
    
    [hy,hx]=histcounts(scores,30);
    hx=(hx(1:end-1)+hx(2:end))/2;
    

%     figure;
%     plot(hx,hy);
    
    hy = smoothdata(hy,2,'movmean',3);
        
    indpart = round(0.2*length(hy)):round(0.8*length(hy));
    hymin=min(hy(indpart));
    indxmin = (hy(indpart)==hymin); % if there will be more hy with minimum values, use median
    threshold = median(hx(indpart(indxmin)));
%    hold on;plot(hx,hy);plot(hx(indpart(indxmin)),hymin,'r+','MarkerSize',10);
    
    %Change threshold so that score>threshold means collection
    threshold = 1-threshold;

end



%Change score so that score>threshold means collection
scores = 1 - scores;

%figure; hist(scores);hold on;plot(threshold,0,'r+')

%Classify
indc=indnegdiff(scores>threshold);

% %Remove 
% toremove=[];
% for k = 1:length(indc)
% 
%     a = find(abs(Time(indc(k))-Time(indc))<hours(10));
%     
%     if length(a)>1
%        ismin = scores(indc(a))==min(scores(indc(a)));
%        toremove = [toremove;indc(a(~ismin))];
%        a = a(ismin);
%     end
%     
%     if length(a)>1
%          dp=p(indc(a)+1)-p(indc(a));
%          ismin = dp==min(dp);
%          toremove = [toremove;indc(a(~ismin))];
%          a = a(ismin);
%     end
%     
%     if length(a)>1
%         toremove = [toremove;a];
%     end
% 
% end
% 
% indc = setdiff(indc, toremove);

%Create binary collection labels
c = zeros(length(Time),1);
c(indc) = 1;
c = logical(c);

%Fill level after each collection
afterpicklevel =(p(circshift(c,1)));
end