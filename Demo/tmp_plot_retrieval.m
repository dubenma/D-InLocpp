% Skript for manual printing of "k" neighbouring images
% Adjust manually the variables ImgList/ImgList_original; ii, kk to show
% desired images.


for ii = 10   % 1 5 10 - length(ImgList_original)
%     ImgList(ii).queryname = ImgList(ii).queryname;
%     ImgList(ii).topNname = ImgList(ii).topNname(1:shortlist_topN);
%     ImgList(ii).primary = ImgList(ii).primary;

    im1 = imread(fullfile(params.dataset.query.dir, ImgList(ii).queryname));
    subfig(4,4,1); imshow(im1); axis image; title(['Query image ' ImgList(ii).queryname]); 
    Position = get(gcf,'Position');
    set(gcf,'Position',[Position(1) Position(2) Position(3) Position(4)+120]);
    saveas(gcf,sprintf('./tmp/densegv_q%s',ImgList(ii).queryname))

    for kk = 1:3 %shortlist_topN
%         cutoutPath = ImgList(ii).topNname{kk};
%         this_gvresults = load(fullfile(params.output.gv_dense.dir, ImgList(ii).queryname, buildCutoutName(cutoutPath, params.output.gv_dense.matformat)));

        im2 = imread(fullfile(params.dataset.db.cutouts.dir, ImgList(ii).topNname{kk}));
        figure(); imshow(im2); title(sprintf('DenseGV: %dth neighbouring image',kk));
        set(gcf,'Position',[Position(1) Position(2) Position(3) Position(4)+120]);
        [a, b, c] = fileparts(ImgList(ii).topNname{kk});
        saveas(gcf,sprintf('./tmp/densegv_q%s-d%d__%s.jpg',ImgList(ii).queryname(1:end-4),kk,b))
    end

    
end