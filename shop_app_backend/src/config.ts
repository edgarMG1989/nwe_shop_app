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
        stripe: {
            secretKey: "sk_test_51SZzjYBN3aDp6gEaQx3KYYRtLkidfvHT6r3qPJNkXLiWSR2XHfDRfIws6aQMNnpUZnPckqdvr2bOBNdkHGwXZofK00btaOiRTn"
        }
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
        stripe: {
            secretKey: "sk_test_51SZzjYBN3aDp6gEaQx3KYYRtLkidfvHT6r3qPJNkXLiWSR2XHfDRfIws6aQMNnpUZnPckqdvr2bOBNdkHGwXZofK00btaOiRTn"
        }
    }
};
