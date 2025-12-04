interface Config {
    db: {
        user: string;
        password: string;
        server: string;
        port: number;
        database: string;
    };
    app: {
        port: number;
        uploadDir: string;
        maxFileSize: number;
        allowedExtensions: string[];
    };
}

import path from "path";
import os from "os";
import fs from "fs";


function getUploadsPath() {
    const homeDir = os.homedir(); 
    const documentos = path.join(homeDir, "Documents");
    const carpetaFinal = path.join(documentos, "SHOPAPP");

    if (!fs.existsSync(carpetaFinal)) {
        fs.mkdirSync(carpetaFinal, { recursive: true });
    }

    return carpetaFinal;
}


export const config: Config = {
    db: {
        user: "sa",
        password: "Mege2089",
        server: "localhost",
        port: 1433,
        database: "LAROPANOSTRAA",
    },
    app: {
        port: 5113,
        uploadDir: "./uploads",// getUploadsPath(), 
        maxFileSize: 5242880, // 5MB
        allowedExtensions: ["jpg", "jpeg", "png", "gif", "webp"],
    },
};