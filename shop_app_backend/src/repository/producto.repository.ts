import { Service } from 'typedi';
import { Query } from '../data/query';
import config from '../config';

@Service()
export class ProductoRepository {
    private conf: any;
    query: any;

    constructor() {
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];
        this.query = new Query();
    }

    async obtenerProductosNovedad(query: any): Promise<any> {
        return await this.query.spExecute(query, "[producto].[SEL_PRODUCTO_NOVEDAD_SP]");
    }

    async obtenerProductoInventario(query: any): Promise<any> {
        return await this.query.spExecute(query, "[producto].[SEL_PRODUCTO_INVENTARIO_SP]");
    }

    async obtenerProductoGenero(query: any): Promise<any> {
        return await this.query.spExecute(query, "[producto].[SEL_PRODUCTO_GENERO_SP]");
    }

    async validaInventario(query: any): Promise<any> {
        return await this.query.spExecute(query, "[producto].[SEL_VALIDA_INVENTARIO_SP]");
    }

    async all(query: any): Promise<any> {
        return await this.query.spExecute(query, "[producto].[SEL_PRODUCTO_ALL_SP]");
    }

    async getProductoId(query: any): Promise<any> {
        return await this.query.spExecuteMulti(query, "[producto].[SEL_PRODUCTO_ID_SP]");
    }

    async postAgregarProducto(body: any): Promise<any> {
        return await this.query.spExecute(body, "[producto].[INS_PRODUCTO_SP]");
    }

    async putEditarProducto(body: any): Promise<any> {
        return await this.query.spExecute(body, "[producto].[UPD_PRODUCTO_SP]");
    }

    async deleteEliminarProducto(body: any): Promise<any> {
        return await this.query.spExecute(body, "[producto].[DEL_PRODUCTO_SP]");
    }


}