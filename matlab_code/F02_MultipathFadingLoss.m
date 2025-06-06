function FadingLossdB = F02_MultipathFadingLoss(FadingModel, Elev)
% Compute multipath fading loss in dB for a given fading model and elevation angle(s)
% Inputs:
%   FadingModel - 'None', 'Rayleigh', or 'Rician'
%   Elev        - Elevation angle(s) in degrees (scalar or array)
% Output: FadingLossdB - Fading loss, NaN where not visible
IsVisible = Elev >= 0;
switch FadingModel
    case 'None'
        FadingLossdB = zeros(size(Elev));
    case 'Rayleigh'
        h = (randn(size(Elev)) + 1j * randn(size(Elev))) / sqrt(2);
        FadingLossdB = -20 * log10(abs(h));
    case 'Rician'
        KdB = 15 * sin(deg2rad(max(Elev, 0)));   % Rician K-factor in dB
        K = 10.^(KdB / 10);
        s = sqrt(K ./ (K + 1));
        sigma = sqrt(1 ./ (2 * (K + 1)));
        h = s + sigma .* (randn(size(Elev)) + 1j * randn(size(Elev))); % complex gain (amplitude and phase distortion)
        FadingLossdB = -20 * log10(abs(h));
        FadingLossdB = max(min(FadingLossdB, 10), -5);  % limit fading to [-5, +10] dB range
    otherwise
        error('Unsupported fading model: %s', FadingModel);
end
% Mask non-visible links
FadingLossdB(~IsVisible) = NaN;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Second Option %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function fading_dB = F01_GetMultipathFadingLoss(model, K_dB, el)
%     if el < 10  % Below 10 degrees, consider scattering dominant
%         model = 'Rayleigh';
%     end
%     switch model
%         case 'None'
%             fading_dB = 0;
%         case 'Rayleigh'
%             h = (randn + 1j*randn)/sqrt(2);
%             fading_dB = -20 * log10(abs(h));
%         case 'Rician'
%             K = 10^(K_dB/10);
%             s = sqrt(K / (K + 1));
%             sigma = sqrt(1 / (2 * (K + 1)));
%             h = s + sigma * (randn + 1j*randn);
%             fading_dB = -20 * log10(abs(h));
%         otherwise
%             error('Invalid fading model');
%     end
% end
