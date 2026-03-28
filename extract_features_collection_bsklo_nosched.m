function [X,xnames]=extract_features_collection_bsklo_nosched(p,Time,schedule,indc)
%  
% %Zjistil jsem, ze mediany jsou asi k nicemu, zkusim pridat opravdu derivace
% X = [diff(p(repmat(indc,1,3)+(-1:1)),[],2)./hours(diff(Time(repmat(indc,1,3)+(-1:1)),[],2)), ...%derivace
%      diff(p(repmat(indc,1,3)+(-1:1)),[],2), ...%abs diference
%      p(repmat(indc,1,2)+(0:1)) ...%aktualni a dalsi hodnota p
%      abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
%      diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
%      hours(diff(Time(repmat(indc,1,2)+(0:1)),[],2))...
% ];
% xnames = {'deriv-1','deriv0','diff-1','diff0','p0','p+1','noon_dist','diff0/p0','diffTime'};

window_hours = 3*24;
X = [diff(p(repmat(indc,1,3)+(-1:1)),[],2)./hours(diff(Time(repmat(indc,1,3)+(-1:1)),[],2)), ...%derivace
     diff(p(repmat(indc,1,3)+(-1:1)),[],2), ...%abs diference
     arrayfun(@(k) median(p(Time >= Time(k)-hours(window_hours) & Time < Time(k))), indc), ...%mean of p over past window window_hours
     arrayfun(@(k) median(p(Time > Time(k) & Time <= Time(k)+hours(window_hours))), indc), ...%mean of p over future window window_hour
     abs(hour(Time(indc))+minute(Time(indc))/60-12) ...%vzdalenost od poledne
     diff(p(repmat(indc,1,2)+(0:1)),[],2)./p(indc) ...%relativni diference
     hours(diff(Time(repmat(indc,1,2)+(0:1)),[],2))...
];
xnames = {'deriv-1','deriv0','diff-1','diff0','medianp0','medianp+1','noon_dist','diff0/p0','diffTime'};
