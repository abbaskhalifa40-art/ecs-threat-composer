FROM node:18-alpine AS build
WORKDIR /app
    
COPY package.json yarn.lock ./
RUN yarn install
    
COPY . .
RUN yarn build
    
   
FROM node:18-alpine
WORKDIR /app
    
COPY package.json yarn.lock ./
RUN yarn install --production
    
COPY server.js ./
COPY --from=build /app/build ./build
    
EXPOSE 3000
CMD ["node", "server.js"]
    