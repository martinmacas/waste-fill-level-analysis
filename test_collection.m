function [fn,fp] = test_collection(predtimes, labeltimes)


toler = hours(6);
tp=0;tn=0;fp=0;fn=0;
for k = 1:length(predtimes)
    if min(abs(predtimes(k)-labeltimes))<toler
            tp = tp + 1;
    else
        fp = fp + 1;    
    end
end
for k = 1:length(labeltimes)
    if isempty(predtimes)
        fn = fn + 1;
    elseif min(abs(predtimes-labeltimes(k)))>=toler
        fn = fn + 1;
    end
end
%if fp+fn==0, keyboard;end
%     
%         tpr = tp/length(labeltimes)
%         tnr = 1-fn/(length(Time)-length(labeltimes))
%     