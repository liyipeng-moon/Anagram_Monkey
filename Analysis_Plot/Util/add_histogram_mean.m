function add_histogram_mean(d1)
yl = ylim; ylim(yl)
scatter(mean(d1), yl(2),16,Marker="v",MarkerFaceColor='k',MarkerEdgeColor='k')
yl=ylim; ylim([0,yl(2)*1.1])