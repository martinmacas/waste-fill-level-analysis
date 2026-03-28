function  [ypred, ymse] = forecast_arx(TT,steps_ahead)

%Exogenous variables
X=dummyvar(categorical(weekday(TT.Time)));
X=[X dummyvar(categorical(hour(TT.Time)))];

%Create iddata for system identification toolbox
data = iddata(TT.p,X,1);
data.TimeUnit='Hours';



%Train the model
T = size(TT,1)-1000;
%T= 10000;
order=24;
idxpre = 1:order;                      
idxest = order+1:(T - steps_ahead);   
idxf = (T - steps_ahead + 1):T;
Mdl = arima(order,0,0);
X = double(TT{:,"csched"});
Mdl = estimate(Mdl,TT.p(idxest),'Y0',TT.p(idxpre),...
    'X',X(idxest,:));
[ypred,ymse] = forecast(Mdl,steps_ahead,TT.p(idxest(end-order:end)),'XF',X(idxf,:));


%[ypred, ~, ~, ySD]  = forecast(mdl, data(1:end-steps_ahead-1000), steps_ahead);
%ypred=ypred.OutputData;
tpred=TT.Time(end-steps_ahead-1000)+(1:steps_ahead)'*hours(1);

figure;
plot(TT.Time,TT.p,'.-');
hold on;
h2 = plot(TT.Time(idxf),ypred,'r.-','LineWidth',2,'MarkerSize',20);
%plot(tpred, ypred, 'r.-', tpred, ypred+3*ySD, 'r--', tpred, ypred-3*ySD, 'r--')
xlim([TT.Time(T-2000) TT.Time(T)]);
xtickformat('eee dd/MM');


%[y,fit,ic] = compare(data,mdl,steps_ahead);

% err_hourly = abs(y.OutputData-data.OutputData);
% 
% err_original = retime(timetable(TT.Time,err_hourly),Time,'linear');
% err_original = err_original.Variables;
% 
% 
% 
% unique_dates=unique(Time);
% unique_days=weekday(unique_dates);
% 
% Time_hour=hour(Time);
% Time_weekday=weekday(Time);
% Mn=zeros(7,24);
% Mmean=zeros(7,24);
% Mstd=zeros(7,24);
% Mp={};
% wd=1:7;h=0:23;
% for i = 1 : 7
%     for j = 1:24
%         isfit=and(Time_hour==h(j),Time_weekday==wd(i));
%         %Mn(i,j) = sum(isfit);
%         Mmean(i,j) = mean(err_original(isfit));
%         Mstd(i,j) = std(err_original(isfit));
%     end
% end
% 
% ind=sub2ind([7 24], Time_weekday,Time_hour+1);
% % ypred=abs(p-Mmean(ind))>numstd*Mstd(ind);
% 
% ypred = int8(err_original > Mmean(ind)+4*Mstd(ind));
% score = err_original;
% 
% forecast = y.OutputData;
% forecast = retime(timetable(TT.Time,forecast),Time,'linear');
% forecast = forecast.Variables;


end