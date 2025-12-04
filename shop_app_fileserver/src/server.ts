import app from "./app";
import { config } from "./config";

const PORT = config.app.port;

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 File Server corriendo en puerto ${PORT}`);
    console.log(`📁 Uploads directory: ${config.app.uploadDir}`);
    console.log(`📡 Accesible en http://localhost:${PORT}`);
    console.log(`📡 Accesible en red local: http://192.168.100.120:${PORT}`);
});