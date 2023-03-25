% Calculate digital beamforming with one TX antenna
clear;
close all;

% (1) Connect to Radarbook2 with ADF24 Frontend
% (2) Enable Supply
% (3) Configure RX
% (4) Configure TX
% (5) Start Measurements
% (6) Configure signal processing
% (7) Calculate DBF algorithm

% Configure script
Disp_FrmNr = 1;
Disp_TimSig = 0;      % display time signals
Disp_RP = 0;      % display range profile
Disp_JOpt = 1;      % display cost function for DBF

c0 = 299792458;
%--------------------------------------------------------------------------
% Include all necessary directories
%--------------------------------------------------------------------------
CurPath = pwd();
addpath([CurPath,'/../../PNet']);
addpath([CurPath,'/../../Class']);

%--------------------------------------------------------------------------
% Setup Connection
%--------------------------------------------------------------------------
Brd = Rbk2Adf24Tx2Rx8('PNet', '192.168.1.1');

% Verify if sampling framework is installed
Brd.BrdChkSocSysId();

% Reset board: resets timing unit in case a measurement has been configured
% previously
Brd.BrdRst();
% Enable RF power supply and wait for supply 
Brd.BrdPwrEna();

% Use 40 MHz clock for the ADC (AFE5801)
Brd.BrdSetRole('Ms', 40e6);

%--------------------------------------------------------------------------
% Load Calibration Data
%--------------------------------------------------------------------------
CalCfg.Mask = 1;
CalCfg.Len = 16;
CalData = Brd.BrdGetCalData(CalCfg);

%--------------------------------------------------------------------------
% Configure RF Transceivers
%--------------------------------------------------------------------------
Brd.RfRxEna();
Brd.RfTxEna(1, 80);

%--------------------------------------------------------------------------
% Configure AFE5801
%--------------------------------------------------------------------------
% Enable/Disable internal DC coupling
Brd.Set('AfeIntDcCoupling',0);
% Set AfeGain in dB (-5 - 30 dB); The closest available value is configured
Brd.Set('AfeGaindB', 20);

%--------------------------------------------------------------------------
% Configure Up-Chirp
%--------------------------------------------------------------------------
Cfg.fStrt = 23.8e9;         
Cfg.fStop = 24.25e9;
Cfg.TRampUp = 256e-6;
Cfg.TRampDo = 64e-6;
Cfg.TInt = 200e-3;
Cfg.N = 1024;
Cfg.IniTim = 100e-3;                  
Cfg.IniEve = 0;                      % Start automatically after IniTim

Brd.RfMeas('ExtTrigUp',Cfg);
%--------------------------------------------------------------------------
% Read actual configuration
%--------------------------------------------------------------------------
NrChn = Brd.Get('NrChn');
N = Brd.Get('N');
fs = Brd.Get('fs');

%--------------------------------------------------------------------------
% Configure Signal Processing
%--------------------------------------------------------------------------
% Processing of range profile
Win2D = Brd.hanning(N-1,NrChn);
ScaWin = sum(Win2D(:,1));
NFFT = 2^12;
kf = (Cfg.fStop - Cfg.fStrt)/Cfg.TRampUp;
vRange = [0:NFFT-1].'./NFFT.*fs.*c0/(2.*kf);

RMin = 1;
RMax = 10;

[Val RMinIdx] = min(abs(vRange - RMin));
[Val RMaxIdx] = min(abs(vRange - RMax));
vRangeExt = vRange(RMinIdx:RMaxIdx);

% Window function for receive channels
NFFTAnt = 256;
WinAnt = Brd.hanning(NrChn);
ScaWinAnt = sum(WinAnt);
WinAnt2D = repmat(WinAnt.',numel(vRangeExt),1);
vAngDeg = asin(2*[-NFFTAnt./2:NFFTAnt./2-1].'./NFFTAnt)./pi*180;

% Calibration data
mCalData = repmat(CalData.',N-1,1);

% Positions for polar plot of cost function
vU = linspace(-1,1,NFFTAnt);
[mRange , mU] = ndgrid(vRangeExt,vU);
mX = mRange.*mU;
mY = mRange.*cos(asin(mU));

FrmNrOld = 0;

%--------------------------------------------------------------------------
% Measure and calculate DBF
%--------------------------------------------------------------------------
for MeasIdx = 1:1000

    Data = Brd.BrdGetData(1);

    if Disp_FrmNr > 0
        % Show Frame number:
        % The board can buffer multiple frames but if the communication
        % speed is too low, or the time between calls of BrdGetData is
        % higher than TInt, then frames will be lost if the FIFOs in the
        % RBK2 overflow.
        % Use the framecounter to check if no data is missing
        FrmNr = mean(Data(1,:));
        disp(num2str(Data(1,:)))
        FrmNrOld = FrmNrOld + 1;
        if FrmNrOld >= 2^15
            FrmNrOld = FrmNrOld - 2^16;
        end
        if FrmNr ~= FrmNrOld
            warning('Data Frame is missing');
        end
        FrmNrOld = FrmNr;
    end     
    
    % Remove Framenumber from processing
    Data = Data(2:end,:);
    
    if Disp_TimSig > 0      
        % Display time signals
        figure(1)
        plot(Data(:,:));
        grid on;
        xlabel('n ( )');
        ylabel('u (LSB)');   
    end    
    
    % Calculate range profile including calibration
    RP = fft(Data.*Win2D.*mCalData,NFFT,1).*Brd.FuSca/ScaWin;
    RPExt = RP(RMinIdx:RMaxIdx,:);    
    
    if Disp_RP> 0 
        %Display range profile
        figure(1)
        plot(vRangeExt, 20.*log10(abs(RPExt)));
        grid on;
        xlabel('R (m)');
        ylabel('X (dBV)');
        axis([vRangeExt(1) vRangeExt(end) -120 -40])
    end
    

    
    if Disp_JOpt > 0
        % calculate fourier transform over receive channels
        JOpt = fftshift(fft(RPExt.*WinAnt2D,NFFTAnt,2)/ScaWinAnt,2);

        % normalize cost function
        JdB = 20.*log10(abs(JOpt));
        JMax = max(JdB(:));
        JNorm = JdB - JMax;
        JNorm(JNorm < -25) = -25;    



        figure(3);
        surf(mX,mY, JNorm); 
        shading flat;
        view(0,90);
        axis equal
        xlabel('x (m)');
        ylabel('y (m)');
        colormap('jet');
    end
    
    
end

Brd.BrdDispInf();
Brd.BrdRst();
Brd.BrdPwrDi();

clear Brd;