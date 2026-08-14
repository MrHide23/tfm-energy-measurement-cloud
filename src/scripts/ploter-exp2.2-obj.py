
class DataObject:
    
    def __init__(self, nombre_video=None, hw="cpu", kind=None, codec=None, bitrate_Mbps=None, consumo_process_j=[],si=0.0,ti=0.0):
        self.nombre_video=nombre_video
        self.hw=hw
        self.kind=kind
        self.codec=codec
        self.bitrate_Mbps=bitrate_Mbps
        self.consumo_process_j=consumo_process_j
        self.si=si
        self.ti=ti

    def as_dict(self):
        data={
            "nombre_video": self.nombre_video,
            "hw": self.hw,
            "kind": self.kind,
            "codec":self.codec,
            "bitrate_Mbps": self.bitrate_Mbps,
            "SI": self.si,
            "TI": self.ti
        }

        for idx,cosnumo in enumerate(self.consumo_process_j):
            data[f"consumo_container{idx}_j"]=cosnumo
        
        return data