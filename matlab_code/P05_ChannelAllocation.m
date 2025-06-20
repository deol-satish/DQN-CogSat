% Random channel allocation
fprintf('Channel allocation...\n');
% Define number of channels based of number of LEO and GEO users + 5 extra
% Each GEO users will always have its own channel
% LEO users will always share all channel randemoly assigned with unique channels per timestep
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

% 
% %% Optimized channel allocation using Greedy Max-SINR with GEO Awareness
% LEOUsers = find(GSLEOFilter);  % e.g., 1:10
% GEOUsers = find(GSGEOFilter);  % e.g., 11:20
% for t = 1:length(ts)
%     geoAssignments = randperm(NumGeoUser);
%     for g = 1:geoNum
%         ChannelListGeo(GEOUsers, g, t) = geoAssignments';
%     end
% end
% % Initialize allocation matrix for LEO [GS x LEO x T]
% ChannelListLeo = nan(NumGS, leoNum, length(ts));
% ThermalNoise = 10^(ThermalNoisedBm / 10);
% for t = 1:length(ts)
%     for s = 1:leoNum
%         for g = 1:NumGS
%             if ~GSLEOFilter(g), continue; end  % Skip non-LEO users
%             bestSINR = -Inf;
%             bestCh = NaN;
%             for ch = 1:numChannels
%                 % Check if this channel is used by any GEO user for this GS at t
%                 isGEOUsed = any(ChannelListGeo(g, :, t) == ch, 'all');
% 
%                 % Interference from other LEOs on same channel at same timestep
%                 interferingLEOs = find(ChannelListLeo(:, s, t) == ch);
%                 interferenceLEO = sum(PrxLEO(g, interferingLEOs, t), 'omitnan');
% 
%                 % Interference from GEOs using same channel
%                 interferenceGEO = 0;
%                 for geo = 1:geoNum
%                     if ChannelListGeo(g, geo, t) == ch
%                         interferenceGEO = interferenceGEO + PrxGEO(g, geo, t);
%                     end
%                 end
% 
%                 totalInterference = ThermalNoise + interferenceLEO + interferenceGEO;
%                 SINR = PrxLEO(g, s, t) / totalInterference;
% 
%                 % % Penalize if using a GEO-reserved channel
%                 % if isGEOUsed
%                 %     SINR = SINR - 1;
%                 % end
% 
%                 % Update best channel if this is better
%                 if SINR > bestSINR
%                     bestSINR = SINR;
%                     bestCh = ch;
%                 elseif SINR == bestSINR && rand < 0.5
%                     bestCh = ch;  % break tie randomly
%                 end
%             end
% 
%             % Assign best channel
%             ChannelListLeo(g, s, t) = bestCh;
%         end
%     end
% end
%% Finding the serving LEO for each LEO GS (20 x ts)
% % Limited by the theta beamwidth and the local horizon ==> very restricted
% fprintf('Finding the serving LEO for each LEO GS...\n');
% thetaThreshold = leo.psi; % beamwidth cutoff threshold (in radians)
% % Create beam mask: satellite covers GS only if off-axis θ is within beam
% beamMask = leotheta <= thetaThreshold;  % [NumGS × LEO × Time]
% % Copy Prx and mask out values outside the beam
% MaskedPrxLEO = PrxLEO;
% MaskedPrxLEO(~beamMask) = -Inf;
% % Apply GS filter — only process LEO-designated ground stations
% GSFilter3D = repmat(GSLEOFilter, 1, size(PrxLEO,2), size(PrxLEO,3));  % Expand to [NumGS × LEO × Time]
% MaskedPrxLEO(~GSFilter3D) = -Inf;
% % Find the max Prx across satellites (dim 2), restricted to valid beams
% [PservLEO, Serv_idxLEO] = max(MaskedPrxLEO, [], 2);
% % Squeeze dimensions to get [NumGS × Time]
% PservLEO = squeeze(PservLEO);
% Serv_idxLEO = squeeze(Serv_idxLEO);
% % % Optional: set Serv_idx to 0 if no satellite covers that GS at time t
% Serv_idxLEO(PservLEO == -Inf) = 0;
%% Finding the serving LEO for each LEO GS (20 x 31)
fprintf('Finding the serving LEO for each LEO GS...\n');
ActualPrxLEO = PrxLEO .*GSLEOFilter;
[PservLEO, Serv_idxLEO] = max(ActualPrxLEO, [], 2);  % Max over LEO satellites
PservLEO = squeeze(PservLEO);                        % [NumGS × Time]
Serv_idxLEO = GSLEOFilter .* squeeze(Serv_idxLEO);   % [NumGS × Time]
%% Find the serving GEO for each GEO GS (20 x ts)
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
