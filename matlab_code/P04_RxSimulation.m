%% P04_RxSimulation
%% Reciever Gain
Grx = 10* log10((pi * gsAntenna *fc /c)^2 * eff);
ThermalNoisedBm = 10 * log10(kb * TempK * ChannelBW) +30; % Noise in dBm
%% LEO Power calculations
GtxLEO = 10* log10((pi * leoAntenna *fc /c)^2 * eff);
RhoLEO(ElLEO<0) = Inf;
PathLoss = 20*log10(fc) + 20*log10(RhoLEO) -147.55;
AtmoLLEO = F01_ComputeAtmosphericLoss(fc, ElLEO, Att);
FadingLEO = F02_MultipathFadingLoss(FadingModel, ElLEO);
PrxLEO = leoPower + GtxLEO + Grx - PathLoss - AtmoLLEO - FadingLEO;
% PrxLEO = leoPower + GtxLEO + Grx - PathLoss;
SNRLEO = PrxLEO - ThermalNoisedBm;
%% GEO Power calculations
GtxGEO = 10* log10((pi * geoAntenna *fc /c)^2 * eff);
RhoGEO(ElGEO<0) = Inf;
PathLoss = 20*log10(fc) + 20*log10(RhoGEO) -147.55;
AtmoLGEO = F01_ComputeAtmosphericLoss(fc, ElGEO , Att);
FadingGEO = F02_MultipathFadingLoss(FadingModel, ElGEO);
PrxGEO = geoPower + GtxGEO + Grx - PathLoss - AtmoLGEO - FadingGEO;
% PrxGEO = geoPower + GtxGEO + Grx - PathLoss;
SNRGEO = PrxGEO - ThermalNoisedBm;
