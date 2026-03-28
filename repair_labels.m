function [labeltimes,ynew,yold] = repair_labels(labeltimes,Time,p)
yold = ismember(Time,labeltimes);
ynew=yold;
flag = 1;
while flag == 1
    
    disp('Repair iteration');
    flag = 0;
    for i = find(ynew)'
        if seconds(Time(i+1)-Time(i))<3000
            if p(i+1)==p(i)
                flag = 1;
                ynew(i+1) = 1;
                ynew(i) = 0;
            end
        end
    
    end
end
labeltimes = Time(ynew)';
