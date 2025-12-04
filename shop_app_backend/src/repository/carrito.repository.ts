import { Service } from 'typedi';
import { Query } from '../data/query';
import config from '../config';

@Service()
export class CarritoRepository {
    private conf: any;
    query: any;

    constructor() {
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];
        this.query = new Query();
    }

    async getCarrito(query: any): Promise<any> {
        return await this.query.spExecute(query, "venta.SEL_CARRITO_SP");
    }

    async postAgregarCarrito(body: any): Promise<any> {
        return await this.query.spExecute(body, "[venta].[INS_CARRITO_SP]");
    }

    async actualizarCantidadCarrito(body: any): Promise<any> {
        return await this.query.spExecute(body, "[venta].[UPD_CARRITO_CANTIDAD_SP]");
    }

    async eliminarCarrito(body: any): Promise<any> {
        return await this.query.spExecute(body, "[venta].[DEL_CARRITO_SP]");
    }



}