# Builder (stage 0)
ARG OME_SEADRAGON_VERSION=0.6.13
ARG OMERO_WEB_VERSION=5.4.10

FROM crs4/ome_seadragon-web:${OME_SEADRAGON_VERSION}-ome${OMERO_WEB_VERSION}

ENV PYTHONPATH "/opt/omero/web/venv/lib/python2.7/site-packages/:/opt/omero/web/OMERO.web/lib/python/:${PYTHONPATH}"

RUN /opt/omero/web/OMERO.web/bin/omero config append omero.web.apps '"ome_seadragon"' \
    && /opt/omero/web/OMERO.web/bin/omero web config nginx-location > /opt/omero/web/nginx_omero-web.location \
    && sed -i -re 's/(alias )\/opt\/omero\/web\/OMERO.web\/lib\/python\/omeroweb\/static(;)/\1\/opt\/omero\/nginx\/static\2/' /opt/omero/web/nginx_omero-web.location \
    && sed -i -re "s/(proxy_pass http:\/\/)0.0.0.0:4080(;)/\1omeroweb\2/" /opt/omero/web/nginx_omero-web.location \
    && python /opt/omero/web/OMERO.web/lib/python/omeroweb/manage.py collectstatic --noinput

# Production
FROM nginx:1.15.11
LABEL maintainer="luca.lianas@crs4.it"

COPY --from=0 /opt/omero/web/OMERO.web/lib/python/omeroweb/static /opt/omero/nginx/static/
COPY --from=0 /opt/omero/web/nginx_omero-web.location /etc/nginx/apps/

RUN mkdir /etc/nginx/sites-enabled/

COPY conf_files/nginx.conf /etc/nginx/nginx.conf
COPY conf_files/* /etc/nginx/templates/

COPY resources/entrypoint.sh \
     resources/wait-for-it.sh \
     /usr/local/bin/

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
