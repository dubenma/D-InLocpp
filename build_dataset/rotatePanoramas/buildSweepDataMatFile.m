% to be filled by user
% it is the ID as displayed in the Capture iPadOS app
% aka the number in a blue circle
% NOTE: you are expected to adjust the goodness parameter accordingly
% (in the resulting params.sweepData.mat.path file)
panoIds = [1:116];
        
%% initialize 
startup;
[ params ] = setupParams('hospital_1');

%% Fill in the sweep data structure
in = jsondecode(fileread(params.sweepData.json.path));
assert(size(panoIds,2) == size(in,1));
for i=1:size(in,1)
    out(i).uuid = in(i).uuid;
    out(i).panoId = panoIds(i);
    out(i).position = [in(i).position.x; in(i).position.y; in(i).position.z];
    out(i).rotation = [in(i).rotation.x in(i).rotation.y in(i).rotation.z];
    out(i).goodness = 1;
end

sweepData = out;

%% Save the sweep data
save(params.sweepData.mat.path, 'sweepData');