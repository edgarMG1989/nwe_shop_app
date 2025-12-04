import { JsonController, Get, Post, Body, Req, Delete, Put } from "routing-controllers";
import { SeguridadRepository } from "../repository/seguridad.repository";

@JsonController("/seguridad")
export class SeguridadController {
    private repository: SeguridadRepository;

    constructor() {
        this.repository = new SeguridadRepository();
    }

    @Post("/login")
    async postAgregarCarrito(@Body() body: any) {
        return await this.repository.login(body);
    }

    @Post("/postInsPerfil")
    async postInsPerfil(@Body() body: any) {
        return await this.repository.postInsPerfil(body);
    }

    @Post("/updatePerfil")
    async updatePerfil(@Body() body: any) {
        return await this.repository.updatePerfil(body);
    }



}