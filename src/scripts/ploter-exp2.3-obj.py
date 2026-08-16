class DataObject:
    def __init__(
            self,
            nombre_video=None, 
            hw="cpu", 
            n_cores=0, 
            codec=None, 
            bitrate_Mbps='30Mbps',
            ex_time=None, 
            consumo_process_j=None
    ):
                
        self.nombre_video=nombre_video
        self.hw=hw
        self.codec=codec
        self.n_cores=n_cores
        self.bitrate_Mbps=bitrate_Mbps
        self.ex_time = [] if ex_time is None else ex_time
        self.consumo_process_j = [] if consumo_process_j is None else consumo_process_j

    def as_dict(self):
        data={
            "nombre_video": self.nombre_video,
            "hw": self.hw,
            "codec":self.codec,
            "n_cores": self.n_cores,
            "bitrate_Mbps": self.bitrate_Mbps
        }

        for idx,consumo in enumerate(self.consumo_process_j):
            data[f"ex_time_cont{idx}_s"]=self.ex_time[idx]
            data[f"consumo_container{idx}_j"]=consumo
        return data
        
    def full_dict(self):
        return self.__dict__