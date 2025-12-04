export default {
    development: {
        db: {
            user: "sa",
            password: "Mege2089",
            server: "localhost",
            port: 1433,
            database: "LAROPANOSTRAA",
            options: {
                encrypt: false,
                trustServerCertificate: true,
            },
        },
        app: {
            port: 5112,
        },
        
    },
    production: {
        db: {
            user: "sa",
            password: "Mege2089",
            server: "localhost",
            port: 1433,
            database: "LAROPANOSTRAA",
            options: {
                encrypt: false,
                trustServerCertificate: true,
            },
        },
        app: {
            port: 5112,
        },
       
    }
};
