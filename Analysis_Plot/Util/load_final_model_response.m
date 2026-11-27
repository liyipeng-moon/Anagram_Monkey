function [layer_response, final_layer] = load_final_model_response(feature_directory, model_name)
% Load the saved final representation and return one feature vector per image.
model_path = fullfile(feature_directory, model_name + ".mat");
model_metadata = load(model_path, 'layer_names');
final_layer = string(model_metadata.layer_names{end});
safe_layer_name = regexprep(final_layer, '[^A-Za-z0-9_]', '_');
variable_name = "embedding_" + safe_layer_name;
loaded_layer = load(model_path, variable_name);
layer_response = loaded_layer.(variable_name);
if ndims(layer_response) == 4
    % Average spatial dimensions but keep the image and feature dimensions.
    layer_response = mean(layer_response, 4);
    layer_response = mean(layer_response, 3);
    layer_response = squeeze(layer_response);
end
layer_response = reshape(double(layer_response), size(layer_response, 1), []);
end
