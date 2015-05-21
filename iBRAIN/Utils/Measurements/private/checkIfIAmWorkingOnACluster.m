function amIaClusterComputer = checkIfIAmWorkingOnACluster

persistent cachedIAmBrutus  % remove excess system calls

if isempty(cachedIAmBrutus)
   
    [~, name] = system('hostname');
    
    if any(strfind(name,'brutus'));
        cachedIAmBrutus = true;
    elseif any(strfind(name,'hpc-net'));
        cachedIAmBrutus = true;
    else
        cachedIAmBrutus = false;
    end
    
end

amIaClusterComputer = cachedIAmBrutus;

end