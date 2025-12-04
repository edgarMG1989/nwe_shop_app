import { JsonController, Get, Post, QueryParam, Body, Req, Put, Delete, UseBefore } from "routing-controllers";
import { Request } from "express";
import { ProductoRepository } from "../repository/producto.repository";
import multer from "multer";

import FormData from "form-data";
import axios from "axios";

const upload = multer({ storage: multer.memoryStorage() });

@JsonController("/productos")
export class ProductoController {
    private repository: ProductoRepository;

    constructor() {
        this.repository = new ProductoRepository();
    }

    @Get("/novedades")
    async getProductosNovedad(@Req() req: Request) {
        return await this.repository.obtenerProductosNovedad(req.query);
    }

    @Get("/inventario")
    async getProductoInventario(@Req() req: Request) {
        return await this.repository.obtenerProductoInventario(req.query);
    }

    @Get("/genero")
    async getProductoGenero(@Req() req: Request) {
        return await this.repository.obtenerProductoGenero(req.query);
    }

    @Get("/validaInventario")
    async validaInventario(@Req() req: Request) {
        return await this.repository.validaInventario(req.query);
    }

    @Get("/all")
    async all(@Req() req: Request) {
        return await this.repository.all(req.query);
    }

    @Get("/getProductoId")
    async getProductoId(@Req() req: Request) {
        return await this.repository.getProductoId(req.query);
    }

    @Post("/postAgregarProducto")
    async postAgregarProducto(@Body() body: any) {
        return await this.repository.postAgregarProducto(body);
    }

    @Post("/tryon")
    @UseBefore(upload.fields([
        { name: "userImage", maxCount: 1 },
        { name: "garmentImage", maxCount: 1 },
    ]))
    async generarTryOn(@Req() req: Request) {
        try {
            console.log("Enviando a servidor Python local...");

            const formData = new FormData();
            formData.append('userImage', req.files["userImage"][0].buffer, {
                filename: 'person.jpg',
                contentType: 'image/jpeg'
            });
            formData.append('garmentImage', req.files["garmentImage"][0].buffer, {
                filename: 'garment.jpg',
                contentType: 'image/jpeg'
            });
            
            formData.append("description", req.body.description || "clothing item");

            const response = await axios.post(
                'https://tryon-server-ab5a.onrender.com/tryon',
                formData,
                {
                    headers: formData.getHeaders(),
                    timeout: 90000 // 90 segundos
                }
            );

            return response.data;

        } catch (error: any) {
            console.error("Error:", error.message);
            return {
                success: false,
                message: error.message
            };
        }
    }

    @Put("/putEditarProducto")
    async putEditarProducto(@Body() body: any) {
        return await this.repository.putEditarProducto(body);
    }

    @Delete("/deleteEliminarProducto")
    async deleteEliminarProducto(@Body() body: any) {
        return await this.repository.deleteEliminarProducto(body);
    }


}

