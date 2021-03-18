
class ProgressWrapper(object):

    def __init__(self, callback):
        super().__init__()
        self.callback = callback

    def __call__(self, progress):
        self.progress = progress
        self.callback(self)
