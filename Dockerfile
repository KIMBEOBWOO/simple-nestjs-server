######################################
# BUILD FOR LOCAL DEVELOPMENT
######################################

FROM node:18-alpine As development

# add the missing shared libraries from alpine base image
WORKDIR /usr/src/app

# Copy source code into app folder
COPY --chown=node:node . .

# Install dependencies
RUN yarn --frozen-lockfile

# Set Docker as a non-root user
USER node

######################################
# BUILD FOR PRODUCTION
######################################
FROM node:18-alpine as build

WORKDIR /usr/src/app

ARG APP

# In order to run `yarn build` we need access to the Nest CLI.dl;s
# Nest CLI is a dev dependency.
COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules
COPY --chown=node:node . .

# Install only the production dependencies and clean cache to optimize image size.
# TODO : yarn cache clean
RUN yarn build && yarn --frozen-lockfile --production && yarn cache clean
# Set Docker as a non-root user
USER node

######################################
# PRODUCTION
######################################

FROM node:18-alpine As production

WORKDIR /usr/src/app

ARG APP

# Set to production environment
ENV NODE_ENV production

# Copy the production dependencies and build result from the build stage
COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/dist ./dist

# Set Docker as non-root user
USER node

# app runs on
CMD ["node", "dist/main"]
