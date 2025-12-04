import { Service } from 'typedi';
import { Query } from '../data/query';
import config from '../config';

@Service()
export class VentaRepository {
    private conf: any;
    query: any;

    constructor() {
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];
        this.query = new Query();
    }

    async getVentaIdUsuario(query: any): Promise<any> {
        return await this.query.spExecuteMulti(query, "[venta].[SEL_VENTAUSUARIO_SP]");
    }

    async getVentas(query: any): Promise<any> {
        return await this.query.spExecuteMulti(query, "[venta].[SEL_VENTAS_SP]");
    }

    async postAgregaVenta(body: any): Promise<any> {
        return await this.query.spExecute(body, "[venta].[INS_VENTA_SP]");
    }

    async putActualizaEstatus(body: any): Promise<any> {
        return await this.query.spExecute(body, "[venta].[UPD_ESTATUSVENTA_SP]");
    }

    

}