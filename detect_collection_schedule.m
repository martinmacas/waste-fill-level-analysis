function [c,cpresc, numcollections, schedule, afterpicklevel] = detect_collection_schedule(Time,p)

if ~issorted(Time,'ascend')
    error('The time must be sorted in order to use detect_collections.m!');
end

[c, afterpicklevel] = detect_collections_thresholding(Time,p);


wr = weekratio(Time);
[hy,hx]=hist(wr(c),0:(1/24/7):1); %Compute histogram of collection weekratios
[~,loc,~,prom]=findpeaks(movavg(hy','linear',9)); %Find peaks on that histogram
ind = prom/max(prom)>0.4; %Choose most prominent peaks 
numcollections = sum(ind);%Number of scheduled collections per week
loc = loc(ind);
%loc = loc - min(loc-1,1);%Moving average shifts the peaks so I shift them slightly back using this

schedule = hx(loc);
edges = [1; find(diff(wr)<0)+1; length(wr)];%Indices of end of week
cpresc = zeros(size(c));
for i=1:length(edges)-1
    indweek = edges(i):edges(i+1)-1;
    [~,b] = min(abs(wr(indweek)-schedule),[],1);
    cpresc(indweek(b)) = 1;
end
cpresc = logical(cpresc);

%Fill level after each collection
afterpicklevel =(p(circshift(c,1)));

end