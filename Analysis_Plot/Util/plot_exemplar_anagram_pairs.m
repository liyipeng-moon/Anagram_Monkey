function plot_exemplar_anagram_pairs(exemplar_values, anagram_values, valid_pairs, pair_exemplar)
hold on
valid_pair_indices = find(valid_pairs);
for valid_idx = 1:length(valid_pair_indices)
    pair_idx = valid_pair_indices(valid_idx);
    plot([1, 2], [exemplar_values(pair_idx), anagram_values(pair_idx)], '-', 'Color', 'k', 'LineWidth', 0.8)
end

exemplar_a_pairs = valid_pairs & pair_exemplar == 1;
exemplar_b_pairs = valid_pairs & pair_exemplar == 2;
exemplar_a_handle = scatter(ones(sum(exemplar_a_pairs), 1), exemplar_values(exemplar_a_pairs), 25, 'k', 'filled');
exemplar_b_handle = scatter(ones(sum(exemplar_b_pairs), 1), exemplar_values(exemplar_b_pairs), 25, 'k', 'filled');
anagram_handle = scatter(2 * ones(sum(valid_pairs), 1), anagram_values(valid_pairs), 25, 'k', 'filled');
% median_handle = scatter(1, median(exemplar_values(valid_pairs)), 110, 'rv', 'filled');
% scatter(2, median(anagram_values(valid_pairs)), 110, 'rv', 'filled')
xlim([0.65, 2.35])
xticks([1, 2])
xticklabels({'Exemplar', 'Matched Anagram'})
end
