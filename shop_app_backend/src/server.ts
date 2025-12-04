import "reflect-metadata";
import app from "./app";
import config from "./config";

const env = process.env.NODE_ENV || 'development';
const currentConfig = (config as any)[env]; 

const PORT = currentConfig.app.port || 4112;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`📡 Accesible en http://192.168.100.120:${PORT}`);
});
