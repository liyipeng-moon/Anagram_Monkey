function [img_pool,combined_pool24,combined_pool12,combined_pool8,cm] = load_stimPP
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPP');
i_set='AnagramPP';

[X, Y] = meshgrid(1:300, 1:300); R = sqrt((X - 150).^2 + (Y - 150).^2); ringMask = uint8(255*(R>=149));
for c = 1:3
    maskcircle(:,:,c) = ringMask;
end

stim_dir = fullfile(load('root_dir.mat').root_dir,'Data\stim');
tsv_data = readtable(sprintf('%s.tsv',i_set),'FileType','text','Delimiter','tab');
img_num = size(tsv_data,1);
img_pool = uint8(zeros([img_num,300,300,3]));
for i = 1:img_num
    img_pool(i,:,:,:) = imresize(imread(fullfile(i_set,tsv_data.FileName{i})),[300,300]) + maskcircle;
end
cm = colorcet('C6'); cm = floor(255*cm(1:11:256,:));
for stims_family = 1:10
    stim144=f_compare{stims_family};
    for case_idx = 1:3
        ss{stims_family,case_idx} = stim144([1:24]+48*(case_idx-1));
        img = [];
        for s = 1:24
            img_in = squeeze(img_pool(ss{stims_family,case_idx}(s),:,:,:));
            img_in = add_edge(img_in, cm(s,:),20);
            img = [img, img_in];
            k{s} = img_in;
        end
        combined_pool24{stims_family,case_idx}=img;
        combined_pool8{stims_family,case_idx}= [k{1},k{4},k{7},k{10},k{13},k{16},k{19},k{22}];
        combined_pool12{stims_family,case_idx}= [k{1},k{3},k{5},k{7},k{9},k{11},k{13},k{15},k{17},k{19},k{21},k{23}];
    end
end
cm=cm/255;
end