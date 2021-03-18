
class Logger(object):
    lastMessage = None

    def debug(self, msg):
        self.lastMessage = msg

    def warning(self, msg):
        self.lastMessage = msg

    def error(self, msg):
        self.lastMessage = msg
