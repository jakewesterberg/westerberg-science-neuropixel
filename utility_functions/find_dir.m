function dir_cont = find_dir(dir_in,search_exp)

dir_str = dir(dir_in);
dir_cont = {};

for itt_str = 1 : length(dir_str)
    
    if dir_str(itt_str).isdir && ...
            ~isempty(regexp(dir_str(itt_str).name,search_exp,'match'))
        
        dir_cont{length(dir_cont) + 1} = [ dir_in dir_str(itt_str).name];
        
    end
end
end