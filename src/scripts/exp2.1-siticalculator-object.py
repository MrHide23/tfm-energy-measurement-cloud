class SITI:
    def __init__(self, name_video=None, chunck=None, SI=0.0, TI=0.0):
        self.name_video = name_video
        self.chunck = chunck
        self.SI = SI
        self.TI = TI

    def get_json_data(self):
        return {
            "name_video": self.name_video,
            "chunck": self.chunck,
            "SI": self.SI,
            "TI": self.TI
        }
    def get_csv_data(self):
        return f"{self.name_video},{self.chunck},{self.SI},{self.TI}"