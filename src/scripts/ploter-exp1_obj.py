class FilesCSV:
    def __init__(self, nombre_archivo, dir_archivo):
        self.nombre_archivo = nombre_archivo
        self.dir_archivo = dir_archivo 

class DataProcessed:
    def __init__(self, tool, case, em_total_energy, node_total_joules,gpu_node_jouls,*args):
        self.tool = tool
        self.case = case
        self.em_total_energy = em_total_energy
        self.node_total_joules = node_total_joules
        self.gpu_node_jouls=gpu_node_jouls
        self.process_energy_joules_list = args 
        
    def as_dict(self):
        # 1. Inicializar el diccionario con los campos base
        as_dict_parse = {
            "tool": self.tool,
            "case": self.case,
            "em_total_energy": self.em_total_energy,
            "node_total_joules": self.node_total_joules,
            "gpu_node_jouls": self.gpu_node_jouls
        }

        if self.process_energy_joules_list and isinstance(self.process_energy_joules_list[0], list):
            lista_valores = self.process_energy_joules_list[0]
        else:
            lista_valores = self.process_energy_joules_list

        print(f"Tool {self.tool} ---> {lista_valores}")
        # 2. Añadir dinámicamente las claves numeradas sin sobreescribir la misma línea
        for idx, process_energy in enumerate(lista_valores):
            
            as_dict_parse[f"process{idx + 1}_energy_joules"] = process_energy
            
        return as_dict_parse
    
