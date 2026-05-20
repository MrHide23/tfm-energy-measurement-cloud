class GPU{
   private String nombre;
   private int cores;
   public GPU(String nombre, int cores){
      this.nombre=nombre;
      this.cores=cores;
   }
   public void setNombre(String arg){
      this.nombre=arg;
   }
   public String getNombre(){
      return nombre;
   }
   public void setCores(int arg){
      this.cores=arg;
   }
   public int getCores(){
      return cores;
   }
}
