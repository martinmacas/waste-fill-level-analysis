function  ypred = anomaly_detection_nsigma(Time, p, numstd)


unique_dates=unique(Time);
unique_days=weekday(unique_dates);

Time_hour=hour(Time);
Time_weekday=weekday(Time);
Mn=zeros(7,24);
Mmean=zeros(7,24);
Mstd=zeros(7,24);
Mp={};
wd=1:7;h=0:23;
for i = 1 : 7
    for j = 1:24
        isfit=and(Time_hour==h(j),Time_weekday==wd(i));
        Mn(i,j) = sum(isfit);
        Mmean(i,j) = mean(p(isfit));
        Mstd(i,j) = std(p(isfit));
    end
end

ind=sub2ind([7 24], Time_weekday,Time_hour+1);
ypred=int8(abs(p-Mmean(ind))>numstd*Mstd(ind));


end