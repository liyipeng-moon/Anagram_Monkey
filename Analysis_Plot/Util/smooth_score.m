function new_score = smooth_score(Score_now,ccbin)
new_score = Score_now;
for trial = 1:size(Score_now,2)
    new_score(:,trial) = conv(Score_now(:,trial),ones([1,ccbin]),'same')/ccbin;
end