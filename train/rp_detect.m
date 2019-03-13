function [pos,current_sz,max_response] = rp_detect(im,pos,window_sz,bbs,target_sz,app_sz,app_model,config,max_response,current_sz,pdiff)        
        % when tracking failure happen, detection     
               app_response = zeros(size(bbs,1),1);%zeros(numel(nonzeros(ind)),1);
               dist = zeros(size(bbs,1),1);%zeros(numel(nonzeros(ind)),1);
              if nonzeros(bbs)
               for ii=1:size(bbs,1)%numel(nonzeros(ind))
                 bb=bbs((ii),:);
                 proposal_loc = floor(pos-window_sz./2+pdiff+[bb(2) bb(1)]+[bb(4)./2 bb(3)./2]);
                 [proposal] = get_subwindow(im,proposal_loc,[bb(4) bb(3)]);
                 proposal = imresize(proposal,config.app_sz,'bilinear');
                 feat = get_hog_features(proposal,config,[]);
                 model_alpha = real(ifft2(app_model.alphaf));
                 kf = gaussian_correlation_nofft(fft2(feat),app_model.xf,config.kernel_sigma);
                 app_resp = model_alpha.*(kf);
                 app_response(ii)=sum(app_resp(:));
                 dist(ii)= .1*exp(-1./(2*app_sz*app_sz')*sum(abs(pos-proposal_loc).^2));
               end
               
              [app_max_response,ind1]=max(app_response(:));
              
              if (app_max_response>max_response)&& (app_max_response>1.5*config.motion_thresh) %1.5
                  max_response = app_max_response; % use good proposals for updating  model
                 [~,ind] = max(app_response(:)+dist(:));
                 bb=bbs((ind),:);
                 pos3 = pos-window_sz./2+[bb(2) bb(1)]+[bb(4)./2 bb(3)./2];
                 patch3 = get_subwindow(im,pos3,[bb(4) bb(3)]);
                 pos = pos+floor(0.8*(pos3-pos));
                 current_sz = current_sz+0.6*([bb(4) bb(3)]-current_sz);
                % extract the test sample feature map for the scale filter
              end
              end
