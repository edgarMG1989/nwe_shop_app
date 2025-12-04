import "reflect-metadata";
import express from "express";
import cors from "cors";
import { useExpressServer } from "routing-controllers";
import { ProductoController } from "./controllers/producto.controller";
import { CarritoController } from "./controllers/carrito.controller";
import { SeguridadController } from "./controllers/seguridad.controller";
import { CatalogoController } from "./controllers/catalogo.controller";
import { FileServerController } from "./controllers/fileserver.controller";
import {  VentaController } from "./controllers/venta.controller";

const app = express();

app.use(cors());

// Configurar routing-controllers
useExpressServer(app, {
    routePrefix: "/api",
    controllers: [ProductoController, CarritoController, SeguridadController, CatalogoController, FileServerController, VentaController],
    defaultErrorHandler: true,
    validation: true,
    classTransformer: true,
    defaults: {
        nullResultCode: 404,
        undefinedResultCode: 204,
    },
});

export default app;