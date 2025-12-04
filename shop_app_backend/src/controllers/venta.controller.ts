import { JsonController, Post, Body, Get, Req, Put } from "routing-controllers";
import { Request } from "express";
import Stripe from "stripe";
import config from '../config';
import { VentaRepository } from "../repository/venta.repository";

@JsonController("/venta")
export class VentaController {
    private repository: VentaRepository;
    private conf: any;
    private stripe: Stripe;

    constructor() {
        this.repository = new VentaRepository();
        const env: string = process.env.NODE_ENV || 'development';
        this.conf = (config as any)[env];


        this.stripe = new Stripe(this.conf.stripe.secretKey, {
            apiVersion: null as any
        });
    }

    @Get("/getVentaIdUsuario")
    async getVentaIdUsuario(@Req() req: Request) {
        return await this.repository.getVentaIdUsuario(req.query);
    }

    @Get("/getVentas")
    async getVentas(@Req() req: Request) {
        return await this.repository.getVentas(req.query);
    }

    @Post("/postAgregaVenta")
    async postAgregaVenta(@Body() body: any) {
        return await this.repository.postAgregaVenta(body);
    }

    @Put("/putActualizaEstatus")
    async putActualizaEstatus(@Body() body: any) {
        return await this.repository.putActualizaEstatus(body);
    }

    @Post("/postCreaIntencion")
    async postCreaIntencion(@Body() body: any) {
        try {
            const { amount } = body;

            if (!amount) {
                return { success: 0, message: "Amount requerido" };
            }

            // 1. Crear cliente
            const customer = await this.stripe.customers.create();

            // 2. Crear ephemeral key
            const ephemeralKey = await this.stripe.ephemeralKeys.create(
                { customer: customer.id },
                { apiVersion: '2024-06-20' }
            );



            // 3. Crear PaymentIntent
            const paymentIntent = await this.stripe.paymentIntents.create({
                amount: parseInt(amount), // centavos
                currency: "mxn",
                customer: customer.id,
                automatic_payment_methods: { enabled: true }
            });

            return {
                success: 1,
                paymentIntent: paymentIntent.client_secret,
                ephemeralKey: ephemeralKey.secret,
                customer: customer.id
            };

        } catch (e) {
            console.error(e);
            return { success: 0, message: `Error creando intención: ${e}` };
        }
    }
}
