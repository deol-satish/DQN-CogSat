
function overlapFactor = getOverlapFactor(txFreq, txBW, intfFreq, intfBW)
    txRange = [txFreq - txBW/2, txFreq + txBW/2];
    intfRange = [intfFreq - intfBW/2, intfFreq + intfBW/2];
    overlap = max(0, min(txRange(2), intfRange(2)) - max(txRange(1), intfRange(1)));
    overlapFactor = overlap / intfBW;
end

%% Simulation Loop with Selective Logging
fprintf('Starting main simulation loop...\n');

% Update LEO frequencies (random channel selection)
%currentLEOFreqs = channelFreqs(randi([1 10], 1, leoNum));
%fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));




reward = struct;

leoIndex = leoIndex + 1;

if leoIndex > leoNum
    tIdx = tIdx + 1;
    leoIndex = 1;
end

endIndex = length(ts);

t = ts(tIdx);
fprintf('\nProcessing time step %d/%d: %s\n', tIdx, length(ts), datestr(t));

leoAccess = false;
geoAccess = false;
accessDetails = '';




% First check if any LEO has access to any ground station
for i = 1:leoNum
    for gsIdx = 1:numel(gsList)
        if accessStatus(access(leoSats{i}, gsList{gsIdx}), t)
            leoAccess = true;
            accessDetails = sprintf('LEO-%d to %s', i, gsList{gsIdx}.Name);
            fprintf('  Access detected: %s\n', accessDetails);
            break;
        end
    end
    if leoAccess, break; end
end


% Check if any GEO has access to any ground station
for i = 1:geoNum
    for gsIdx = 1:numel(gsList)
        if accessStatus(access(geoSats{i}, gsList{gsIdx}), t)
            geoAccess = true;
            fprintf('  Found GEO access at %s (GEO-%d to %s)\n', datestr(t), i, gsList{gsIdx}.Name);
            break;
        end
    end
    if geoAccess, break; end
end

% Only process if at least one LEO has access (GEOs can be added later)
if leoAccess | geoAccess
    sampleCount = sampleCount + 1;
    logData.Time(sampleCount) = t;
    fprintf('  Processing sample %d (valid sample %d)\n', tIdx, sampleCount);
    




    fprintf(' Sending inital state to py function ...\n');


    % Initialize a struct to store the LEO satellite data
    snd_state = struct;

    % Add base frequency or frequency of GEO to the state
    snd_state.GeobaseFreq = baseFreq;
    snd_state.time = datestr(t)

    for i = 1:leoNum
        % Get position in geographic coordinates (Latitude, Longitude)
        [pos, ~] = states(leoSats{i}, t, 'CoordinateFrame', 'geographic');
        
        % Initialize a struct to hold the satellite data for this LEO
        satellite_data = struct;
        satellite_data.LEO_Num = i;
        satellite_data.Latitude = pos(1);
        satellite_data.Longitude = pos(2);
        
        % Create a struct for access status
        accessStatusStruct = struct;
        
        % For each ground station, check if the satellite has access
        for gsIdx = 1:numel(gsList)
            gsName = strrep(gsList{gsIdx}.Name, ' ', '_');
            accObj = access(leoSats{i}, gsList{gsIdx});
            accessStatusStruct.(gsName) = accessStatus(accObj, t);
        end
        
        % Add AccessStatus to the satellite data
        satellite_data.AccessStatus = accessStatusStruct;
        
        % Store the satellite data
        fieldName = sprintf("LEO_%d", i);
        snd_state.(fieldName) = satellite_data;
    end

    % Convert MATLAB struct to Python dict
    py_state = py.dict(snd_state);

    display(py_state)

    % Call Python function without checking return value
    try
        if tIdx == 1
            fprintf('reset_env being called \n');
            %py.a2c_dsa.reset_env(py_state);                
        else
            fprintf('get_action being called \n');
            %py.a2c_dsa.get_action(py_state);
            
        end

        
        fprintf('State save attempted (no return value checked)\n');
    catch e
        fprintf('Error calling Python function:\n%s\n', e.message);
    end



    % Update LEO satellite data
    for i = 1:leoNum
        [pos, ~] = states(leoSats{i}, t, 'CoordinateFrame', 'geographic');
        logData.LEO(i).Latitude(sampleCount) = pos(1);
        logData.LEO(i).Longitude(sampleCount) = pos(2);
        logData.LEO(i).Frequency(sampleCount) = currentLEOFreqs(i);
        
        % Update transmitter frequency for this LEO
        tx = leoTx{i};
        tx.Frequency = currentLEOFreqs(i);

        reward_data_leo = struct;
        reward_data_leo_gs = struct;
        reward_data_leo.LEO_Num = i;
        
        % Check access and calculate metrics for each ground station
        for gsIdx = 1:numel(gsList)
            acc = accessStatus(access(leoSats{i}, gsList{gsIdx}), t);
            logData.LEO(i).Access(sampleCount, gsIdx) = acc;
            
            if acc

                % Calculate link metrics
                linkLEO = link(tx, rxReceivers_LEO(gsList{gsIdx}.Name));
                [~, Pwr_dBW] = sigstrength(linkLEO, t);


                % Calculate elevation angle
                [~, elevationAngle, ~] = aer(rxReceivers_LEO(gsList{gsIdx}.Name), leoSats{i}, t);

                % Use ITU-R P.618 atmospheric propagation loss model
                cfg = p618Config;
                cfg.Frequency = max(baseFreq, 4e9); %ITU P.618 model is not officially validated for frequencies below 4 GHz.
                cfg.ElevationAngle = max(elevationAngle, 5);
                cfg.Latitude = gsList{gsIdx}.Latitude;
                cfg.Longitude = gsList{gsIdx}.Longitude;
                cfg.TotalAnnualExceedance = 0.001; % Typical exceedance

                [pl, ~, ~] = p618PropagationLosses(cfg);
                atmosLoss = pl.At; % Atmospheric attenuation (dB)

                rssi = Pwr_dBW - atmosLoss;
                snr = rssi - 10*log10(kb*tempK*channelBW);
                
                logData.LEO(i).RSSI(sampleCount, gsIdx) = rssi;
                logData.LEO(i).SNR(sampleCount, gsIdx) = snr;

                

                


                fieldName = sprintf("LEO_%d", i);
                gsName = strrep(gsList{gsIdx}.Name, ' ', '_');
                reward_temp = struct;
                reward_temp.rssi = Pwr_dBW - atmosLoss;
                reward_temp.snr = rssi - 10*log10(kb*tempK*channelBW);
                reward_data_leo_gs.(gsName) = reward_temp;
                
                fprintf('    LEO-%d to %s (%.6f GHz): RSSI=%.2f dBm, SNR=%.2f dB\n', ...
                    i, gsList{gsIdx}.Name, currentLEOFreqs(i)/1e9, rssi, snr);
            end
        end
        reward_data_leo.reward = reward_data_leo_gs;
        % *** CORRECTED LINE: Assign the LEO reward data to the main reward struct ***
        fieldName = sprintf("LEO_%d", i);
        reward.(fieldName) = reward_data_leo;
    end
    
    % Update GEO satellite data
    for i = 1:geoNum
        [pos, ~] = states(geoSats{i}, t, 'CoordinateFrame', 'geographic');
        logData.GEO(i).Latitude(sampleCount) = pos(1);
        logData.GEO(i).Longitude(sampleCount) = pos(2);

        reward_data_geo = struct;
        reward_data_geo_gs = struct;
        reward_data_geo.GEO_Num = i;
        
        
        % Check access and calculate metrics for each ground station
        for gsIdx = 1:numel(gsList)
            acc = accessStatus(access(geoSats{i}, gsList{gsIdx}), t);
            logData.GEO(i).Access(sampleCount, gsIdx) = acc;
            
            if acc
                % Calculate link metrics
                linkGEO = link(geoTx{i}, rxReceivers_GEO(gsList{gsIdx}.Name));
                [~, Pwr_dBW] = sigstrength(linkGEO, t);

                %signalPwr_dBW = signalPwr_dBW - (rainLoss + cloudLoss);

                % Calculate elevation angle
                [~, elevationAngle, ~] = aer(rxReceivers_GEO(gsList{gsIdx}.Name), geoSats{i}, t);

                % Use ITU-R P.618 atmospheric propagation loss model
                cfg = p618Config;
                cfg.Frequency = max(baseFreq, 4e9);
                cfg.ElevationAngle = elevationAngle;
                cfg.Latitude = gsList{gsIdx}.Latitude;
                cfg.Longitude = gsList{gsIdx}.Longitude;
                cfg.TotalAnnualExceedance = 0.001; % Typical exceedance

                [pl, ~, ~] = p618PropagationLosses(cfg);
                atmosLoss = pl.At; % Atmospheric attenuation (dB)

                % Apply to signal power
                signalPwr_dBW = Pwr_dBW - atmosLoss;

                signalPwr_W = 10^(signalPwr_dBW / 10);
                
                % Thermal noise in W
                noisePwr_W = kb * tempK * channelBW;
                
                % Interference from each LEO
                intfPowerSum_W = 0;
                for j = 1:leoNum
                    txLEO = leoTx{j};
                    intfFreq = txLEO.Frequency;
                    intfBW = channelBW;  % Assume same BW for simplicity
                
                    overlapFactor = getOverlapFactor(baseFreq, channelBW, intfFreq, intfBW);
                    if overlapFactor > 0
                        linkLEO2GS = link(txLEO, rxReceivers_GEO(gsList{gsIdx}.Name));
                        [~, intfPwr_dBW] = sigstrength(linkLEO2GS, t);
                        intfPwr_dBW = intfPwr_dBW - atmosLoss;
                        intfPwr_W = 10^(intfPwr_dBW / 10) * overlapFactor;
                        intfPowerSum_W = intfPowerSum_W + intfPwr_W;
                    end
                end
                
                % Total interference + noise
                totalIntfNoise_W = noisePwr_W + intfPowerSum_W;
                SINR_dB = 10 * log10(signalPwr_W / totalIntfNoise_W);
                
                % Store
                logData.GEO(i).RSSI(sampleCount, gsIdx) = 10 * log10(signalPwr_W);
                logData.GEO(i).SNR(sampleCount, gsIdx) = SINR_dB;

                fieldName = sprintf("GEO_%d", i);
                gsName = strrep(gsList{gsIdx}.Name, ' ', '_');
                reward_temp = struct;
                reward_temp.rssi = 10 * log10(signalPwr_W);
                reward_temp.snr = SINR_dB;
                reward_data_geo_gs.(gsName) = reward_temp;
                
                fprintf('GEO-%d to %s | SINR: %.2f dB | Signal: %.2f dBm | Intf: %.2f dBW\n', ...
                    i, gsList{gsIdx}.Name, SINR_dB, 10*log10(signalPwr_W)+30, 10*log10(intfPowerSum_W));


            end
        end
        reward_data_geo.reward = reward_data_geo_gs;
        % *** CORRECTED LINE: Assign the GEO reward data to the main reward struct ***
        fieldName = sprintf("GEO_%d", i);
        reward.(fieldName) = reward_data_geo;
        
    end
    
else
    fprintf('  No LEO access detected - skipping this time step\n');
end
fprintf('\nMain simulation loop completed. Processed %d valid samples.\n', sampleCount);

display(reward);



if tIdx == endIndex
    done = true;
end




