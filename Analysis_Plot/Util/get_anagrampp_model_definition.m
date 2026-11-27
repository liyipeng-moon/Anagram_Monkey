function [family_model_rows, critical_points] = get_anagrampp_model_definition(stimulus_root, feature_directory, first_model_name)
% Match the canonical stimulus definition to rows in the model feature files.
metadata = load(fullfile(feature_directory, first_model_name + ".mat"), 'file_names');
model_file_names = string(metadata.file_names(:));
stimulus_directory = fullfile(stimulus_root, 'AnagramPP');
previous_directory = pwd;
directory_cleanup = onCleanup(@() cd(previous_directory));
cd(stimulus_directory)
[family_stimuli, critical_points, ~] = gen_famuli_compare('AnagramPP');
stimulus_table = readtable('AnagramPP.tsv', 'FileType', 'text', 'Delimiter', 'tab', 'TextType', 'string');
family_model_rows = cell(10, 1);
for family_index = 1:10
    requested_file_names = stimulus_table.FileName(family_stimuli{family_index});
    [all_found, model_rows] = ismember(requested_file_names, model_file_names);
    if ~all(all_found)
        missing_file_name = requested_file_names(find(~all_found, 1));
        error('Could not find %s in the compact AnagramPP feature files.', missing_file_name)
    end
    family_model_rows{family_index} = model_rows;
end
clear directory_cleanup
end
