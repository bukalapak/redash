# redash-kube (scalable)
Kubernetes configurations for Bukalapak's Redash, scalable worker container and web server container.

### Usage
```sh
make <command>
```

Or to run with production environment:
```sh
make ENV=production DOMAIN=<redash domain> <command>
```

See `Makefile` for the details.

### Components

redash-server -- web server necessary to enable Redash access from a web browser. Scalable.  
redash-worker -- Celery worker running the queue for queries and sheduled queries. Scalable.  
redis-- Redis message broker for Celery use. Do not scale.  
redash-beat -- A Celery worker running with "--beat" option, running query scheduler functions. Do not scale.  
