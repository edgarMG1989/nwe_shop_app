import app from "./app";
import { config } from "./config";
import fs from "fs";

const PORT = config.app.port;

if (!fs.existsSync(config.app.uploadDir)) {
    fs.mkdirSync(config.app.uploadDir, { recursive: true });
}

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 File Server corriendo en puerto ${PORT}`);
    console.log(`📁 Uploads directory: ${config.app.uploadDir}`);
    console.log(`📡 Accesible en http://localhost:${PORT}`);
    console.log(`📡 Accesible en red local: http://192.168.100.120:${PORT}`);
});