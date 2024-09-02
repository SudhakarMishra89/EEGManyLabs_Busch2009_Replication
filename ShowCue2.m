CueDuration   = 0.500; % in secs
CueOnsetDelay = 1.000;


% Present start screen, wait for keypress and wait for another 2 secs

Screen(window,'FillRect', [ 0, 0, 0 ]);
Screen(window,'TextSize',16);
Screen(window,'DrawText',['Press ENTER to start run #', num2str(b)],centerx-190,centery+120, [16, 16, 16] ); %rs changed the value from [6, 6, 6] to [16, 16, 16]
Screen('Flip', window);
KbWait;

continueexp = -1;

while continueexp < 0
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown
        if keyCode(quitkey) == 1
            % ShowCursor;         %added by r&s % Commented by rs
            % fclose(OutputFile); %added by r&s % Commented by rs
            Screen('CloseAll'); %added by r&s % Commented by rs
            continueexp = 99;
        elseif keyCode(ReturnKey) == 1
            continueexp = 1;
            
        end;
	end;
end;

  % Not Needed: commented by rs
 %if (continueexp == 99)
     %return; % Sudhakar Commented
 %end;

% Send a trigger to START the recording.
if EEGmode == 1;
    display('Send a trigger to START the recording')
    io64(ioObj, address, 1)
    status = io64(ioObj); %edited by rs
    display(status)
    %outlpt1(1);
    WaitSecs(0.020);  % changed by r&s from waitsecs() to the correct format WaitSecs()
    io64(ioObj, address, 0)
    %outlpt1(0);
end;

display(0/0)
% Initial empty screen.
Screen('DrawTexture', window, FixCross);
Screen('DrawingFinished', window);
[VBL_start Ons_start] = Screen('Flip', window);


% Show cue.
if Trials(trialnum+1).cues == 1;
    Screen('DrawTexture', window, LeftCueScreen);
elseif Trials(trialnum+1).cues == 2;
    Screen('DrawTexture', window, RightCueScreen);
end;
Screen('DrawingFinished', window);
[VBL_cue Ons_cue] = Screen('Flip', window, ( Ons_start + CueOnsetDelay) );
cuetime = GetSecs;


% Send a trigger.
if EEGmode == 1;
    pulse = 8 + Trials(trialnum+1).cues; %edited by rs
    io64(ioObj, address, pulse); %edited by rs
    io64(ioObj, address, 0) %edited by rs
    %outlpt1(pulse);
    %outlpt1(0);
end;


% Turn off the cue.
Screen('DrawTexture', window, FixCross);
Screen('DrawingFinished', window);
[VBL_cueoff Ons_cueoff] = Screen('Flip', window, ( Ons_cue + CueDuration) );

% wait 0.800 secs
tic
while toc < 0.800
    ;
end;

