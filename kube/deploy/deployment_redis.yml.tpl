---
apiVersion: extensions/v1beta1 
kind: Deployment
metadata:
  name: redis-$DOMAIN
spec:
  selector:
    matchLabels:
      app: redis-$DOMAIN
  replicas: 1 
  template:
    metadata:
      labels:
        app: redis-$DOMAIN
        domain: $DOMAIN
        superdomain: redash
        env: $ENV
    spec:
      nodeSelector:
        env: $NODE_SELECTOR
      containers:
      - name: redis-redash
        image: redis:3.0-alpine 
        ports:
        - containerPort: 6379 
        resources:
          requests:
            memory: "2Gi"
            cpu: "750m"
          limits:
            memory: "3Gi"
            cpu: "1000m"
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - "redis-cli -c $(hostname) ping"
          initialDelaySeconds: 20
          periodSeconds: 5
...
