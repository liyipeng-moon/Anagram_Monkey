function plot_mds(mds,cm,mk,sz)
for im_idx = 1:24
    if(im_idx<24)
        plot([mds(im_idx,1),mds(im_idx+1,1)],[mds(im_idx,2),mds(im_idx+1,2)],'Color',[0.5,0.5,0.5],LineWidth=1)
    else
        plot([mds(im_idx,1),mds(1,1)],[mds(im_idx,2),mds(1,2)],'Color',[0.5,0.5,0.5],LineWidth=1)
    end
end
for im_idx = 1:24
    scatter(mds(im_idx,1),mds(im_idx,2),sz,'filled',MarkerFaceColor=cm(im_idx,:),Marker=mk)
end