import { JsonController, Get, Post, QueryParam, Body, Req, Delete, Put } from "routing-controllers";
import { Request } from "express";
import { FileServerRepository } from "../repository/fileserver.repository";

@JsonController("/fileserver")
export class FileServerController {
    private repository: FileServerRepository;

    constructor() {
        this.repository = new FileServerRepository();
    }

   
    @Post("/postInsDocumento")
    async postInsDocumento(@Body() body: any) {
        return await this.repository.postInsDocumento(body);
    }



}