%% Find the final channel allocations per users
FreqAlloc = NaN(NumGS, length(ts));  % Initialize
for t = 1:length(ts)
    for u = 1:NumGS
        if GSLEOFilter(u)
            s_serv = Serv_idxLEO(u, t);
            if s_serv > 0 && ~isnan(s_serv)
                FreqAlloc(u, t) = ChannelListLeo(u, s_serv, t);
            end
        elseif GSGEOFilter(u)
            s_serv = Serv_idxGEO(u, t);
            if s_serv > 0 && ~isnan(s_serv)
                FreqAlloc(u, t) = ChannelListGeo(u, s_serv, t);
            end
        end
    end
end

P06_Interference

% P07_Plotting