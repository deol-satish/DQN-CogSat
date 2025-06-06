%% Save Data to CSV (only valid samples)
fprintf('\nPreparing data for CSV export...\n');
% Prepare data for CSV export
csvData = table();
csvData.Time = logData.Time;

% Add GEO data
for i = 1:geoNum
    fprintf('  Adding GEO-%d data to CSV structure\n', i);
    csvData.(sprintf('GEO%d_Name', i)) = repmat(logData.GEO(i).Name, validSamples, 1);
    csvData.(sprintf('GEO%d_Lat', i)) = logData.GEO(i).Latitude;
    csvData.(sprintf('GEO%d_Lon', i)) = logData.GEO(i).Longitude;
    csvData.(sprintf('GEO%d_Freq_Hz', i)) = logData.GEO(i).Frequency;
    
    for gsIdx = 1:numel(gsList)
        gsName = strrep(gsList{gsIdx}.Name, ' ', '_');
        csvData.(sprintf('GEO%d_%s_Access', i, gsName)) = logData.GEO(i).Access(:, gsIdx);
        csvData.(sprintf('GEO%d_%s_SNR_dB', i, gsName)) = logData.GEO(i).SNR(:, gsIdx);
        csvData.(sprintf('GEO%d_%s_RSSI_dBm', i, gsName)) = logData.GEO(i).RSSI(:, gsIdx);
    end
end

% Add LEO data
for i = 1:leoNum
    fprintf('  Adding LEO-%d data to CSV structure\n', i);
    csvData.(sprintf('LEO%d_Name', i)) = repmat(logData.LEO(i).Name, validSamples, 1);
    csvData.(sprintf('LEO%d_Lat', i)) = logData.LEO(i).Latitude;
    csvData.(sprintf('LEO%d_Lon', i)) = logData.LEO(i).Longitude;
    csvData.(sprintf('LEO%d_Freq_Hz', i)) = logData.LEO(i).Frequency;
    
    for gsIdx = 1:numel(gsList)
        gsName = strrep(gsList{gsIdx}.Name, ' ', '_');
        csvData.(sprintf('LEO%d_%s_Access', i, gsName)) = logData.LEO(i).Access(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_SNR_dB', i, gsName)) = logData.LEO(i).SNR(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_RSSI_dBm', i, gsName)) = logData.LEO(i).RSSI(:, gsIdx);
    end
end

% Write to CSV
fprintf('Writing data to CSV file...\n');
writetable(csvData, 'Satellite_Australia_Simulation_Log.csv');
fprintf('CSV saved with %d valid samples: Satellite_Australia_Simulation_Log.csv\n', validSamples);


save('mySatelliteScenario.mat', 'sc');

%% Play Simulation
%fprintf('\nStarting visualization...\n');
%v = satelliteScenarioViewer(sc);
%v.ShowDetails = true;
%play(sc, 'PlaybackSpeedMultiplier', 100);
%fprintf('=== Simulation Complete ===\n');

fprintf('=== End of Script ===\n');