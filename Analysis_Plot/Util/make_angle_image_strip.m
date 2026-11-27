function image_strip = make_angle_image_strip(img_pool, stimulus_indices, angle_indices, angle_colors, edge_width)
first_angle = angle_indices(1);
first_image = squeeze(img_pool(stimulus_indices(first_angle), :, :, :));
first_image = add_edge(first_image, floor(255 * angle_colors(first_angle, :)), edge_width);
image_height = size(first_image, 1);
image_width = size(first_image, 2);
image_channels = size(first_image, 3);
image_strip = zeros(image_height, image_width * length(angle_indices), image_channels, 'like', first_image);

for image_idx = 1:length(angle_indices)
    angle_idx = angle_indices(image_idx);
    image_here = squeeze(img_pool(stimulus_indices(angle_idx), :, :, :));
    image_here = add_edge(image_here, floor(255 * angle_colors(angle_idx, :)), edge_width);
    image_columns = (image_idx - 1) * image_width + (1:image_width);
    image_strip(:, image_columns, :) = image_here;
end
end
