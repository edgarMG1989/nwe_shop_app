import { JsonController, Get, Post, QueryParam, Body, Req, Delete, Put } from "routing-controllers";
import { Request } from "express";
import { CatalogoRepository } from "../repository/catalogo.repository";

@JsonController("/catalogo")
export class CatalogoController {
    private repository: CatalogoRepository;

    constructor() {
        this.repository = new CatalogoRepository();
    }

    @Get("/getTallas")
    async getTallas(@Req() req:Request) {
        return await this.repository.getTallas(req.query);
    }

    @Get("/getGeneros")
    async getGeneros(@Req() req:Request) {
        return await this.repository.getGeneros(req.query);
    }

    @Get("/getTipoPrenda")
    async getTipoPrenda(@Req() req:Request) {
        return await this.repository.getTipoPrenda(req.query);
    }

   

}