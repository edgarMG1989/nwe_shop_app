import { default as confDB } from '../config';
import * as sql from 'mssql';

export class Query {
  constructor() { }

  public spExecute(params: any, SP: string): Promise<any> {
    return this.dbConnect(async (dbConn: sql.ConnectionPool) => {
      try {
        const request = dbConn.request();

        const cleanParams = { ...params };
        delete cleanParams.nocache;
        delete cleanParams.timestamp;
        delete cleanParams.cacheBuster;

        if (cleanParams) {
          Object.keys(cleanParams).forEach((key) => {
            const value = cleanParams[key];
            request.input(key, value);
          });
        }

        const result = await request.execute(SP);

        dbConn.close();
        return result.recordset;
      } catch (error) {
        dbConn.close();
        console.error(`❌ Error ejecutando SP ${SP}:`, error);
        throw error;
      }
    });
  }

  public spExecuteMulti(params: any, SP: string): Promise<any> {
    return this.dbConnect(async (dbConn: sql.ConnectionPool) => {
      try {
        const request = dbConn.request();

        const cleanParams = { ...params };
        delete cleanParams.nocache;
        delete cleanParams.timestamp;
        delete cleanParams.cacheBuster;

        if (cleanParams) {
          Object.keys(cleanParams).forEach((key) => {
            const value = cleanParams[key];
            request.input(key, value);
          });
        }

        const result = await request.execute(SP);

        dbConn.close();
        return result.recordsets;
      } catch (error) {
        dbConn.close();
        console.error(`❌ Error ejecutando SP ${SP}:`, error);
        throw error;
      }
    });
  }

  private dbConnect(callback: (dbConn: sql.ConnectionPool) => Promise<any>): Promise<any> {
    const env: string = process.env.NODE_ENV || 'development';
    const dbConfig = (confDB as any)[env].db; 

    const dbConn = new sql.ConnectionPool(dbConfig);

    return new Promise((resolve, reject) => {
      dbConn
        .connect()
        .then(() => callback(dbConn).then(resolve).catch(reject))
        .catch(reject);
    });
  }
}
