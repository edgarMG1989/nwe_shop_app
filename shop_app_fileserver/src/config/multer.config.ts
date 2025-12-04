import multer from "multer";
import path from "path";
import fs from "fs";
import { config } from "../config";


// Configuración de almacenamiento
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // ✅ Obtener el path del body o query
        const customPath = req.body.path || req.query.path;

        if (!customPath) {
            return cb(new Error("El parámetro 'path' es requerido"), "");
        }

        // ✅ Validar que no contenga caracteres peligrosos
        const sanitizedPath = customPath.replace(/\.\./g, "").replace(/^\/+/, "");

        // ✅ Construir ruta completa: C:/uploads/PRODUCTO/id/nombre
        const uploadPath = path.join(config.app.uploadDir, sanitizedPath);

        console.log("📁 Guardando en:", uploadPath);

        // ✅ Crear carpetas recursivamente si no existen
        if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath, { recursive: true });
            console.log("✅ Carpeta creada:", uploadPath);
        }

        cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
        // ✅ Generar nombre único con timestamp
        const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname);
        const nameWithoutExt = path.basename(file.originalname, ext);
        const sanitizedName = nameWithoutExt.replace(/[^a-zA-Z0-9]/g, "_");
        
        const filename = `${uniqueSuffix}-${sanitizedName}${ext}`;
        
        console.log("📝 Nombre del archivo:", filename);
        
        cb(null, filename);
    },
});

// Filtro de archivos permitidos
const fileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const ext = path.extname(file.originalname).toLowerCase().substring(1);

    if (config.app.allowedExtensions.includes(ext)) {
        cb(null, true);
    } else {
        cb(new Error(`Solo se permiten archivos: ${config.app.allowedExtensions.join(", ")}`));
    }
};

// Límite de tamaño
const limits = {
    fileSize: config.app.maxFileSize,
};

export const upload = multer({
    storage,
    fileFilter,
    limits,
});