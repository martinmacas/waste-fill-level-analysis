function  [ypred, score, forecast] = anomaly_detection_arx(Time, p, c,steps_ahead)

%Resampling to hourly time series
TT=retime(timetable(Time,p),'hourly','linear');

%Exogenous variables
X=dummyvar(categorical(weekday(TT.Time)));
X=[X dummyvar(categorical(hour(TT.Time)))];

%Create iddata for system identification toolbox
data = iddata(TT.p,X,3600);


%Train the model
mdl = arx(data,[3 ones(1,31) zeros(1,31)]);

[y,fit,ic] = compare(data,mdl,steps_ahead);

err_hourly = abs(y.OutputData-data.OutputData);

err_original = retime(timetable(TT.Time,err_hourly),Time,'linear');
err_original = err_original.Variables;



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
        %Mn(i,j) = sum(isfit);
        Mmean(i,j) = mean(err_original(isfit));
        Mstd(i,j) = std(err_original(isfit));
    end
end

ind=sub2ind([7 24], Time_weekday,Time_hour+1);
% ypred=abs(p-Mmean(ind))>numstd*Mstd(ind);

ypred = int8(err_original > Mmean(ind)+4*Mstd(ind));
score = err_original;

forecast = y.OutputData;
forecast = retime(timetable(TT.Time,forecast),Time,'linear');
forecast = forecast.Variables;


end