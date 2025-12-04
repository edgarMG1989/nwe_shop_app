import { Router } from "express";
import { upload } from "../config/multer.config";
import { FileController } from "../controllers/file.controller";

const router = Router();

// 📤 Subir un archivo
// POST /api/files/upload
// Body/Query: path=PRODUCTO/1/imagen_principal
router.post("/upload", upload.single("file"), FileController.uploadFile);

// 📤 Subir múltiples archivos
// POST /api/files/upload-multiple
// Body/Query: path=PRODUCTO/1/galeria
router.post("/upload-multiple", upload.array("files", 10), FileController.uploadMultiple);

// 🗑️ Eliminar un archivo
// DELETE /api/files/delete
// Body/Query: path=PRODUCTO/1/imagen_principal/123456-imagen.jpg
router.delete("/delete", FileController.deleteFile);

// 📋 Listar archivos de una ruta
// GET /api/files/list?path=PRODUCTO/1
router.get("/list", FileController.listFiles);

export default router;