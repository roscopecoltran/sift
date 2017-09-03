FROM python:3.5-alpine
LABEL maintainer "Luc Michalski <michalski.luc@gmail.com>"

ENV PYTHONUNBUFFERED=1 \
	PYTHONPATH=$PYTHONPATH:/srv/app

ADD ./example/requirements.txt /srv/app/requirements.txt
WORKDIR /srv
RUN apk add --no-cache --no-progress --update nano bash jq tree \
	&& pip install --no-cache --no-cache-dir -r /srv/app/requirements.txt

ADD ./example/ /srv/app/
EXPOSE 8080

CMD ["/bin/bash"]
# CMD ["gunicorn", "srv:app", "--bind", "0.0.0.0:8080", "--worker-class", "aiohttp.worker.GunicornWebWorker"]

# docker build -t aiounfurl --no-cache .
# docker run -ti --rm --name aiounfurl -p 8080:8080 -e "OEMBED_PROVIDERS_FILE=/srv/app/providers.json" -v `pwd`/providers.json:/srv/app/providers.json aiounfurl