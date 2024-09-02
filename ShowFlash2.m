%% Added by r&s
Outfile = [Name, '_DurationReport.log'];
if ( strcmp(Name,'test') == 0 )
    if exist(Outfile) ~= 2
        Dur_summary = fopen(Outfile,'w');
        fprintf(Dur_summary,['PeriFlashInterval\t',...
            'PreFlashInterval\t',...
            'Ons_start\t',...            
            'DesiredFlashOnset\t',...
            'Ons_flash\t',...
            'FlashTime\t',...
            'Ons_flashoff\t',...
            'OffsetTime\t',...
            'Duration\t', 'altDuration\t',...
            'stop\t',...      
        ]);
    else
         Dur_summary = fopen(Outfile,'a'); %% rs -It can be changed to 'a' if already created file is needed to be appended.
    end;
end;
%% Added by r&s


PeriFlashInterval = 0.400 * rand(1);
PreFlashInterval  = 0.400 - PeriFlashInterval;
PostFlashInterval = 1.500;

%FlashDuration = 1;  %commented by r&s line 28 & 29 given these variables don't seem to be used in the further code
%Buffer = (FrDuration/4); 
% Buffer = (FrDuration); 


Priority(MaxPriority(window));


% Initial empty screen.
Screen('DrawTexture', window, FixCross);
Screen('DrawingFinished', window);
[VBL_start Ons_start] = Screen('Flip', window);


% Flash with updated luminance
if Trials(trialnum).flash == 1
    Screen( LeftFlashScreen, 'FillOval',  ( black + ( white - black ) * Luminance ), left_target_coords );
    Screen('DrawTexture', window, LeftFlashScreen);    
elseif Trials(trialnum).flash == 2
    Screen( RightFlashScreen, 'FillOval', ( black + ( white - black ) * Luminance ), right_target_coords );
    Screen('DrawTexture', window, RightFlashScreen);    
elseif Trials(trialnum).flash == 0  
    Screen('DrawTexture', window, FixCross);
end;

DesiredFlashOnset = Ons_start + PreFlashInterval;

Screen('DrawingFinished', window);
[VBL_flash Ons_flash] = Screen('Flip', window, DesiredFlashOnset);
FlashTime = GetSecs;

DesiredFlashOffset = DesiredFlashOnset + FrDuration; %% added by r&s because the teh duration of the flash is changing (probably because of rand(1)) and was not fixed to frame rate duration ~6ms.

% Turn off the flash with an empty screen.
Screen('DrawTexture', window, FixCross);
Screen('DrawingFinished', window);
[VBL_flashoff Ons_flashoff] = Screen('Flip', window, DesiredFlashOffset); %% added by r&s - DesiredFlashOffset argument 
OffsetTime = GetSecs;


if EEGmode == 1;
    pulse = (3*Trials(trialnum).cues) + (Trials(trialnum).flash); %edited by rs
    io64(ioObj, address, pulse); %edited by rs
    %outlpt1(pulse);
    WaitSecs(0.020);  % changed by r&s from waitsecs() to the correct format WaitSecs()
    io64(ioObj, address, 0) %edited by rs
    %outlpt1(0);
end;

% While the empty screen is still on, check if a button is pressed.
stop = OffsetTime + PostFlashInterval;

keyDownFlag = 0;  % Added by Sudhakar
while GetSecs < stop
    [keyIsDown,secs,keyCode] = KbCheck;
    display(['Before If: GetSecs-' num2str(GetSecs) ' and stop-' num2str(stop) 'and KeyDown Status-' num2str(keyIsDown)]) % Added by Sudhakar
    if keyDownFlag == 1 % Added by Sudhakar
        keyIsDown = 0; % Added by Sudhakar
    end
    if keyIsDown
        display(['After If: GetSecs-' num2str(GetSecs) ' and stop-' num2str(stop) 'and KeyDown Status-' num2str(keyIsDown)]) % Added by Sudhakar
        if (keyCode(responsekey) == 1)
            ReportedFlashes = 1;       
            if EEGmode == 1;
                io64(ioObj, address, 2); %edited by rs
                %outlpt1(2);
                WaitSecs(0.020);  % changed by r&s from waitsecs() to the correct format WaitSecs()
                io64(ioObj, address, 0) %edited by rs
                %outlpt1(0);
                keyDownFlag = 1; % Added by Sudhakar
            end;                   
        elseif keyCode(quitkey) == 1
            ReportedFlashes = 99;            
        else
            ReportedFlashes = 0;
        end;
        RT = secs - Ons_flash;        
    end;
end

if (ReportedFlashes == 0 && EEGmode == 1)
    io64(ioObj, address, 11); %edited by rs
    %outlpt1(11);
    WaitSecs(0.020);   % changed by r&s from waitsecs() to the correct format WaitSecs()
    io64(ioObj, address, 0) %edited by rs
    %outlpt1(0);
end;                   


% compute timing
StartTime   = ( Ons_flash - Ons_start ) * 1000;
Duration    = ( Ons_flashoff - Ons_flash ) * 1000;
altDuration = ( OffsetTime - FlashTime ) * 1000;

priorityLevel=0;

%% Added by r&s TO check timing parameters
fprintf(Dur_summary,'%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\t%.5f\n', ...
        PeriFlashInterval, PreFlashInterval,...
        Ons_start,...
        DesiredFlashOnset,...
        Ons_flash,...
        FlashTime,...
        Ons_flashoff,...
        OffsetTime,Duration,altDuration,...
        stop) 
fclose(Dur_summary)               

%data = readtable([Name, '_DurationReport.log'],'FileType','text');
%data.Properties.VariableNames(1:11) = {'PeriFlashInterval',	'PreFlashInterval', 'Ons_start', 'DesiredFlashOnset', 'Ons_flash', 'FlashTime', 'Ons_flashoff', 'OffsetTime', 'Duration', 'altDuration', 'stop'};
%Out_data = [Name, '_DurationReport.csv'];
%writetable(data, Out_data);
%% Added by r&s