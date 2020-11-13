# Builder (stage 0)
ARG OME_SEADRAGON_VERSION=0.7.0
ARG OMERO_WEB_VERSION=5.8.1

FROM crs4/ome_seadragon-web:${OME_SEADRAGON_VERSION}-ome${OMERO_WEB_VERSION}

USER root

RUN mkdir -p /opt/build_data/django_static/ \
    && mkdir -p /opt/build_data/nginx-site/ \
    && chown -R omero-web /opt/build_data/

USER omero-web

ENV PYTHONPATH "/opt/omero/web/venv3/lib/python3.6/site-packages/:${PYTHONPATH}"

RUN /opt/omero/web/OMERO.web/bin/omero config append omero.web.apps '"ome_seadragon"' \
    && /opt/omero/web/OMERO.web/bin/omero web config nginx-location > /opt/build_data/nginx-site/nginx_omero-web.location \
    && sed -i -re 's/(alias )\/opt\/omero\/web\/OMERO.web\/var\/static(;)/\1\/opt\/omero\/nginx\/static\2/' /opt/build_data/nginx-site/nginx_omero-web.location \
    && sed -i -re "s/(proxy_pass http:\/\/)0.0.0.0:4080(;)/\1omeroweb\2/" /opt/build_data/nginx-site/nginx_omero-web.location \
    && python3 /opt/omero/web/venv3/lib/python3.6/site-packages/omeroweb/manage.py collectstatic --noinput \
    && mv /opt/omero/web/OMERO.web/var/static/* /opt/build_data/django_static/

# Production
FROM nginx:1.18.0
LABEL maintainer="luca.lianas@crs4.it"

COPY --from=0 /opt/build_data/django_static/ /opt/omero/nginx/static/
COPY --from=0 /opt/build_data/nginx-site/nginx_omero-web.location /etc/nginx/apps/

RUN mkdir /etc/nginx/sites-enabled/

COPY conf_files/nginx.conf /etc/nginx/nginx.conf
COPY conf_files/* /etc/nginx/templates/

COPY resources/entrypoint.sh \
     resources/wait-for-it.sh \
     /usr/local/bin/

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
