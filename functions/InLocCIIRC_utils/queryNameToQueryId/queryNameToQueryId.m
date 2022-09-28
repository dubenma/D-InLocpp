function queryId = queryNameToQueryId(queryName)
    queryId = strsplit(queryName, '.');
    queryId = strsplit(queryId{1}, '/');
    queryId = str2num(queryId{end});
end