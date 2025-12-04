import { Request, Response, NextFunction } from "express";
import { MulterError } from "multer";

export function errorHandler(
    err: Error,
    req: Request,
    res: Response,
    next: NextFunction
) {
    console.error("❌ Error:", err);

    // Errores de Multer
    if (err instanceof MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
                success: false,
                message: "El archivo excede el tamaño máximo permitido",
            });
        }
        if (err.code === "LIMIT_FILE_COUNT") {
            return res.status(400).json({
                success: false,
                message: "Se excedió el número máximo de archivos",
            });
        }
    }

    // Otros errores
    res.status(500).json({
        success: false,
        message: err.message || "Error interno del servidor",
    });
}