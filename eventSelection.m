function [EEG_H, EEG_M] = eventSelection(EEG, eventCell)
        
    EEG = eeg_checkset( EEG );
    Ind_s2 = strcmp({EEG.event.type}, {'S  2'});
    Ind_s4 = strcmp({EEG.event.type}, {eventCell{1}});    
    Ind_s11 = strcmp({EEG.event.type}, {'S 11'});
    % Attention/Valid Hits
    % S  4
    Att_Hit_idx = find(Ind_s4(1:end-1))+1;
    Att_Hit_idx_R = Att_Hit_idx(Ind_s11(Att_Hit_idx));
    Att_Hit_idx_S = Att_Hit_idx_R-1;
    ToRemoveIdx = sort([Att_Hit_idx_R, Att_Hit_idx_S]);

    %S  8    
    if length(eventCell) > 1
        Ind_s8 = strcmp({EEG.event.type}, {eventCell{2}});
        Att_Hit_idx = find(Ind_s8(1:end-1))+1;
        Att_Hit_idx_R = Att_Hit_idx(Ind_s11(Att_Hit_idx));
        Att_Hit_idx_S = Att_Hit_idx_R-1;
        ToRemoveIdx = sort([ToRemoveIdx, sort([Att_Hit_idx_R, Att_Hit_idx_S])]);
    end

    EEG_H = pop_selectevent( EEG, 'omitevent',ToRemoveIdx,'deleteevents','on');
    EEG_H = pop_rmbase( EEG_H, [EEG_H.xmin*1000  -800]); 

    % S  4
    Att_Miss_idx = find(Ind_s4(1:end-1))+1;
    Att_Miss_idx_R = Att_Miss_idx(Ind_s2(Att_Miss_idx));
    Att_Miss_idx_S = Att_Miss_idx_R-1;
    ToRemoveIdx = sort([Att_Miss_idx_R, Att_Miss_idx_S]);
    %S  8
    if length(eventCell) > 1        
        Att_Miss_idx = find(Ind_s8(1:end-1))+1;
        Att_Miss_idx_R = Att_Miss_idx(Ind_s2(Att_Miss_idx));
        Att_Miss_idx_S = Att_Miss_idx_R-1;
        ToRemoveIdx = sort([ToRemoveIdx, sort([Att_Miss_idx_R, Att_Miss_idx_S])]);
    end

    EEG_M = pop_selectevent( EEG, 'omitevent',ToRemoveIdx,'deleteevents','on');
    EEG_M = pop_rmbase( EEG_M, [EEG_M.xmin*1000  0]); % Not necessary if data are
end