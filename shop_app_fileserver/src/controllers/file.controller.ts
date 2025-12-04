import { Request, Response } from "express";
import path from "path";
import fs from "fs";
import { config } from "../config";

export class FileController {
    // 📤 Subir archivo
    static uploadFile(req: Request, res: Response) {
        try {
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: "No se proporcionó ningún archivo",
                });
            }

            const customPath = req.body.path || req.query.path;

            if (!customPath) {
                return res.status(400).json({
                    success: false,
                    message: "El parámetro 'path' es requerido1",
                });
            }

            // ✅ Construir URL relativa
            const sanitizedPath = customPath.replace(/\.\./g, "").replace(/^\/+/, "");
            const fileUrl = `/${sanitizedPath}/${req.file.filename}`.replace(/\\/g, "/");

            console.log("✅ Archivo subido:", fileUrl);

            res.status(200).json({
                success: true,
                message: "Archivo subido exitosamente",
                data: {
                    filename: req.file.filename,
                    originalName: req.file.originalname,
                    size: req.file.size,
                    mimeType: req.file.mimetype,
                    path: sanitizedPath,
                    url: fileUrl,
                    fullUrl: `${req.protocol}://${req.get("host")}/uploads${fileUrl}`,
                    localPath: req.file.path,
                },
            });
        } catch (error: any) {
            console.error("❌ Error al subir archivo:", error);
            res.status(500).json({
                success: false,
                message: error.message || "Error al subir archivo",
            });
        }
    }

    // 📤 Subir múltiples archivos
    static uploadMultiple(req: Request, res: Response) {
        try {
            if (!req.files || (req.files as Express.Multer.File[]).length === 0) {
                return res.status(400).json({
                    success: false,
                    message: "No se proporcionaron archivos",
                });
            }

            const customPath = req.body.path || req.query.path;

            if (!customPath) {
                return res.status(400).json({
                    success: false,
                    message: "El parámetro 'path' es requerido2",
                });
            }

            const files = req.files as Express.Multer.File[];
            const sanitizedPath = customPath.replace(/\.\./g, "").replace(/^\/+/, "");

            const uploadedFiles = files.map((file) => {
                const fileUrl = `/${sanitizedPath}/${file.filename}`.replace(/\\/g, "/");
                
                return {
                    filename: file.filename,
                    originalName: file.originalname,
                    size: file.size,
                    mimeType: file.mimetype,
                    path: sanitizedPath,
                    url: fileUrl,
                    fullUrl: `${req.protocol}://${req.get("host")}/uploads${fileUrl}`,
                    localPath: file.path,
                };
            });

            console.log(`✅ ${files.length} archivos subidos`);

            res.status(200).json({
                success: true,
                message: `${files.length} archivos subidos exitosamente`,
                data: uploadedFiles,
            });
        } catch (error: any) {
            console.error("❌ Error al subir archivos:", error);
            res.status(500).json({
                success: false,
                message: error.message || "Error al subir archivos",
            });
        }
    }

    // 🗑️ Eliminar archivo
    static deleteFile(req: Request, res: Response) {
        try {
            // ✅ Recibir path completo desde el body o query
            const filePath = req.body.path || req.query.path;

            if (!filePath) {
                return res.status(400).json({
                    success: false,
                    message: "El parámetro 'path' es requerido3",
                });
            }

            // ✅ Construir ruta completa
            const sanitizedPath = filePath.replace(/\.\./g, "").replace(/^\/+/, "");
            const fullPath = path.join(config.app.uploadDir, sanitizedPath);

            console.log("🗑️ Intentando eliminar:", fullPath);

            if (!fs.existsSync(fullPath)) {
                return res.status(404).json({
                    success: false,
                    message: "Archivo no encontrado",
                });
            }

            fs.unlinkSync(fullPath);

            console.log("✅ Archivo eliminado:", fullPath);

            res.status(200).json({
                success: true,
                message: "Archivo eliminado exitosamente",
            });
        } catch (error: any) {
            console.error("❌ Error al eliminar archivo:", error);
            res.status(500).json({
                success: false,
                message: error.message || "Error al eliminar archivo",
            });
        }
    }

    // 📋 Listar archivos de una ruta
    static listFiles(req: Request, res: Response) {
        try {
            const customPath = req.query.path as string;

            if (!customPath) {
                return res.status(400).json({
                    success: false,
                    message: "El parámetro 'path' es requerido4",
                });
            }

            const sanitizedPath = customPath.replace(/\.\./g, "").replace(/^\/+/, "");
            const fullPath = path.join(config.app.uploadDir, sanitizedPath);

            console.log("📋 Listando archivos en:", fullPath);

            if (!fs.existsSync(fullPath)) {
                return res.status(404).json({
                    success: false,
                    message: "Ruta no encontrada",
                    data: [],
                });
            }

            const files = fs.readdirSync(fullPath);

            const fileList = files.map((filename) => {
                const filePath = path.join(fullPath, filename);
                const stats = fs.statSync(filePath);
                const fileUrl = `/${sanitizedPath}/${filename}`.replace(/\\/g, "/");

                return {
                    filename,
                    size: stats.size,
                    createdAt: stats.birthtime,
                    isDirectory: stats.isDirectory(),
                    url: fileUrl,
                    fullUrl: `${req.protocol}://${req.get("host")}/uploads${fileUrl}`,
                };
            });

            res.status(200).json({
                success: true,
                message: `${files.length} elementos encontrados`,
                data: fileList,
            });
        } catch (error: any) {
            console.error("❌ Error al listar archivos:", error);
            res.status(500).json({
                success: false,
                message: error.message || "Error al listar archivos",
            });
        }
    }
}