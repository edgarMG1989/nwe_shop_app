import { Service } from 'typedi';
import { Query } from '../data/query';
import config from '../config';

@Service()
export class FileServerRepository {
    private conf: any;
    query: any;

    constructor() {
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];
        this.query = new Query();
    }


    async postInsDocumento(body: any): Promise<any> {
        return await this.query.spExecute(body, "[fileserver].[INS_DOCUMENTO_SP]");
    }




}