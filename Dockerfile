# Serveur web léger
FROM nginx:alpine

# Copie du site dans le dossier servi par nginx
COPY . /usr/share/nginx/html

EXPOSE 80
