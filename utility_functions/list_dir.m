function dirs = list_dir(dir_in)

dir_str = dir(dir_in);

dirs = {};
dir_ctr = 1;

for itt_str = 1 : length(dir_str)
    
    if dir_str(itt_str).name(1) ~= '.' && ...
            dir_str(itt_str).name(1) ~= '_'
        
        if dir_str(itt_str).isdir == true
            
            dirs{dir_ctr} = [dir_in dir_str(itt_str).name];
            dir_ctr = dir_ctr + 1;
  
        end
    end
end
end