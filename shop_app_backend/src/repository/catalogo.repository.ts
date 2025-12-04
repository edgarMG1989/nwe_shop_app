import { Service } from 'typedi';
import { Query } from '../data/query';
import config from '../config';

@Service()
export class CatalogoRepository {
    private conf: any;
    query: any;

    constructor() {
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];
        this.query = new Query();
    }

    async getTallas(query: any): Promise<any> {
        return await this.query.spExecute(query, "[catalogo].[SEL_TALLAS_SP]");
    }

    async getGeneros(query: any): Promise<any> {
        return await this.query.spExecute(query, "[catalogo].[SEL_GENEROS_SP]");
    }

    async getTipoPrenda(query: any): Promise<any> {
        return await this.query.spExecute(query, "[catalogo].[SEL_TIPOPRENDA_SP]");
    }


}