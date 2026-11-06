# syntax=docker/dockerfile:1
# Imagen de send2ereader para enviar EPUB a Kobo.
# Sustituye al Dockerfile oficial, que falla al compilar PyMuPDF (pdfCropMargins)
# porque usa node:lts-alpine sin versión fija.
FROM node:20-alpine

WORKDIR /usr/src/app

# kepubify: convierte EPUB a KEPUB (formato nativo de Kobo)
ADD --checksum=sha256:37d7628d26c5c906f607f24b36f781f306075e7073a6fe7820a751bb60431fc5 \
    https://github.com/pgaskin/kepubify/releases/download/v4.0.4/kepubify-linux-64bit \
    /usr/local/bin/kepubify
RUN chmod +x /usr/local/bin/kepubify

# Código de send2ereader, fijado a un commit concreto del repositorio oficial
ADD https://github.com/daniel-j/send2ereader.git#eb0b646191d654aa4ab52a185151aa34f359f889 ./

RUN npm ci --omit=dev && node -e "require('koa')" && mkdir -p uploads

EXPOSE 3001
CMD ["node", "index.js"]
