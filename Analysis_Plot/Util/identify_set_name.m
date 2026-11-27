function set_name = identify_set_name(file_name)
loc1 = find(file_name=='-');
set_name = file_name(loc1(end)+1:end-4);