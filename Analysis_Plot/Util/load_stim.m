function [img_pool,ss,combined_pool24,combined_pool12,combined_pool38,cm] = load_stim(i_set)
[X, Y] = meshgrid(1:300, 1:300); R = sqrt((X - 150).^2 + (Y - 150).^2); ringMask = uint8(255*(R>=149));
for c = 1:3
    maskcircle(:,:,c) = ringMask;
end
stim_dir = 'G:\Anagram\Data\stim';
tsv_data = readtable(sprintf('%s.tsv',i_set),'FileType','text','Delimiter','tab');
img_num = size(tsv_data,1);
family_num = (img_num-36)/24;
img_pool = uint8(zeros([img_num,300,300,3]));
for i = 1:img_num
    img_pool(i,:,:,:) = imresize(imread(fullfile(i_set,tsv_data.FileName{i})),[300,300]) + maskcircle;
end
cm = colorcet('C6'); cm = floor(255*cm(1:11:256,:));
for stims_family = 1:family_num
    ss{stims_family} = 36+24*(stims_family-1)+[1:24];
    img = [];
    for s = 1:24
        img_in = squeeze(img_pool(ss{stims_family}(s),:,:,:));
        img_in = add_edge(img_in, cm(s,:),20);
        img = [img, img_in];
        k{s} = img_in;
    end
    combined_pool24{stims_family}=img;
    combined_pool12{stims_family}= [k{1},k{4},k{7},k{10},k{13},k{16},k{19},k{22}];
    combined_pool38{stims_family} = [k{1},k{2},k{3},k{4},k{5},k{6},k{7},k{8};k{9},k{10},k{11},k{12},k{13},k{14},k{15},k{16};k{17},k{18},k{19},k{20},k{21},k{22},k{23},k{24}];
end
cm=cm/255;
end