function metric_columns = map_family_metric_columns(family_stimuli)
block_start_positions = [1, 25, 49, 73, 97, 121];
block_start_stimuli = family_stimuli(block_start_positions);
metric_columns = (block_start_stimuli - 37) / 24 + 1;

mapped_block_starts = 37 + 24 * (metric_columns - 1);
if any(mapped_block_starts ~= block_start_stimuli)
    error('Metric-column mapping failed.')
end
end
