clear; close all; clc
root_dir = load('root_dir.mat').root_dir;
cd(root_dir);
all_data = dir('Data\s0\*mat');
load('root_dir.mat')
for s = 1:length(all_data)
    s0_data = load(fullfile('Data/s0/',all_data(s).name));
    s0_data = rmfield(s0_data,'raster_mtx');
    s0_data = rmfield(s0_data,'rsp_mtx');
    s0{s}=s0_data;
end
dp_thres = 0.5;
%% ROIS
for s = 1:length(all_data)
    session_name{s} = all_data(s).name(1:end-4);
    switch session_name{s}
        case '250823-FanFan-Anagram'
            ROI{s} = 'MSB';
        case '250824-ZhuangZhuang-Anagram'
            ROI{s} = 'AL & ASB';
        case '250825-JianJian-Anagram'
            ROI{s} = 'AL & ASB';
        case '250828-JianJian-Anagram'
            ROI{s} = 'AL & ASB';
        case '250902-ZhuangZhuang-Anagram'
            ROI{s} = 'MSB';
        case '250910-JianJian-Anagram'
            ROI{s} = 'AL & ASB';
        case '251013-Jianjian-AnagramPlus'
            ROI{s} = 'AL';
        case '251022-JianJian-AnagramPlus'
            ROI{s} = 'AL';
        case '251103-JianJian-AnagramPlus'
            ROI{s} = 'AL & ASB';
        case '251110-ZhuangZhuang-AnagramPlus'
            ROI{s} = 'AL & ASB';
        case '251205-MaoDan-Anagram'
            ROI{s} = 'ML';
        case '251209-MaoDan-Anagram'
            ROI{s} = 'MF & MSB';
        case '251212-MaoDan-Anagram'
            ROI{s} = 'MF & MSB';
        case '251223-Jianjian-AnagramPlus2'
            ROI{s} = 'AL';
        case '251230-JianJian-AnagramPP'
            ROI{s} = 'AL & ASB';
        case '260101-JianJian-AnagramPP'
            ROI{s} = 'AL & ASB';
        case '260105-JianJian-AnagramPP'
            ROI{s} = 'AL & ASB';
        case '260105-ZhuangZhuang-Anagram'
            ROI{s} = 'AL & ASB';
        case '260105-ZhuangZhuang-AnagramPP'
            ROI{s} = 'AL & ASB';
        case '260106-MaoDan-Anagram'
            ROI{s} = 'MF & MSB';
        case '260108-JianJian-AnagramPP'
            ROI{s} = 'AL & ASB';
        case '260116-JianJian-AnagramPP'
            ROI{s} = 'AL & ASB';
        case '260126-FaCai-AnagramPP'
            ROI{s} = 'ASB';
        case '260128-Facai-AnagramPP'
            ROI{s} = 'ASB';
        case '260202-ZhuangZhuangR-Anagram'
            ROI{s} = 'MSB';
        case '260428-FaLaDi-Anagram'
            ROI{s} = 'MF & MSB';
        case '260325-Faladi-Anagram'
            ROI{s} = 'MF & MSB'; 
        otherwise
            keyboard
    end
end
%%
for s = 1:length(all_data)
    session_name = all_data(s).name(8:end-4); dash = find(session_name=='-');
    subj=session_name(1:dash-1);
    if(strcmpi(subj,'FaCai'))
        subject{s}='C';
    elseif(strcmpi(subj,'FaLaDi'))
        subject{s}='L';
    else
        subject{s}=subj(1);
    end
    % note: FLD is L, FaCai is C;
    sessionID(s)=s;

    stim_set{s}=session_name(dash+1:end);
    trials(s) = length(s0{s}.trial_idx);
    avg_trials(s) = trials(s)./max(s0{s}.trial_idx);
    NumUnits(s) = length(s0{s}.bdp);
    BodyUnits(s) = sum(s0{s}.bdp>dp_thres);
    FaceUnits(s) = sum(s0{s}.fdp>dp_thres);

    TrialInfo{s} = sprintf('%d (%.01f)',trials(s),avg_trials(s));
    BodyInfo{s} = sprintf('%d (%.02f)',BodyUnits(s),BodyUnits(s)/NumUnits(s));
    FaceInfo{s} = sprintf('%d (%.02f)',FaceUnits(s),FaceUnits(s)/NumUnits(s));
    switch stim_set{s}
        case 'Anagram'
            stim_set{s} = 'Exp.1';
            imgsize{s} = '612';
        case 'AnagramPlus'
            stim_set{s} = 'Exp.2 (1-5)';
            imgsize{s} = '756';
        case 'AnagramPlus2'
            stim_set{s} = 'Exp.2 (6-10)';
            imgsize{s} = '756';
        case 'AnagramPP'
            stim_set{s} = 'Exp.2 (1-10)';
            imgsize{s} = '1476';
    end
end
T = table(sessionID', subject', ROI',stim_set',imgsize', TrialInfo',NumUnits',BodyInfo',FaceInfo');
T.Properties.VariableNames = {'session','subject','target','experiment','#image','#trials','#reliable units','#body units','#face units'};
writetable(T, 'Fig/SessionSummary.xlsx');

return

varNames={'session','subject','target','experiment','#image','#trials','#reliable units','#body units','#face units'};
fileID = fopen('Fig/SessionSummary.rtf','w','n','UTF-8');
fprintf(fileID,'{\\rtf1\\ansi\\deff0\n');
fprintf(fileID,'{\\fonttbl{\\f0 Times New Roman;}}\n');
fprintf(fileID,'\\fs16\n');
colWidthTwips_Small = [600,600,1200,1200,800,1200,800,1100,1100];
numCols = length(colWidthTwips_Small);
colX = cumsum(colWidthTwips_Small);
fprintf(fileID,'\\trowd\n');
for c = 1:numCols
    fprintf(fileID,'\\clbrdrt\\clbrdrl\\clbrdrb\\clbrdrr\\brdrs\\cellx%d', colX(c));
end
for c = 1:numCols
    fprintf(fileID,'\\intbl\\qc\\b %s\\b0\\cell ', varNames{c});
end
fprintf(fileID,'\\row\n');
for r = 1:height(T)
    fprintf(fileID,'\\trowd\n');
    for c = 1:numCols
        fprintf(fileID,'\\clbrdrt\\clbrdrl\\clbrdrb\\clbrdrr\\brdrs\\cellx%d', colX(c));
    end
    for c = 1:numCols
        fprintf(fileID,'\\intbl\\qc %s\\cell ', string(T{r,c}));
    end
    fprintf(fileID,'\\row\n');
end
fprintf(fileID,'}'); fclose(fileID);