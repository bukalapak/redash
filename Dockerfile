FROM python:2-slim

EXPOSE 5000

RUN useradd --create-home redash

RUN apt-get update && \
  apt-get install -y curl gnupg && \
  curl https://deb.nodesource.com/setup_6.x | bash - && \
  apt-get install -y \
    build-essential \
    pwgen \
    libffi-dev \
    sudo \
    git-core \
    wget \
    nodejs \
    libpq-dev \
    xmlsec1 \
    libssl-dev \
    default-libmysqlclient-dev \
    freetds-dev \
    libsasl2-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*


RUN mkdir /opt/redash && \
    chown -R redash /opt/redash
    
WORKDIR /opt/redash/

ADD ./requirements*txt /opt/redash/
RUN pip install -r requirements.txt 
RUN pip install -r requirements_dev.txt
RUN pip install -r requirements_all_ds.txt
RUN pip install pandas
RUN pip install --upgrade pyasn1-modules

ADD . /opt/redash/

ADD https://releases.hashicorp.com/envconsul/0.6.2/envconsul_0.6.2_linux_amd64.tgz /tmp/
RUN tar -xf /tmp/envconsul* -C /bin && rm /tmp/envconsul*

USER redash
