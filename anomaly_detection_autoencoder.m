function  [ypred,error, reconstruction] = anomaly_autoencoder(Time, p)

%Resampling to hourly time series
TT=retime(timetable(Time,p),'hourly','linear');
TT=addvars(TT,TT.p,'NewVariableNames','pr');
Time_weekday=weekday(TT.Time);
inds=find([0;diff(Time_weekday)~=0]);

for wdanalysed = 1:7
    X=[];
    for i = 1:length(inds)-1
        if Time_weekday(inds(i))==wdanalysed
            X=[X TT.p(inds(i):inds(i+1)-1)];
            
        end
    end

    hiddenSize = 5;
    autoenc = trainAutoencoder(X,hiddenSize,...
            'EncoderTransferFunction','satlin',...
            'DecoderTransferFunction','purelin',...
            'L2WeightRegularization',0.01,...
            'SparsityRegularization',4,...
            'SparsityProportion',0.10);
    
    Xr = predict(autoenc,X);
    icol=0;
    for i = 1:length(inds)-1
        if Time_weekday(inds(i))==wdanalysed
            icol = icol+1;
            TT.pr(inds(i):inds(i+1)-1) = Xr(:,icol);
                       
        end
    end

end


reconstruction = retime(TT,Time,'linear');
reconstruction = reconstruction.pr;
error = abs(reconstruction-p);
ypred = int8(error>40);