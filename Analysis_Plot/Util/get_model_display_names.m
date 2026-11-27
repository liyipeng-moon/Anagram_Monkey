function display_names = get_model_display_names(model_names)
% Convert internal model identifiers into labels used in the figure.
internal_names = [
    "alexnet"; "clip"; "clip_rn50"; "clip_vit_b16"; "convnext_tiny";
    "cornet_s"; "deit_b16_in1k"; "densenet121"; "dino_resnet50";
    "dino_v1"; "dino_vit_b16"; "dinov2"; "dinov2_vitb14";
    "dinov3_vitb16"; "dinov3_vitl16"; "efficientnet_b0";
    "eva02_clip_b16"; "imagenet_resnet50"; "imagenet_vit";
    "imagenet_vit_b16"; "mae"; "mobilenet_v3_large"; "moco_v2";
    "mocov3_resnet50"; "mocov3_vit_b16"; "openclip_rn50_cc12m";
    "openclip_rn50_yfcc15m"; "regnet_y_400mf"; "resnet101";
    "resnet18"; "resnet34"; "robust_resnet50"; "siglip"; "simclr";
    "swav"; "swin_tiny"; "vgg16"];

pretty_names = [
    "AlexNet";
    "CLIP ViT-B/32";
    "CLIP RN50";
    "CLIP ViT-B/16";
    "ConvNeXt-T";
    "CORnet-S";
    "DeiT-B/16";
    "DenseNet-121";
    "DINO RN50";
    "DINO ViT-S/16";
    "DINO ViT-B/16";
    "DINOv2 ViT-S/14";
    "DINOv2 ViT-B/14";
    "DINOv3 ViT-B/16";
    "DINOv3 ViT-L/16";
    "EfficientNet-B0";
    "EVA02-CLIP ViT-B/16";
    "ImageNet RN50";
    "ImageNet ViT-S/16";
    "ImageNet ViT-B/16";
    "MAE ViT-B/16";
    "MobileNetV3-L";
    "MoCo v2 RN50";
    "MoCo v3 RN50";
    "MoCo v3 ViT-B/16";
    "OpenCLIP RN50-CC12M";
    "OpenCLIP RN50-YFCC15M";
    "RegNet-Y-400MF";
    "ImageNet RN101";
    "ImageNet RN18";
    "ImageNet RN34";
    "Robust RN50";
    "SigLIP ViT-B/16";
    "SimCLR RN50";
    "SwAV RN50";
    "Swin-T";
    "VGG-16"
];

display_names = model_names;
[known_models, name_rows] = ismember(model_names, internal_names);
display_names(known_models) = pretty_names(name_rows(known_models));
end
