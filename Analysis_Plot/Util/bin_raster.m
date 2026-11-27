function raster_mtx_binned=bin_raster(raster_mtx, bin_t)

raster_mtx_binned = zeros(size(raster_mtx),'uint8');
for unit = 1:size(raster_mtx,1)
    parfor trial = 1:size(raster_mtx,2)
        raster_mtx_binned(unit,trial,:) = conv(squeeze(raster_mtx(unit,trial,:)),ones([1,bin_t]),"same");
    end
end

end