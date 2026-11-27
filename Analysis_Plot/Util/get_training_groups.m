function training_groups = get_training_groups(model_names)
% Return 1 for language supervision, 2 for self-supervision, and 3 for classification.
language_models = ["siglip"; "clip"; "clip_vit_b16"; "eva02_clip_b16"; "clip_rn50"; "openclip_rn50_yfcc15m"; "openclip_rn50_cc12m"];
classification_models = ["alexnet"; "convnext_tiny"; "cornet_s"; "deit_b16_in1k"; "densenet121"; "efficientnet_b0"; "imagenet_resnet50"; "imagenet_vit"; "imagenet_vit_b16"; "mobilenet_v3_large"; "regnet_y_400mf"; "resnet101"; "resnet18"; "resnet34"; "robust_resnet50"; "swin_tiny"; "vgg16"];
training_groups = 2 * ones(length(model_names), 1);
training_groups(ismember(model_names, language_models)) = 1;
training_groups(ismember(model_names, classification_models)) = 3;
end
