function loc = look_for_tsv(tsv_in,index)
for i = 1:size(tsv_in,1)
    if(strcmp(sprintf('Stim%d_01_ang_000.jpg',index), tsv_in{i,1}))
        loc=i;
        return
    end
    if(strcmp(sprintf('Stim%d_1_ang_000.jpg',index), tsv_in{i,1}))
        loc=i;
        return
    end
end