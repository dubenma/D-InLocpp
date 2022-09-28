from efficientnet_pytorch import EfficientNet
from torch import nn

class RelPNet(nn.Module):
    """RelPNet model.
       Utilizes EfficientNet as encoder. Then estimates relative pose.
    """
    def __init__(self, encoder='b0', only_head_trainable=False, head='fc'):
        super().__init__()

        model = 'efficientnet-b0' if 'b0' in encoder else 'efficientnet-b3'
        self.EffNet = EfficientNet.from_pretrained(model, num_classes=1280)
        if only_head_trainable:
            for param in self.EffNet.parameters():
                param.requires_grad = False
        if head=='fc':
            self._fc = nn.Linear(1280*2*1*1, 1)
        else:
            self._fc = nn.Linear(1280*2*1*1, 1)

    
    def forward(self, inputs):
        # Effnet layer - get embeddings from both images
        x = self.EffNet(inputs.view(inputs.shape[0]*inputs.shape[1], *inputs.shape[2:]))
        # get error from features using functional layer
        x = x.view(int(x.shape[0]/2), 2,*x.shape[1:]) # get
        x = x.view(x.shape[0], -1)
        x = self._fc(x)
        return x.abs()

