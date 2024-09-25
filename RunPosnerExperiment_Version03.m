function RunExperiment(Name)
      %Name=('Pilot1_01');
    prompt= {'Subject', 'Subject''s number:', 'age', 'gender'};
    defaults={'Testing','S01', '30', 'M'};
    answer= inputdlg(prompt, 'ChoiceRT', 2, defaults);
    [output, subid, subage, gender] = deal(answer{:}); %all input variables are strings
    Name= strcat(output, subid, gender, subage);
 try
diary myDiaryFile
% Trigger Value 	Function
%         1	    START new block (Before pressing Enter)
%         2	    Post Flash Response Trigger
%         3	    Fixation Cross (Cue = 1; Flash = 0)
%         4	    Cue = 1; Flash = 1
%         5	    Cue = 1; Flash = 2
%         6	    Fixation Cross (Cue = 2; Flash = 0)
%         7	    Cue = 2; Flash = 1
%         8	    Cue = 2; Flash = 2
%         9	    Cue = 1
%         10	Cue = 2
%         11	No Flash Reported
%         12	End of the Block

EEGmode = 1; %%changed by r&s to 0. Make it 1 when you are running with EEG
%-------------------------------------------------------------------------`
%              This code is created by EEG Lab Team in IIT-Kanpr, India    %
%-------------------------------------------------------------------------%
addpath('C:\Program Files\MATLAB\R2022a\bin');  %for mex64 files
if EEGmode == 1  
    ioObj = io64; %edited by rs
    status = io64(ioObj); %edited by rs
    address = hex2dec('3EFC'); %edited by rs
    display(status)
end

OutputFile = [ Name, '.log' ];
if ( strcmp(Name,'test') == 0 )

    %%%%%%  For Single Session Per Participant - added by r&s  %%%%%%%
    summary = fopen(OutputFile,'w');
        fprintf(summary,['Trial\t',...
            'Lumin.\t',...
            'Flash\t',...
            'Cue\t',...
            'Valid\t',...
            'Report\t',...
            'RT\t',...
            'Dur\t',...
            'altDur\t',...
            'Startt\t',...
            'FrRate\t',...
            'EstlVal\t',...
            'SDlVal\t',...
            'EstrVal\t',...
            'SDrVal\t',...
            'EstlInv\t',...
            'SDlInv\t',...
            'EstrInv\t',...
            'SDrInv\n'...            
        ]);
        %%added by r&s
    
    %%%%%%%     For Multiple Sessions Per Participant - commented by r&s    %%%%%%
%     if exist(OutputFile) ~= 2
%         summary = fopen(OutputFile,'w');
%         fprintf(summary,['Trial\t',...
%             'Lumin.\t',...
%             'Flash\t',...
%             'Cue\t',...
%             'Valid\t',...
%             'Report\t',...
%             'RT\t',...
%             'Dur\t',...
%             'altDur\t',...
%             'Startt\t',...
%             'FrRate\t',...
%             'EstlVal\t',...
%             'SDlVal\t',...
%             'EstrVal\t',...
%             'SDrVal\t',...
%             'EstlInv\t',...
%             'SDlInv\t',...
%             'EstrInv\t',...
%             'SDrInv\n',...
%             
%         ]);
%     else
%          summary = fopen(OutputFile,'a');
%     end;
%%%commented by r&s
end;





%-------------------------------------------------------------------------%
%              Open the display and verify performance.                   %
%-------------------------------------------------------------------------%
ListenChar(2);
Screen('Preference', 'SkipSyncTests',1);
Screen('Preference', 'VBLTimestampingMode', -1); 
[window,rect] = Screen( 0,'OpenWindow', [ 0, 0, 0 ] ); % by rs
%[window,rect] = Screen( 'OpenWindow', 1, [ 0, 0, 0 ] ); % rs changed second argument from 0 to 1 - screen number while extending
topPriorityLevel = MaxPriority(window); %rs comment
Priority(topPriorityLevel); %rs comment
HideCursor;
FrRate = round(FrameRate(window)); 
FrDuration = (Screen( window, 'GetFlipInterval')); %ms
[screenWidth, screenHeight] = Screen('WindowSize', window);

% if screenWidth  ~= 640; clear screen; error('\nScreen width does not match!!!\n');  end; %commented by r&s
% if screenHeight ~= 480; clear screen; error('\nScreen height does not match!!!\n'); end; %commented by r&s
% if FrRate       ~= 160; clear screen; error('\nFrame rate does not match!!!\n');    end; %commented by r&s


% Define colours.
white = WhiteIndex(window);
black = BlackIndex(window);
gray = (white + black)/2;
if round(gray) == white
    gray=black;
end

% Define Keys.
KbName('UnifyKeyNames');
quitkey = KbName('ESCAPE');
responsekey = KbName('space');
ReturnKey = KbName('Return');
  

%-------------------------------------------------------------------------%
% Create a structure containing the flash location and the cue direction  %
%-------------------------------------------------------------------------%
cue = [1 2];
validity = [1 1 1 1 -1 -1 -1 -1 0];
TrialsPerCueBlock = length(validity);
trialnum = 0;
nBlocks = 100; %rs commented from 100 to 75
Trials = [];


for n = 1:nBlocks    
    cue = Shuffle(cue);
    
    for i = 1:length(cue)
        validity = Shuffle(validity);
        
        for j = 1:TrialsPerCueBlock
            trialnum = trialnum + 1;

            Trials(trialnum).cues = cue(i);

            if ( cue(i) == 1 && validity(j) == 1 );  Trials(trialnum).flash = 1; end; 
            if ( cue(i) == 1 && validity(j) == -1 ); Trials(trialnum).flash = 2; end; 
            if ( cue(i) == 1 && validity(j) == 0 );  Trials(trialnum).flash = 0; end; 
            if ( cue(i) == 2 && validity(j) == 1 );  Trials(trialnum).flash = 2; end; 
            if ( cue(i) == 2 && validity(j) == -1 )  Trials(trialnum).flash = 1; end; 
            if ( cue(i) == 2 && validity(j) == 0 );  Trials(trialnum).flash = 0; end; 

        end
    end
end


%-------------------------------------------------------------------------%
%                   Load or create QUEST file and data.                   %
%-------------------------------------------------------------------------%
StartLuminance = 0.1; % the initial guess  
QUESTMemory = 5; % The Quest estimation is based on only the last x trials of that condition. %rs note: changed it from 50 to 5. It's functionality now is to wait for first 5 trials to start recomputing
QuestFile = [ Name, '_QUEST.mat' ];

%% For Multiple Sessions per participant. Commented by r&s.
%if ( exist( QuestFile ) == 2 )
%    load( QuestFile );   
%else
    
    % ... or initialise a new QUEST structure.
%    FirstGuess  = log10( StartLuminance );
%    GuessStd = 3; % a priori standard deviation of the guess. manual suggests to be generous here
%    pThreshold = 0.50; % threshold criterior for response = 1
%    beta  = 3;    %slope of psychometric function
%    delta = 0.01; % p of response = 0 for visible stimuli
%    gamma = 0;    %chance level (for invisible stimuli)
%    grain = 0.005;
%    for c = 1:4        
        % This creates four staircases:
        % QUEST(1): left targets,  valid cue
        % QUEST(2): right targets, valid cue
        % QUEST(3): left targets,  invalid cue
        % QUEST(4): right targets, invalid cue
        
        % We are not using descending - ascending staircases anymore! The
        % initial gues is chosen to be above threshold, so that subjects
        % get the chance to see a few flashes in the beginning.

%        QUEST(c).name = Name;
%        QUEST(c).NTrials = 0;

%        QUEST(c).FirstGuess = FirstGuess;
%        QUEST(c).GuessStd = GuessStd;
%        QUEST(c).pThreshold = pThreshold;
%        QUEST(c).beta = beta;
%        QUEST(c).delta = delta;
%        QUEST(c).gamma = gamma;
%        QUEST(c).grain = grain;   
        
%        QUEST(c).qData = QuestCreate( FirstGuess, GuessStd, pThreshold, beta, delta, gamma, grain );      
%        QUEST(c).qData.normalizePdf = 1;         
%        QUEST(c).qData.allresponses = []; 
%        QUEST(c).qData.allintensities = []; 
%        QUEST(c).qData.allluminances = [];
%        QUEST(c).qData.allestimates = [0]; 
%        QUEST(c).qData.allSD = [0]; 

%        QUEST(c).qData = QuestRecompute( QUEST(c).qData );  
%    end
%end; 
%%%%commented by r&s

%% For Single Session per participant.. Added by r&s.
% ... or initialise a new QUEST structure.
FirstGuess  = log10( StartLuminance );
GuessStd = 3; % a priori standard deviation of the guess. manual suggests to be generous here
pThreshold = 0.50; % threshold criterior for response = 1
beta  = 3;    %slope of psychometric function
delta = 0.01; % p of response = 0 for visible stimuli
gamma = 0;    %chance level (for invisible stimuli)
grain = 0.005; 

for c = 1:4        
    % This creates four staircases:
    % QUEST(1): left targets,  valid cue
    % QUEST(2): right targets, valid cue
    % QUEST(3): left targets,  invalid cue
    % QUEST(4): right targets, invalid cue

    % We are not using descending - ascending staircases anymore! The
    % initial gues is chosen to be above threshold, so that subjects
    % get the chance to see a few flashes in the beginning.

    QUEST(c).name = Name;
    QUEST(c).NTrials = 0;

    QUEST(c).FirstGuess = FirstGuess;
    QUEST(c).GuessStd = GuessStd;
    QUEST(c).pThreshold = pThreshold;
    QUEST(c).beta = beta;
    QUEST(c).delta = delta;
    QUEST(c).gamma = gamma;
    QUEST(c).grain = grain;   
    %QUEST(c).grain = grain;

    QUEST(c).qData = QuestCreate( FirstGuess, GuessStd, pThreshold, beta, delta, gamma, grain );      
    QUEST(c).qData.normalizePdf = 1;         
    QUEST(c).qData.allresponses = []; 
    QUEST(c).qData.allintensities = []; 
    QUEST(c).qData.allluminances = [];
    QUEST(c).qData.allestimates = [0]; 
    QUEST(c).qData.allSD = [0]; 

    QUEST(c).qData = QuestRecompute( QUEST(c).qData );  
    
    
end
%%%% added by r&s
%%
%-------------------------------------------------------------------------%
%                           Define the layout                             %
%-------------------------------------------------------------------------%
DisplayLuminance = 0.1; % rs changed from 0.02 to 0.1 because it was not visible
[screenWidth, screenHeight] = Screen('WindowSize', window);
centerx = screenWidth/2;
centery = screenHeight/2;
ecc =7;
[PixelsPerDegree, DegreesPerPixel] = VisAng2( [screenWidth, screenHeight], [ 36, 27 ], 46);
PixelsPerDegree = mean(PixelsPerDegree);
LeftEccentricity  = centerx - ecc * PixelsPerDegree; % corresponds to Latour's parameters
RightEccentricity = centerx + ecc * PixelsPerDegree; % corresponds to Latour's parameters
cross_arm_length = 10;
cross_gap = 25;
cross_color = [35 35 35];
line_width = 1;

cross_vertical_up      = [(centery + (cross_arm_length+cross_gap)), (centery + cross_gap)];
cross_vertical_down    = [(centery - (cross_arm_length+cross_gap)), (centery - cross_gap)];

left_target_coords = [...
        LeftEccentricity-3.5 * PixelsPerDegree/60 ...
        centery-3.5 * PixelsPerDegree/60 ...
        LeftEccentricity+3.5 * PixelsPerDegree/60 ...
        centery+3.5 * PixelsPerDegree/60
];
right_target_coords = [...
        RightEccentricity-3.5 * PixelsPerDegree/60 ...
        centery-3.5 * PixelsPerDegree/60 ...
        RightEccentricity+3.5 * PixelsPerDegree/60 ...
        centery+3.5 * PixelsPerDegree/60
];

%-------------------------------------------------------------------------%
%                           Define the screens                            %
%-------------------------------------------------------------------------%
%% Define an empty screen (including the target cross)
EmptyScreen = Screen( 'OpenOffscreenWindow', window, black );
Screen( 'DrawLine', EmptyScreen, cross_color, LeftEccentricity, cross_vertical_up(1),    LeftEccentricity, cross_vertical_up(2),    line_width);
Screen( 'DrawLine', EmptyScreen, cross_color, LeftEccentricity, cross_vertical_down(1),  LeftEccentricity, cross_vertical_down(2),  line_width);
Screen( 'DrawLine', EmptyScreen, cross_color, RightEccentricity, cross_vertical_up(1),   RightEccentricity, cross_vertical_up(2),   line_width);
Screen( 'DrawLine', EmptyScreen, cross_color, RightEccentricity, cross_vertical_down(1), RightEccentricity, cross_vertical_down(2), line_width);

%% Define the empty screen with fixation cross
FixCross = Screen( 'OpenOffscreenWindow', window, black );
Screen('CopyWindow', EmptyScreen, FixCross);
Screen( 'TextSize', FixCross, 7 );  
FixString = '+';
bbox = Screen('TextBounds', window, FixString);
bbox = CenterRect(bbox, Screen('Rect', window));
[x,y] = RectCenter(bbox);
%display([x, y])
Screen( 'DrawText', FixCross, FixString, centerx, (y-8), [25, 25, 25] );

%% Define the question screen
QuestionScreen = Screen( 'OpenOffscreenWindow', window, black );
Screen('CopyWindow', EmptyScreen, QuestionScreen);
Screen( 'TextSize', QuestionScreen, 9 ); 
QuestionString = '?';
bbox = Screen('TextBounds', window, QuestionString);
bbox = CenterRect(bbox, Screen('Rect', window));
y = bbox(RectTop);
Screen( 'DrawText', QuestionScreen, QuestionString, centerx, y, [50, 50, 50] );

%% Define a left cue
LeftCueScreen = Screen( 'OpenOffscreenWindow', window, black );
Screen('CopyWindow', FixCross, LeftCueScreen);
Screen( 'TextSize', LeftCueScreen, 9); 
leftcuebmp = imread('ArrowLeft.bmp');
leftcuebmp = leftcuebmp .* DisplayLuminance;
leftcuebmp = imresize(leftcuebmp,.08);
leftcuetex = Screen('MakeTexture', window, leftcuebmp);
Screen('DrawTexture', LeftCueScreen, leftcuetex, [], []);

%% Define a right cue
RightCueScreen = Screen( 'OpenOffscreenWindow', window, black );
Screen('CopyWindow', FixCross, RightCueScreen);
rightcuebmp = imread('ArrowRight.bmp');
rightcuebmp = rightcuebmp .* DisplayLuminance;
rightcuebmp = imresize(rightcuebmp,.08);
rightcuetex = Screen('MakeTexture', window, rightcuebmp);
Screen('DrawTexture', RightCueScreen, rightcuetex, [], []);

%% Define a left flash
LeftFlashScreen = Screen( 'OpenOffscreenWindow', window, black );
Screen('CopyWindow', FixCross, LeftFlashScreen);
Screen( LeftFlashScreen, 'FillOval', ( black + ( white - black ) * DisplayLuminance ), left_target_coords );

%% Define a right flash
RightFlashScreen = Screen( 'OpenOffscreenWindow', window, black );
Screen('CopyWindow', FixCross, RightFlashScreen);
Screen( RightFlashScreen, 'FillOval', ( black + ( white - black ) * DisplayLuminance ), right_target_coords );



%-------------------------------------------------------------------------%
%                          EXPERIMENT STARTS HERE                         %
%-------------------------------------------------------------------------%
trialnum = 0;

% loop over blocks

for b = 1:nBlocks 
     ShowCue2;       
    % Loop over trials
    
    for t = 1:TrialsPerCueBlock
        trialnum = trialnum + 1;
       
        % If a flash will be presented, adjust the luminance according to
        % Quest. If not, set the luminance to 0.
        if (Trials(trialnum).flash == 0);
            thisvalid = 0;
            thisquest = 0;
            Luminance = 0;      
        else

            if  (Trials(trialnum).cues == 1 && Trials(trialnum).flash == 1 )
                thisquest = 1;
                thisvalid = 1;
            elseif (Trials(trialnum).cues == 2 && Trials(trialnum).flash == 2 )
                thisvalid = 1;
                thisquest = 2;
            elseif (Trials(trialnum).cues == 2 && Trials(trialnum).flash == 1 )
                thisvalid = 2;
                thisquest = 3;
            elseif (Trials(trialnum).cues == 1 && Trials(trialnum).flash == 2 )
                thisvalid = 2;
                thisquest = 4;            
            end;

            QUEST(thisquest).NTrials = QUEST(thisquest).NTrials + 1;
            
            LogLuminance = QuestQuantile( QUEST(thisquest).qData );
            Luminance = 10^LogLuminance;  
            if Luminance > 1
                Luminance = 1;
            end
        end;

        
        % Present the flash(es) and get response.
        
        ReportedFlashes = 0;
        RT = 0.000;
        Duration = 0;
        altDuration = 0;
        PreFlashInterval = 0;

        ShowFlash2;

        if (ReportedFlashes == 99);
            break;  %note r&s: might have to replace break with return since matlab recent versions don't allow break inside if statement
        end;


     %update QUEST only for trials with a flash
        
        if ( thisquest ~= 0 )

            QUEST(thisquest).qData = QuestUpdate( QUEST(thisquest).qData, LogLuminance, ReportedFlashes ); %note by r&s : the logluminance gets updated to intensity and reportedflashes to response in qdata. The intensity array length becomes 10000 (or more) again.
            QUEST(thisquest).qData.allresponses(trialnum)   = ReportedFlashes;
            QUEST(thisquest).qData.allintensities(trialnum) = LogLuminance;
            QUEST(thisquest).qData.allluminances(trialnum)  = Luminance;
            
            %if (length(QUEST(thisquest).qData.intensity) > QUESTMemory)          
            if (QUEST(thisquest).qData.trialCount > QUESTMemory)                
                QUEST(thisquest).qData.intensity = QUEST(thisquest).qData.intensity(1:QUEST(thisquest).qData.trialCount);
                QUEST(thisquest).qData.response  = QUEST(thisquest).qData.response(1:QUEST(thisquest).qData.trialCount);

                QUEST(thisquest).qData           = QuestRecompute(QUEST(thisquest).qData);
            end

            QUEST(thisquest).qData.allestimates(end+1)    = 10^( QuestMean(QUEST(thisquest).qData ));
            QUEST(thisquest).qData.allSD(end+1)           = QuestSd( QUEST(thisquest).qData );
            save(QuestFile, 'QUEST');            

        end;
        
        % Finally, update the logfile.       
        fprintf(summary,'%d\t%.3f\t%d\t%d\t%d\t%d\t%.2f\t%.0f\t%.0f\t%.3f\t%.0f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\n', ... % added by r&s : four arguemnts were missing
        trialnum,...
        Luminance,...
        Trials(trialnum).flash,...
        Trials(trialnum).cues,...
        thisvalid,...
        ReportedFlashes,...
        RT,...
        Duration,...
        altDuration,...
        PreFlashInterval,...
        FrRate,...
        QUEST(1).qData.allestimates(end),...
        QUEST(1).qData.allSD(end), ...
        QUEST(2).qData.allestimates(end),...
        QUEST(2).qData.allSD(end),... 
        QUEST(3).qData.allestimates(end),...
        QUEST(3).qData.allSD(end),...
        QUEST(4).qData.allestimates(end),...
        QUEST(4).qData.allSD(end))    
        
    end 
        
           % Send a trigger to STOP the recording.    
    WaitSecs(1.000) % changed by r&s from waitsecs() to the correct format WaitSecs()
    
    if EEGmode == 1
        io64(ioObj, address, 12) %edited by rs
        %outlpt1(77);
        WaitSecs(0.020);  % changed by r&s from waitsecs() to the correct format WaitSecs()
        io64(ioObj, address, 0) %edited by rs
        %outlpt1(0);
    end

%     toc
end


ShowCursor;
Screen('CloseAll');
if ( strcmp(Name,'test') == 0 )
    fclose(summary);
end;    
ListenChar(0);

%added by r&s to convert the .log into .csv 
data = readtable('test33.log','FileType','text');
%data.Properties.VariableNames(1:15) = {'Trial',	'Lumin.', 'Flash',	'Cue',	'Valid', 'Report', 'RT', 'Dur', 'altDur', 'Startt', 'FrRate', 'EstlVal', 'SDlVal', 'EstrVal', 'SDrVal'};
data.Properties.VariableNames(1:19) = {'Trial',	'Lumin.', 'Flash',	'Cue',	'Valid', 'Report', 'RT', 'Dur', 'altDur', 'Startt', 'FrRate', 'EstlVal', 'SDlVal', 'EstrVal', 'SDrVal', 'EstlInv', 'SDlInv', 'EstrInv', 'SDrInv'};
Out_data = [ Name, '.csv' ];
writetable(data, Out_data);
diary off
%added by r&s

% readlog(Name);
Priority(0);
catch
    'ERROR'
    Priority(0);
    Screen('CloseAll');
    fclose('all');
    ShowCursor;
    a=psychlasterror;
    a.message
    ListenChar(0);
end 
