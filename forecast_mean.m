function  [ypred, ystd] = forecast_mean(TT,steps_ahead,params)

TT = estimate_disposal(TT);

[Mmean,Mstd,Mn] = mean_weekly_profile(TT.Time,TT.dp);

%Index of the current time (time of prediction)
indcurr = size(TT,1)-1000;

%Time signal of prediction horizon
tpred=TT.Time(indcurr)+(0:steps_ahead)'*hours(1);

tpred_hour=hour(tpred);
tpred_weekday=weekday(tpred);
ind=sub2ind([7 24], tpred_weekday,tpred_hour+1);
dp = Mmean(ind);
ystd = Mstd(ind);


p=TT.p(indcurr);%pall=[p;zeros(n-1,1)];coll=logical(zeros(n,1));

wr=weekratio(tpred);
for i=2:steps_ahead+1
    p=p+dp(i);
    
    if any(and(wr(i-1)<=params.schedule,params.schedule<wr(i))) 
        p = params.afterpicklevel;
        coll(i)=true;
    end
    
    ypred(i)=p;
    
end

ypred(1)=[];tpred(1)=[];ystd(1)=[];

ypred(ypred>100)=100;

%close all;
figure;
plot(TT.Time,TT.p,'.-');
hold on;
h2 = plot(tpred,ypred,'.-','LineWidth',1,'MarkerSize',20);
%plot(tpred, ypred, 'r.-', tpred, ypred+3*ySD, 'r--', tpred, ypred-3*ySD, 'r--')
xlim([TT.Time(indcurr-1000) max(tpred(end),TT.Time(end))]);
xtickformat('eee dd/MM HH');



end