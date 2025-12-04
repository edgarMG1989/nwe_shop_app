import { Service } from 'typedi';
import { Query } from '../data/query';
import config from '../config';

export class SeguridadRepository {
    private conf: any;
    query: any;

    constructor() {
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];
        this.query = new Query();
    }


    async login(body) {
        const result = await this.query.spExecuteMulti(body, "[seguridad].[SEL_LOGIN_SP]");
        const usuario = result;

        if (!usuario || usuario[0][0].success === 0) {
            return { success: 0, message: "Usuario o contraseña incorrectos" };
        }

        return {
            success: 1,
            message: "Inicio de sesión exitoso",
            usuario: usuario[1][0],
        };

    }

    async postInsPerfil(body: any): Promise<any> {
        return await this.query.spExecuteMulti(body, "[seguridad].[INS_USUARIO_SP]");
    }

    async updatePerfil(body: any): Promise<any> {
        return await this.query.spExecuteMulti(body, "[seguridad].[UPD_USUARIO_SP]");
    }


}