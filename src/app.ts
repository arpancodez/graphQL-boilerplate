import express, { Application } from 'express'
import morgan from 'morgan';
import cors from 'cors';
import { ApolloServer } from 'apollo-server-express';
import envVars from './config/envVars';
import { logger } from './config/logger';
import { typeDefs } from './api/typeDefs';
import { errorConverter, errorHandler } from './handlers/error.handler';
import { resolvers } from './api/resolvers';

async function startServer() {
    const app: Application = express()

    app.use(cors())
    app.use(morgan('dev'))
    app.use(express.json())

    const server = new ApolloServer({
        typeDefs: typeDefs,
        resolvers: resolvers,
        persistedQueries: false, // Disable persisted queries for simplicity
    });
    
    await server.start();
    server.applyMiddleware({ app: app as any, path: '/graphql' });
    
    // Apply error handling middleware after all routes
    app.use(errorConverter)
    app.use(errorHandler)

    app.listen(envVars.PORT, () => {
        logger.info(`🚀 Server is running in ${envVars.NODE_ENV} mode on port ${envVars.PORT}`);
        logger.info(`📊 GraphQL endpoint: http://localhost:${envVars.PORT}${server.graphqlPath}`);
    });
}

export default startServer;