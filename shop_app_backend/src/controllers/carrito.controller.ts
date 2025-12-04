import { JsonController, Get, Post, QueryParam, Body, Req, Delete, Put } from "routing-controllers";
import { CarritoRepository } from "../repository/carrito.repository";
import { Request } from "express";

@JsonController("/carrito")
export class CarritoController {
    private repository: CarritoRepository;

    constructor() {
        this.repository = new CarritoRepository();
    }

    @Get("/getCarrito")
    async getCarrito(@Req() req: Request) {
        return await this.repository.getCarrito(req.query);
    }

    @Post("/postAgregarCarrito")
    async postAgregarCarrito(@Body() body: any) {
        return await this.repository.postAgregarCarrito(body);
    }

    @Put("/putActualizarCarritoCantidad")
    async postActualizarCarritoCantidad(@Body() body: any) {
        return await this.repository.actualizarCantidadCarrito(body);
    }

    @Delete("/deleteEliminarCarrito")
    async eliminarCarrito(@Body() body: any) {
        return await this.repository.eliminarCarrito(body);
    }


}