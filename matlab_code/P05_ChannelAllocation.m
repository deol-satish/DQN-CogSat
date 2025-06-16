%% Define which is RFI based on channel allocation
fprintf('Channel allocation...\n');
% Define number of channels based of number of LEO and GEO users + 5 extra
% Each GEO users will always have its own channel
% LEO users will always share all channel randemoly assigned with unique channels per timestep
numChannels = 15;
channelPool = 1:numChannels;
% numChannels = 5 + NumLeoUser + NumGeoUser;
ChannelListLeo = nan(NumGS, leoNum, length(ts));
ChannelListGeo = nan(NumGS, geoNum, length(ts));
LEOUsers = find(GSLEOFilter);  % e.g., 1:10
GEOUsers = find(GSGEOFilter);  % e.g., 11:20
% Only Assign Channels to Valid Users (LEO or GEO)

rng(42);
GEOFreq_rand = randperm(NumGeoUser, NumGeoUser)';

for t = 1:length(ts)
    for s = 1:leoNum
        % ChannelListLeo(LEOUsers, s, t) = randperm(numChannels, NumLeoUser);
        ChannelListLeo(LEOUsers, s, t) = randsample(channelPool,length(LEOUsers),true);
    end
    for g = 1:geoNum
        ChannelListGeo(GEOUsers, g, t) = GEOFreq_rand;
    end
end

OriginalChannelListLeo = ChannelListLeo;  % Save original for later
OriginalChannelListGeo = ChannelListGeo;  % Save original for later

T = length(ts);
LEO_LOC = NaN(NumGS, T, 2);  % [NumGS x T]

%% Finding the serving LEO for each LEO GS (20 x 31)
fprintf('Finding the serving LEO for each LEO GS...\n');
ActualPrxLEO = PrxLEO .*GSLEOFilter;
[PservLEO, Serv_idxLEO] = max(ActualPrxLEO, [], 2);  % Max over LEO satellites
PservLEO = squeeze(PservLEO);                        % [NumGS × Time]
Serv_idxLEO = GSLEOFilter .* squeeze(Serv_idxLEO);   % [NumGS × Time]
%% Find the serving GEO for each GEO GS (20 x 31)
ActualPrxGEO = PrxGEO .*GSGEOFilter;
[PservGEO, Serv_idxGEO] = max(ActualPrxGEO, [], 2);  % Max over GEOs (dim 2)
PservGEO = squeeze(PservGEO);                        % [NumGS × Time]
Serv_idxGEO =  GSGEOFilter .* squeeze(Serv_idxGEO);  % [NumGS × Time]
%% Find the final channel allocations per users
FreqAlloc = NaN(NumGS, length(ts));  % Initialize
for t = 1:length(ts)
    for u = 1:NumGS
        if GSLEOFilter(u)
            s_serv = Serv_idxLEO(u, t);



            if s_serv > 0 && ~isnan(s_serv)
                % Get lat/lon from geographic coordinate frame
                [pos, ~] = states(leoSats(s_serv), ts(t), 'CoordinateFrame', 'geographic');
        
                % % Print values
                % fprintf('GS: %d | Time: %s | LEO-%02d | Latitude: %.4f°, Longitude: %.4f°\n', ...
                %     u,datestr(ts(t), 'yyyy-mm-dd HH:MM:SS'), s_serv, pos(1), pos(2));
                % fprintf('=================================================================\n')

                LEO_LOC(u,t,1) = pos(1);
                LEO_LOC(u,t,2) = pos(2);
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
