%% P04_RxSimulation
%% Gain Calculation
%% Rx Gain
Grx = 10* log10((pi * gsAntenna *fc /c)^2 * eff);
ThermalNoisedBm = 10 * log10(kb * TempK * ChannelBW) +30; % Noise in dBm
%% LEO Tx Gain
%% Define sat gain based on the antenna length - parabolic antenna case
GtxLEO = 10* log10((pi * leo.Antenna *fc /c)^2 * eff);
%% Define sat gain based on the beamwidth - parabolic antenna case
% GtxLEO = leo.GainMax - 12 * (leotheta / leo.psi).^2; 
%% Define a realistic 2D sinc pattern shape antenna
% GtxLEO = leo.GainMax + 10* log10((sinc(leotheta / leo.AntShape)).^2 .* (1 - leo.AntRipDepth * abs(sin(leo.AntRipfreq * leoAzimuth))));
%% Define electronically steered antenna (like OneWeb)  - Cosine-to-the-n power
% leotheta(leotheta > pi/2) = pi/2;  % limit to max 90° in radians
% leotheta(leotheta < 0) = 0;        % limit to min 0°
% AzRipple = 1 - 0.5 * leo.AntRipDepth * sin(2 * leoAzimuth).^2;
% AzRipple(AzRipple < 0.01) = 0.01;  % Clamp to avoid log10(negative)
% GtxLEO = leo.GainMax + 10* log10(cos(leotheta).^leo.AntRipfreq .* AzRipple);
% GtxLEO(GtxLEO < (GainMax - 40)) = GainMax - 40; % Optional clipping (e.g., floor at -20 dB below peak)
% plot(squeeze(GtxLEO(1,1,:)))
%% 2D Sinc^2 Antenna Gain Pattern => Beamwidth control
% % leo.AntShape = 0.573 * leo.psi + 0.1;  % leo.psi in radians
% GtxLEO = leo.GainMax + 10 * log10(( abs(sinc(leo.AntShape*leotheta / leo.psi)).^2 ) ...
%            .* ( abs(  sinc(leo.AntShape*leoAzimuth / leo.psi)).^2 ));
%% GEO Tx Gain
GtxGEO = 10* log10((pi * geoAntenna *fc /c)^2 * eff);
%% LEO Power calculations
RhoLEO(ElLEO<0) = Inf;
PathLoss = 20*log10(fc) + 20*log10(RhoLEO) -147.55;
AtmoLLEO = F01_ComputeAtmosphericLoss(fc, ElLEO, Att);
FadingLEO = F02_MultipathFadingLoss(FadingModel, ElLEO);
PrxLEO = leoPower + GtxLEO + Grx - PathLoss - AtmoLLEO - FadingLEO;
% PrxLEO = leoPower + GtxLEO + Grx - PathLoss;
% PrxLEO(ElLEO < 0) = NaN;
SNRLEO = PrxLEO - ThermalNoisedBm;
%% GEO Power calculations
RhoGEO(ElGEO<0) = Inf;
PathLoss = 20*log10(fc) + 20*log10(RhoGEO) -147.55;
AtmoLGEO = F01_ComputeAtmosphericLoss(fc, ElGEO , Att);
FadingGEO = F02_MultipathFadingLoss(FadingModel, ElGEO);
PrxGEO = geoPower + GtxGEO + Grx - PathLoss - AtmoLGEO - FadingGEO;
% PrxGEO(ElGEO < 0) = NaN;
% PrxGEO = geoPower + GtxGEO + Grx - PathLoss;
SNRGEO = PrxGEO - ThermalNoisedBm;
