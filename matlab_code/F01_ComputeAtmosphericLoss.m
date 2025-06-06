%% Atmospheric attenuation
function LAtmosp = F01_ComputeAtmosphericLoss(fc, Elev, Att)
% Inputs:
%   fc    - Frequency [Hz]
%   Elev  - Elevation angle(s) [deg]
%   Att   - Struct of atmospheric parameters
% Output: LAtmosp - Total atmospheric loss [dB]
fcGHz = fc/1e9;                    % frequency in GHz
theta = Elev;
theta(theta < 0) = NaN;            % Set all negative elevations (non-visible) to NaN
theta(theta >= 0 & theta < 5) = 5; % Floor everything else to ≥5° as per P.618
thetaRad = deg2rad(theta);         % Convert to radians
%% 1. Gaseous Absorption (Dry + Wet Air) ITU-R P.676
% Specific (dry+wet) attenuation [dB/km] at sea level
GammaO = 0.0058 * ( fcGHz^2 ) / ( fcGHz^2 + 0.0125 );  % oxygen term γ_o [dB/km]
GammaW = 0.0039 * ( fcGHz^2 ) / ( fcGHz^2 + 12.6   );  % water-vapour term γ_w [dB/km]
GammaGas = GammaO + GammaW;                            % total [dB/km]
SlantFactor = Att.H ./ sin(thetaRad);                % Slant-path factor (convert degrees→radians for sin)[km]
LGas = GammaGas .* SlantFactor;                        % Total gaseous loss [dB]
%% 2. Cloud & Fog Attenuation ITU–R P.840
GammaCl = Att.k_l * Att.M;                          % Specific cloud attenuation [dB/km]
SlantCloud = Att.Hcloud ./ sin(thetaRad); % Slant path length through cloud [km]
LCloud = GammaCl .* SlantCloud;             % Total cloud/fog loss [dB]
%% RAIN ATTENUATION [dB] ITU-R P.838
GammaRain = Att.k_r * (Att.R^Att.alpha);                   % Specific rain attenuation[dB/km]
SlantRain = (Att.h_R - Att.h_s) ./ sin(thetaRad); % Geometric slant length through rain (km) 
Rfactor = 1 ./ ( 1 + 0.78 * sqrt(SlantRain .* GammaRain) ...
                   - 0.38 * (1 - exp(-2 .*SlantRain)) ); % Reduction factor (Eq. P.838-10/12)
Deff = SlantRain .* Rfactor;                  % Effective rain path length[km]
LRain = GammaRain .* Deff;                    % Total rain attenuation [dB]
%% Total
LAtmosp = LGas + LCloud + LRain;
end