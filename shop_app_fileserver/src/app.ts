import express from "express";
import cors from "cors";
import path from "path";
import fileRoutes from "./routes/file.routes";
import { errorHandler } from "./middleware/error.middleware";
import { config } from "./config";

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// ✅ Servir archivos estáticos desde C:/uploads
app.use("/uploads", express.static(config.app.uploadDir));

// Rutas
app.use("/api/files", fileRoutes);

// Ruta de health check
app.get("/health", (req, res) => {
    res.json({
        status: "ok",
        message: "File server funcionando correctamente",
        uploadDir: config.app.uploadDir,
        timestamp: new Date().toISOString(),
    });
});

// Middleware de errores (al final)
app.use(errorHandler);

export default app;